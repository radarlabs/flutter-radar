import 'package:flutter_radar/src/models/radar_location.dart';
import 'package:flutter_radar/src/models/radar_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadarRoutes', () {
    test('reads the iOS geodesic, which is the distance itself', () {
      final routes = RadarRoutes.fromMap({
        'geodesic': {'value': 4800.0, 'text': '0.9 mi'},
      });
      expect(routes.geodesic!.value, 4800);
      expect(routes.geodesic!.text, '0.9 mi');
    });

    const route = <Object?, Object?>{
      'distance': {'value': 5280.0, 'text': '1.0 mi'},
      'duration': {'value': 4.2, 'text': '4 mins'},
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [-73.9911, 40.7342],
          [-73.9851, 40.7484],
        ],
      },
    };

    test('parses routes', () {
      final routes = RadarRoutes.fromMap({
        'geodesic': {
          'distance': {'value': 4800.0, 'text': '0.9 mi'},
        },
        'car': route,
      });
      expect(routes.geodesic!.value, 4800);
      expect(routes.geodesic!.text, '0.9 mi');
      expect(routes.car!.distance!.text, '1.0 mi');
      expect(routes.car!.duration!.value, const Duration(seconds: 252));
      expect(routes.car!.geometry!.coordinates, const [
        RadarCoordinate(latitude: 40.7342, longitude: -73.9911),
        RadarCoordinate(latitude: 40.7484, longitude: -73.9851),
      ]);
      expect(routes.foot, isNull);
      expect(routes.truck, isNull);
    });

    test('parses a matrix, which both platforms send as a list of rows', () {
      final matrix =
          RadarRouteMatrix.fromWire([
            [route, null],
            [route, route],
          ])!;
      expect(matrix.rows, hasLength(2));
      expect(matrix.routeBetween(0, 0)!.distance!.value, 5280);
      expect(matrix.routeBetween(0, 1), isNull);
      expect(
        matrix.routeBetween(1, 1)!.duration!.value,
        const Duration(seconds: 252),
      );
      expect(matrix.routeBetween(2, 0), isNull);
      expect(matrix.routeBetween(0, 5), isNull);
      expect(matrix.routeBetween(-1, 0), isNull);

      expect(RadarRouteMatrix.fromWire({'not': 'a list'}), isNull);
    });

    test('garbage values do not throw', () {
      final routes = RadarRoutes.fromMap(const {
        'geodesic': 'far',
        'foot': 1,
        'car': {
          'distance': 'far',
          'duration': {'value': 'long', 'text': 4},
          'geometry': {'coordinates': 'x'},
        },
      });
      expect(routes.geodesic, isNull);
      expect(routes.foot, isNull);
      expect(routes.car!.distance, isNull);
      expect(routes.car!.duration!.value, Duration.zero);
      expect(routes.car!.duration!.text, '');
      expect(routes.car!.geometry!.coordinates, isEmpty);

      final matrix =
          RadarRouteMatrix.fromWire([
            1,
            'a',
            [2],
          ])!;
      expect(matrix.routeBetween(0, 0), isNull);
      expect(matrix.routeBetween(2, 0), isNull);
    });
  });
}
