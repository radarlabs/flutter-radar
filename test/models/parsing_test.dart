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
}
