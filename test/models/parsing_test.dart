import 'dart:ui';

import 'package:flutter_radar/src/models/parsing.dart';
import 'package:flutter_radar/src/models/radar_context.dart';
import 'package:flutter_radar/src/models/radar_place.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('parsed collections', () {
    test('are unmodifiable', () {
      final place =
          RadarPlace.fromMap({
            'categories': ['a'],
            'metadata': {'m': 1},
            'location': {
              'type': 'Point',
              'coordinates': [-73.99, 40.73],
            },
          })!;
      expect(() => place.categories.add('b'), throwsUnsupportedError);
      expect(() => place.metadata!['n'] = 2, throwsUnsupportedError);
      final context = RadarContext.fromMap({
        'geofences': [circleGeofenceMap],
      });
      expect(() => context.geofences.clear(), throwsUnsupportedError);
    });
  });

  group('colorToHex', () {
    test('formats each channel in its place', () {
      expect(colorToHex(const Color(0xFFFF0000)), '#FF0000');
      expect(colorToHex(const Color(0xFF00FF00)), '#00FF00');
      expect(colorToHex(const Color(0xFF0000FF)), '#0000FF');
    });

    test('pads with zeros', () {
      expect(colorToHex(const Color(0xFF000000)), '#000000');
      expect(colorToHex(const Color(0xFF00000A)), '#00000A');
    });

    test('uses uppercase hex digits', () {
      expect(colorToHex(const Color(0xFFabcdef)), '#ABCDEF');
    });

    test('drops alpha', () {
      expect(colorToHex(const Color(0x80AB01CD)), '#AB01CD');
      expect(colorToHex(const Color(0x00FFFFFF)), '#FFFFFF');
    });

    test('rounds fractional channels to the nearest byte', () {
      expect(
        colorToHex(const Color.from(alpha: 1, red: 0.5, green: 0, blue: 1)),
        '#8000FF',
      );
    });
  });
}
