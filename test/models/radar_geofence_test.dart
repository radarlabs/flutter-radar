import 'package:flutter_radar/src/models/radar_geofence.dart';
import 'package:flutter_radar/src/models/radar_location.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

final _ring = [
  [-73.0, 40.0],
  [-73.1, 40.0],
  [-73.1, 40.1],
  [-73.0, 40.0],
];

void main() {
  group('RadarGeofence', () {
    test('parses a circle', () {
      final g = RadarGeofence.fromMap(circleGeofenceMap);
      expect(g.id, 'g1');
      expect(g.description, 'Store');
      expect(g.tag, 'store');
      expect(g.externalId, '123');
      expect(g.metadata, {'a': 1});
      expect(g.operatingHours, {
        'monday': [
          ['08:00', '17:00'],
        ],
      });
      expect(g.dwellThreshold, 5);
      expect(g.stopDetection, isTrue);
      final geometry = g.geometry;
      expect(geometry, isA<RadarCircleGeometry>());
      expect(
        geometry!.center,
        const RadarCoordinate(latitude: 40.73, longitude: -73.99),
      );
      expect(geometry.radius, 100);
    });

    test('parses an Android polygon (top-level coordinates)', () {
      final g = RadarGeofence.fromMap({
        '_id': 'g2',
        'description': 'Zone',
        'geometryCenter': {
          'type': 'Point',
          'coordinates': [-73.05, 40.05],
        },
        'geometryRadius': 500.0,
        'coordinates': [_ring],
        'type': 'Polygon',
      });
      final geometry = g.geometry as RadarPolygonGeometry;
      expect(geometry.coordinates, hasLength(4));
      expect(
        geometry.coordinates[1],
        const RadarCoordinate(latitude: 40.0, longitude: -73.1),
      );
      expect(geometry.radius, 500);
    });

    test('parses an iOS polygon (GeoJSON geometry)', () {
      final g = RadarGeofence.fromMap({
        '_id': 'g3',
        'description': 'Zone',
        'geometryCenter': {
          'type': 'Point',
          'coordinates': [-73.05, 40.05],
        },
        'geometryRadius': 500.0,
        'coordinates': [_ring],
        'geometry': {
          'type': 'Polygon',
          'coordinates': [_ring],
        },
        'type': 'Polygon',
      });
      final geometry = g.geometry as RadarPolygonGeometry;
      expect(geometry.coordinates, hasLength(4));
      expect(
        geometry.center,
        const RadarCoordinate(latitude: 40.05, longitude: -73.05),
      );
    });

    test('isochrone type and missing coordinates', () {
      final g = RadarGeofence.fromMap({
        'type': 'isochrone',
        'geometryCenter': {
          'type': 'Point',
          'coordinates': [-73.99, 40.73],
        },
      });
      final geometry = g.geometry as RadarPolygonGeometry;
      expect(geometry.coordinates, isEmpty);
      expect(
        geometry.center,
        const RadarCoordinate(latitude: 40.73, longitude: -73.99),
      );
    });

    test('a geometry without a center is null', () {
      expect(RadarGeofence.fromMap({'type': 'Circle'}).geometry, isNull);
      expect(RadarGeofence.fromMap({'type': 'Polygon'}).geometry, isNull);
    });

    test('empty and garbage maps', () {
      final g = RadarGeofence.fromMap({});
      expect(g.id, '');
      expect(g.geometry, isNull);
      final junk = RadarGeofence.fromMap({
        'type': 'Polygon',
        'coordinates': 'x',
        'geometry': 3,
        'geometryCenter': {
          'type': 'Point',
          'coordinates': [1, 2],
        },
        'geometryRadius': 'big',
        'operatingHours': {
          'monday': 'closed',
          'tuesday': [
            1,
            ['a'],
          ],
        },
      });
      expect((junk.geometry as RadarPolygonGeometry).coordinates, isEmpty);
      expect(junk.operatingHours, {
        'tuesday': [
          ['a'],
        ],
      });
    });
  });
}
