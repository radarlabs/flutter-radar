import 'package:meta/meta.dart';

import 'parsing.dart';
import 'radar_location.dart';

/// The beacon protocol.
enum RadarBeaconType implements RadarWireEnum {
  /// iBeacon.
  iBeacon('ibeacon'),

  /// Eddystone.
  eddystone('eddystone');

  const RadarBeaconType(this.wireValue);

  @override
  @internal
  final String wireValue;

  @internal
  static RadarBeaconType fromWire(Object? value) =>
      readEnum(values, value, iBeacon);
}

/// A Bluetooth beacon.
final class RadarBeacon {
  const RadarBeacon({
    required this.id,
    required this.description,
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

  /// The Radar ID of the beacon.
  final String id;

  /// The description of the beacon.
  final String description;

  /// The tag of the beacon.
  final String? tag;

  /// The external ID of the beacon.
  final String? externalId;

  /// The iBeacon UUID, or the Eddystone namespace UID.
  final String uuid;

  /// The iBeacon major value, or the Eddystone instance ID.
  final String major;

  /// The iBeacon minor value. Empty for Eddystone beacons.
  final String minor;

  /// The optional set of custom key-value pairs for the beacon.
  final Map<String, Object?>? metadata;

  /// The location of the beacon.
  final RadarCoordinate? location;

  /// The received signal strength in dBm, for ranged beacons.
  final int? rssi;

  /// The type of the beacon.
  final RadarBeaconType type;

  @internal
  factory RadarBeacon.fromMap(ChannelMap map) => RadarBeacon(
    id: readString(map['_id']) ?? '',
    description: readString(map['description']) ?? '',
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
}

/// Major and minor are strings on both platforms, but accept numbers too.
String? _readId(Object? value) =>
    value is num ? value.toString() : readString(value);
