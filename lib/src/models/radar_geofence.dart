import 'package:meta/meta.dart';

import 'parsing.dart';
import 'radar_location.dart';

/// The shape of a geofence.
sealed class RadarGeofenceGeometry {
  const RadarGeofenceGeometry({required this.center, required this.radius});

  /// The geofence center.
  final RadarCoordinate center;

  /// The radius in meters. For polygons, the radius of the smallest circle
  /// around [center] that contains the polygon.
  final double radius;
}

/// A circular geofence.
final class RadarCircleGeometry extends RadarGeofenceGeometry {
  const RadarCircleGeometry({required super.center, required super.radius});
}

/// A polygon (or isochrone) geofence.
final class RadarPolygonGeometry extends RadarGeofenceGeometry {
  const RadarPolygonGeometry({
    required this.coordinates,
    required super.center,
    required super.radius,
  });

  /// The polygon's outer ring.
  final List<RadarCoordinate> coordinates;
}

/// A geofence.
final class RadarGeofence {
  const RadarGeofence({
    required this.id,
    required this.description,
    this.tag,
    this.externalId,
    this.metadata,
    this.operatingHours,
    this.geometry,
    this.dwellThreshold,
    this.stopDetection,
  });

  final String id;
  final String description;
  final String? tag;
  final String? externalId;
  final Map<String, Object?>? metadata;

  /// Opening hours by day (such as `monday`), each a list of
  /// `[open, close]` time pairs like `["08:00", "17:00"]`.
  final Map<String, List<List<String>>>? operatingHours;
  final RadarGeofenceGeometry? geometry;

  /// Minutes the user must stay in the geofence to generate a dwell event.
  final double? dwellThreshold;

  /// Whether the geofence only generates entries when the user stops.
  final bool? stopDetection;

  @internal
  factory RadarGeofence.fromMap(ChannelMap map) => RadarGeofence(
    id: readString(map['_id']) ?? '',
    description: readString(map['description']) ?? '',
    tag: readString(map['tag']),
    externalId: readString(map['externalId']),
    metadata: readJson(map['metadata']),
    operatingHours: _readOperatingHours(map['operatingHours']),
    geometry: _readGeometry(map),
    dwellThreshold: readDouble(map['dwellThreshold']),
    stopDetection: readBool(map['stopDetection']),
  );
}

Map<String, List<List<String>>>? _readOperatingHours(Object? value) {
  if (value is! Map) return null;
  return {
    for (final MapEntry(:key, value: day) in value.entries)
      if (key is String && day is List)
        key: [
          for (final range in day)
            if (range is List) [for (final t in range) t.toString()],
        ],
  };
}

// Both platforms emit `type` ("Circle"/"Polygon"), `geometryCenter` (a GeoJSON
// point), and `geometryRadius`. Polygon rings come as top-level `coordinates`
// (Android and iOS) and inside a GeoJSON `geometry` object (iOS). The API's
// lowercase types (`circle`, `polygon`, `isochrone`) are accepted too.
RadarGeofenceGeometry? _readGeometry(ChannelMap map) {
  final type = readString(map['type'])?.toLowerCase();
  final center =
      RadarCoordinate.fromMap(readMap(map['geometryCenter'])) ??
      const RadarCoordinate(latitude: 0, longitude: 0);
  final radius = readDouble(map['geometryRadius']) ?? 0;
  switch (type) {
    case 'circle':
      return RadarCircleGeometry(center: center, radius: radius);
    case 'polygon' || 'isochrone':
      final coordinates =
          readMap(map['geometry'])?['coordinates'] ?? map['coordinates'];
      return RadarPolygonGeometry(
        coordinates: _readRing(coordinates),
        center: center,
        radius: radius,
      );
    default:
      return null;
  }
}

/// Reads the outer ring of GeoJSON polygon coordinates
/// (`[[[lng, lat], ...]]`), or a bare ring (`[[lng, lat], ...]`).
List<RadarCoordinate> _readRing(Object? value) {
  if (value is! List || value.isEmpty) return const [];
  final first = value.first;
  final ring =
      first is List && first.isNotEmpty && first.first is List ? first : value;
  return [
    for (final point in ring)
      if (RadarCoordinate.fromLngLat(point) case final coordinate?) coordinate,
  ];
}
