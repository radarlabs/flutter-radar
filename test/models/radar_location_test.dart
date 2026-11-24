import 'package:flutter_radar/src/models/radar_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadarLocation', () {
    test('negative accuracy, speed, and course become null', () {
      final location =
          RadarLocation.fromMap({
            'latitude': 40.7,
            'longitude': -73.9,
            'accuracy': -1,
            'altitude': -10.5,
            'verticalAccuracy': -1,
            'speed': -1,
            'speedAccuracy': -1,
            'course': -1,
            'courseAccuracy': -1,
          })!;
      expect(location.accuracy, isNull);
      expect(location.verticalAccuracy, isNull);
      expect(location.speed, isNull);
      expect(location.speedAccuracy, isNull);
      expect(location.course, isNull);
      expect(location.courseAccuracy, isNull);
      expect(location.altitude, -10.5);
    });

    test('zero is kept', () {
      final location =
          RadarLocation.fromMap({
            'latitude': 0,
            'longitude': 0,
            'accuracy': 0,
            'speed': 0,
            'course': 0,
          })!;
      expect(location.accuracy, 0);
      expect(location.speed, 0);
      expect(location.course, 0);
    });
  });
}
