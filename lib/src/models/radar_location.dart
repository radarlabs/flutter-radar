import 'package:meta/meta.dart';

import 'parsing.dart';

/// A latitude and longitude.
final class RadarCoordinate {
  const RadarCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  /// Parses a GeoJSON `Point` (`{"type": "Point", "coordinates": [lng, lat]}`)
  /// or a map with `latitude` and `longitude` keys.
  @internal
  static RadarCoordinate? fromMap(ChannelMap? map) {
    if (map == null) return null;
    final coordinates = map['coordinates'];
    if (coordinates is List && coordinates.length >= 2) {
      final longitude = readDouble(coordinates[0]);
      final latitude = readDouble(coordinates[1]);
      if (latitude != null && longitude != null) {
        return RadarCoordinate(latitude: latitude, longitude: longitude);
      }
    }
    final latitude = readDouble(map['latitude']);
    final longitude = readDouble(map['longitude']);
    if (latitude == null || longitude == null) return null;
    return RadarCoordinate(latitude: latitude, longitude: longitude);
  }

  /// Parses a GeoJSON `[longitude, latitude]` pair.
  @internal
  static RadarCoordinate? fromLngLat(Object? value) {
    if (value is! List || value.length < 2) return null;
    final longitude = readDouble(value[0]);
    final latitude = readDouble(value[1]);
    if (latitude == null || longitude == null) return null;
    return RadarCoordinate(latitude: latitude, longitude: longitude);
  }

  @internal
  Map<String, Object?> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  bool operator ==(Object other) =>
      other is RadarCoordinate &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'RadarCoordinate($latitude, $longitude)';
}

/// A device location.
///
/// Locations from the native SDKs fill in every field the platform reports.
/// When you pass a location to Radar, such as to [Radar.trackOnce], only
/// [latitude], [longitude], and [accuracy] are sent.
final class RadarLocation {
  const RadarLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.verticalAccuracy,
    this.speed,
    this.speedAccuracy,
    this.course,
    this.courseAccuracy,
    this.mocked,
  });

  final double latitude;
  final double longitude;

  /// Horizontal accuracy in meters.
  final double? accuracy;

  /// Altitude in meters.
  final double? altitude;
  final double? verticalAccuracy;

  /// Speed in meters per second.
  final double? speed;
  final double? speedAccuracy;

  /// Course (bearing) in degrees.
  final double? course;
  final double? courseAccuracy;

  /// Whether the platform reported the location as simulated.
  final bool? mocked;

  RadarCoordinate get coordinate =>
      RadarCoordinate(latitude: latitude, longitude: longitude);

  @internal
  static RadarLocation? fromMap(ChannelMap? map) {
    if (map == null) return null;
    final latitude = readDouble(map['latitude']);
    final longitude = readDouble(map['longitude']);
    if (latitude == null || longitude == null) return null;
    return RadarLocation(
      latitude: latitude,
      longitude: longitude,
      accuracy: readDouble(map['accuracy']),
      altitude: readDouble(map['altitude']),
      verticalAccuracy: readDouble(map['verticalAccuracy']),
      speed: readDouble(map['speed']),
      speedAccuracy: readDouble(map['speedAccuracy']),
      course: readDouble(map['course']),
      courseAccuracy: readDouble(map['courseAccuracy']),
      mocked: readBool(map['mocked']),
    );
  }

  @internal
  Map<String, Object?> toMap() => compact({
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
  });

  @override
  String toString() =>
      'RadarLocation($latitude, $longitude, accuracy: $accuracy)';
}
