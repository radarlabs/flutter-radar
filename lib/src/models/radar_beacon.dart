import 'package:meta/meta.dart';

import 'parsing.dart';
import 'radar_location.dart';

/// The beacon protocol.
enum RadarBeaconType implements RadarWireEnum {
  iBeacon('ibeacon'),
  eddystone('eddystone');

  const RadarBeaconType(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Parses a native beacon type. Unrecognized values become [iBeacon].
  @internal
  static RadarBeaconType fromWire(Object? value) =>
      readEnum(values, value, iBeacon);
}

/// A Bluetooth beacon.
final class RadarBeacon {
  const RadarBeacon({
    this.id,
    this.description,
    this.tag,
    this.externalId,
    required this.uuid,
    required this.major,
    required this.minor,
    this.metadata,
    this.location,
    this.rssi,
    this.type = RadarBeaconType.iBeacon,
  });

  /// The Radar ID of the beacon. Null for a ranged beacon that doesn't match a
  /// beacon in the project.
  final String? id;

  /// The description of the beacon. Null for a ranged beacon that doesn't
  /// match a beacon in the project.
  final String? description;
  final String? tag;
  final String? externalId;

  /// The iBeacon UUID, or the Eddystone namespace UID.
  final String uuid;

  /// The iBeacon major value, or the Eddystone instance ID.
  final String major;

  /// The iBeacon minor value. Empty for Eddystone beacons.
  final String minor;
  final Map<String, Object?>? metadata;
  final RadarCoordinate? location;

  /// The received signal strength in dBm, for ranged beacons.
  final int? rssi;
  final RadarBeaconType type;

  @internal
  factory RadarBeacon.fromMap(ChannelMap map) => RadarBeacon(
    id: readString(map['_id']),
    description: readString(map['description']),
    tag: readString(map['tag']),
    externalId: readString(map['externalId']),
    uuid: _readId(map['uuid']) ?? _readId(map['uid']) ?? '',
    major: _readId(map['major']) ?? _readId(map['instance']) ?? '',
    minor: _readId(map['minor']) ?? '',
    metadata: readJson(map['metadata']),
    location: RadarCoordinate.fromMap(readMap(map['geometry'])),
    rssi: readInt(map['rssi']),
    type: RadarBeaconType.fromWire(map['type']),
  );

  /// Beacons are equal when their [uuid], [major], and [minor] match, like in
  /// both native SDKs.
  @override
  bool operator ==(Object other) =>
      other is RadarBeacon &&
      other.uuid == uuid &&
      other.major == major &&
      other.minor == minor;

  @override
  int get hashCode => Object.hash(uuid, major, minor);
}

/// Major and minor are strings on both platforms, but accept numbers too.
String? _readId(Object? value) =>
    value is num ? value.toString() : readString(value);
