// Helpers for reading the maps that the native Radar SDKs send over the
// method channel. Not exported.
//
// Why the readers are lenient: the plugin doesn't serialize native models
// itself. The bridges call each native SDK's own serializer (Android
// `toJson()`, iOS `dictionaryValue`) and pass the result through the standard
// message codec, so the types Dart sees are whatever those serializers
// produce. They aren't uniform:
//
// - Some models are serialized from typed properties; others, such as the
//   verified location and reveal risk tokens, pass the server's JSON through.
//   JSON has one number type, so a whole-number double can arrive as an `int`,
//   and a field can be an `int` on one platform and a `double` on the other.
// - The codec decodes every map as `Map<Object?, Object?>` and every list as
//   `List<Object?>`, though map keys are always strings.
// - The platforms don't agree on whether an absent value is omitted or
//   `null`. Android models that read JSON with `optString` also store a JSON
//   null as the string "null" and a missing key as "", and re-serialize both,
//   so string readers treat "null" and "" as missing.
// - Any of this can change in a native SDK release without a plugin change.
//
// So every reader returns null or an empty collection when a value is missing
// or has an unexpected type, and a model never throws on a payload from an
// older or newer native SDK. Some branches (numbers or booleans sent as
// strings, booleans sent as numbers, dates as epoch milliseconds) are
// defensive and not tied to a known payload.
//
// To remove this leniency in the future:
//
// - Audit the native serializers and record payload fixtures from both
//   platforms during e2e runs and parse them in unit tests to catch drift
//   in CI. Fixtures are not comprehensive. They show what one run produced,
//   not everything a payload can contain, so they should be used alongside
//   an audit.
// - OR serialize each model in the plugin's native code from its typed
//   properties, by hand or with Pigeon (https://pub.dev/packages/pigeon),
//   so the plugin defines the wire types rather than the native sdk.

import 'dart:ui' show Color;

/// A map decoded by the standard message codec.
typedef ChannelMap = Map<Object?, Object?>;

/// An enum whose values have a fixed string form on the wire.
abstract interface class RadarWireEnum {
  String get wireValue;
}

ChannelMap? readMap(Object? value) => value is Map ? value.cast() : null;

String? readString(Object? value) =>
    value is String && value.isNotEmpty && value != 'null' ? value : null;

/// Returns null for NaN and infinity, which no field uses as a value.
double? readDouble(Object? value) {
  final result = switch (value) {
    num() => value.toDouble(),
    String() => double.tryParse(value),
    _ => null,
  };
  return result != null && result.isFinite ? result : null;
}

int? readInt(Object? value) => switch (value) {
  int() => value,
  double() when value.isFinite => value.toInt(),
  String() => int.tryParse(value),
  _ => null,
};

bool? readBool(Object? value) => switch (value) {
  bool() => value,
  num() => value != 0,
  'true' => true,
  'false' => false,
  _ => null,
};

/// Reads an ISO 8601 string, or a number of milliseconds since the epoch.
DateTime? readDate(Object? value) => switch (value) {
  String() => DateTime.tryParse(value),
  num() when value.isFinite && value.abs() <= _maxEpochMilliseconds =>
    DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true),
  _ => null,
};

/// The largest number of milliseconds from the epoch that [DateTime] allows.
const _maxEpochMilliseconds = 8640000000000000;

/// Reads a number of seconds, which may be fractional.
Duration? readSeconds(Object? value) => _readDuration(value, 1e6);

/// Reads a number of minutes, which may be fractional.
Duration? readMinutes(Object? value) => _readDuration(value, 60e6);

Duration? _readDuration(Object? value, double microsecondsPerUnit) {
  final units = readDouble(value);
  return units == null
      ? null
      : Duration(microseconds: (units * microsecondsPerUnit).round());
}

/// Converts [duration] to whole minutes for the native SDKs, rounding to the
/// nearest minute.
int toMinutes(Duration duration) => (duration.inSeconds / 60).round();

// The list and map readers return unmodifiable collections, so a parsed model
// can't be changed through them, the same as one built with `const` defaults.

List<String> readStringList(Object? value) =>
    value is List ? List.unmodifiable(value.whereType<String>()) : const [];

/// Parses each map in [value] with [fromMap], skipping items that aren't maps
/// and items [fromMap] rejects by returning null.
List<T> readList<T extends Object>(
  Object? value,
  T? Function(ChannelMap map) fromMap,
) =>
    value is List
        ? List.unmodifiable(
          value
              .whereType<Map<Object?, Object?>>()
              .map((item) => fromMap(item.cast()))
              .nonNulls,
        )
        : const [];

T? readObject<T extends Object>(
  Object? value,
  T? Function(ChannelMap map) fromMap,
) {
  final map = readMap(value);
  return map == null ? null : fromMap(map);
}

Map<String, Object?>? readJson(Object? value) =>
    value is Map
        ? Map.unmodifiable(value.map((k, v) => MapEntry(k.toString(), v)))
        : null;

/// Matches [value] against each enum value's [RadarWireEnum.wireValue],
/// ignoring case, and returns [fallback] if nothing matches.
T readEnum<T extends RadarWireEnum>(List<T> values, Object? value, T fallback) {
  if (value is! String) return fallback;
  final lower = value.toLowerCase();
  for (final v in values) {
    if (v.wireValue.toLowerCase() == lower) return v;
  }
  return fallback;
}

T? readEnumOrNull<T extends RadarWireEnum>(List<T> values, Object? value) {
  if (value is! String) return null;
  final lower = value.toLowerCase();
  for (final v in values) {
    if (v.wireValue.toLowerCase() == lower) return v;
  }
  return null;
}

/// Removes entries whose value is null, so an unset optional field reaches the
/// native side as a missing key. This evens out a platform difference: iOS
/// treats a null value like a missing key, but some Android option parsers
/// don't (`has(key)` is true for a null value, and `optString` returns the
/// string "null").
Map<String, Object?> compact(Map<String, Object?> map) =>
    map..removeWhere((_, value) => value == null);

/// Formats [color] as `#RRGGBB`, the format both native SDKs parse. Alpha is
/// dropped.
String colorToHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Converts [duration] to whole seconds for a native field that stores an
/// integer. In debug builds, asserts that nothing would be dropped.
int wholeSeconds(Duration duration, String name) {
  assert(
    duration.inMicroseconds % Duration.microsecondsPerSecond == 0,
    '$name is sent to the native SDKs in whole seconds, but was $duration.',
  );
  return duration.inSeconds;
}

/// Compares JSON-like values (maps, lists, and scalars) by content.
bool deepEquals(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((k) => b.containsKey(k) && deepEquals(a[k], b[k]));
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
