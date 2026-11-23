import 'package:flutter_radar/src/models/radar_location.dart';
import 'package:flutter_radar/src/models/radar_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadarRoutes', () {
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
      expect(routes.geodesic!.distance!.value, 4800);
      expect(routes.geodesic!.duration, isNull);
      expect(routes.car!.distance!.text, '1.0 mi');
      expect(routes.car!.duration!.value, 4.2);
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
      expect(matrix.routeBetween(1, 1)!.duration!.value, 4.2);
      expect(matrix.routeBetween(2, 0), isNull);
      expect(matrix.routeBetween(0, 5), isNull);
      expect(matrix.routeBetween(-1, 0), isNull);

      expect(RadarRouteMatrix.fromWire({'not': 'a list'}), isNull);
    });
  });
}
