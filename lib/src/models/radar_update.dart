import 'package:meta/meta.dart';

import 'parsing.dart';
import 'radar_event.dart';
import 'radar_location.dart';
import 'radar_status.dart';
import 'radar_user.dart';
import 'radar_verified_location_token.dart';

/// An update pushed by the native Radar SDK, delivered to the `Radar.onX`
/// listeners and to the handler passed to [Radar.registerBackgroundHandler].
///
/// The class is sealed, so a background handler can `switch` over every kind
/// of update:
///
/// ```dart
/// @pragma('vm:entry-point')
/// Future<void> onRadarUpdate(RadarUpdate update) async {
///   switch (update) {
///     case RadarEventsUpdate(:final events):
///       // ...
///     case RadarLocationUpdate(:final location, :final user):
///       // ...
///     default:
///       break;
///   }
/// }
/// ```
sealed class RadarUpdate {
  const RadarUpdate();

  /// Parses an update from the method name and payload the native side sends.
  /// Returns null for an unknown method.
  @internal
  static RadarUpdate? fromMethodCall(String method, ChannelMap payload) =>
      switch (method) {
        'location' => RadarLocationUpdate.fromMap(payload),
        'clientLocation' => RadarClientLocationUpdate.fromMap(payload),
        'events' => RadarEventsUpdate.fromMap(payload),
        'error' => RadarErrorUpdate.fromMap(payload),
        'log' => RadarLogUpdate.fromMap(payload),
        'token' => RadarTokenUpdate.fromMap(payload),
        'ipChanged' => const RadarIpChangedUpdate(),
        'sharingChanged' => RadarSharingChangedUpdate.fromMap(payload),
        _ => null,
      };
}

/// The user's location was sent to the server. Delivered to
/// [Radar.onLocation].
final class RadarLocationUpdate extends RadarUpdate {
  const RadarLocationUpdate({required this.location, this.user});

  final RadarLocation? location;
  final RadarUser? user;

  @internal
  factory RadarLocationUpdate.fromMap(ChannelMap map) => RadarLocationUpdate(
    location: RadarLocation.fromMap(readMap(map['location'])),
    user: readObject(map['user'], RadarUser.fromMap),
  );
}

/// The device's location changed, whether or not it was sent to the server.
/// Delivered to [Radar.onClientLocation].
final class RadarClientLocationUpdate extends RadarUpdate {
  const RadarClientLocationUpdate({
    required this.location,
    required this.stopped,
    required this.source,
  });

  final RadarLocation? location;

  /// Whether the device is stopped.
  final bool stopped;
  final RadarLocationSource source;

  @internal
  factory RadarClientLocationUpdate.fromMap(ChannelMap map) =>
      RadarClientLocationUpdate(
        location: RadarLocation.fromMap(readMap(map['location'])),
        stopped: readBool(map['stopped']) ?? false,
        source: RadarLocationSource.fromWire(map['source']),
      );
}

/// The server returned events. Delivered to [Radar.onEvents].
final class RadarEventsUpdate extends RadarUpdate {
  const RadarEventsUpdate({required this.events, this.user});

  final List<RadarEvent> events;
  final RadarUser? user;

  @internal
  factory RadarEventsUpdate.fromMap(ChannelMap map) => RadarEventsUpdate(
    events: readList(map['events'], RadarEvent.fromMap),
    user: readObject(map['user'], RadarUser.fromMap),
  );
}

/// A request failed. Delivered to [Radar.onError].
final class RadarErrorUpdate extends RadarUpdate {
  const RadarErrorUpdate({required this.status});

  final RadarStatus status;

  @internal
  factory RadarErrorUpdate.fromMap(ChannelMap map) =>
      RadarErrorUpdate(status: RadarStatus.fromWire(map['status']));
}

/// The SDK logged a message. Delivered to [Radar.onLog].
final class RadarLogUpdate extends RadarUpdate {
  const RadarLogUpdate({required this.message});

  final String message;

  @internal
  factory RadarLogUpdate.fromMap(ChannelMap map) =>
      RadarLogUpdate(message: readString(map['message']) ?? '');
}

/// A new verified location token was issued. Delivered to [Radar.onToken].
final class RadarTokenUpdate extends RadarUpdate {
  const RadarTokenUpdate({required this.token});

  final RadarVerifiedLocationToken? token;

  @internal
  factory RadarTokenUpdate.fromMap(ChannelMap map) => RadarTokenUpdate(
    token: readObject(map['token'], RadarVerifiedLocationToken.fromMap),
  );
}

/// The device's IP address changed. Delivered to [Radar.onIpChanged].
final class RadarIpChangedUpdate extends RadarUpdate {
  const RadarIpChangedUpdate();
}

/// Location sharing started or stopped. Delivered to
/// [Radar.onSharingChanged].
final class RadarSharingChangedUpdate extends RadarUpdate {
  const RadarSharingChangedUpdate({required this.sharing});

  final bool sharing;

  @internal
  factory RadarSharingChangedUpdate.fromMap(ChannelMap map) =>
      RadarSharingChangedUpdate(sharing: readBool(map['sharing']) ?? false);
}
