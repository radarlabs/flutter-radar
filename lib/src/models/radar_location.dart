import 'package:meta/meta.dart';

import 'parsing.dart';

/// A latitude and longitude.
final class RadarCoordinate {
  const RadarCoordinate({required this.latitude, required this.longitude});

  /// The latitude in degrees.
  final double latitude;

  /// The longitude in degrees.
  final double longitude;

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
/// iOS reports an invalid accuracy, speed, or course as a negative number;
/// those fields are null instead.
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

  /// The latitude in degrees.
  final double latitude;

  /// The longitude in degrees.
  final double longitude;

  /// Horizontal accuracy in meters.
  final double? accuracy;

  /// Altitude in meters.
  final double? altitude;

  /// Vertical accuracy of [altitude] in meters.
  final double? verticalAccuracy;

  /// Speed in meters per second. On iOS, negative if unavailable.
  final double? speed;

  /// Accuracy of [speed] in meters per second.
  final double? speedAccuracy;

  /// Course (bearing) in degrees, measured clockwise from true north. On iOS,
  /// negative if unavailable.
  final double? course;

  /// Accuracy of [course] in degrees.
  final double? courseAccuracy;

  /// Whether the location is mocked. On iOS, this is also true for locations
  /// from an external accessory, and requires iOS 15 or later.
  final bool? mocked;

  /// The [latitude] and [longitude] as a [RadarCoordinate].
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
      accuracy: _readNonNegative(map['accuracy']),
      altitude: readDouble(map['altitude']),
      verticalAccuracy: _readNonNegative(map['verticalAccuracy']),
      speed: _readNonNegative(map['speed']),
      speedAccuracy: _readNonNegative(map['speedAccuracy']),
      course: _readNonNegative(map['course']),
      courseAccuracy: _readNonNegative(map['courseAccuracy']),
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

/// CoreLocation uses a negative value for an invalid accuracy, speed, or
/// course.
double? _readNonNegative(Object? value) {
  final result = readDouble(value);
  return result != null && result >= 0 ? result : null;
}
