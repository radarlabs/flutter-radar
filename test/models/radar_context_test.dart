import 'package:flutter_radar/src/models/radar_context.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('RadarContext', () {
    test('parses a full map', () {
      final c = RadarContext.fromMap({
        'geofences': [circleGeofenceMap, 'junk'],
        'place': {
          '_id': 'p1',
          'name': 'Starbucks',
          'location': {
            'type': 'Point',
            'coordinates': [-73.99, 40.73],
          },
        },
        'country': {'_id': 'c', 'code': 'US', 'type': 'country'},
        'state': {'_id': 's', 'code': 'NY', 'type': 'state'},
        'dma': {'_id': 'd', 'code': '501', 'type': 'dma'},
        'postalCode': {'_id': 'z', 'code': '10003', 'type': 'postalCode'},
      });
      expect(c.geofences.single.id, 'g1');
      expect(c.place?.name, 'Starbucks');
      expect(c.country?.code, 'US');
      expect(c.state?.code, 'NY');
      expect(c.dma?.code, '501');
      expect(c.postalCode?.code, '10003');
    });

    test('empty map (iOS omits empty geofences)', () {
      final c = RadarContext.fromMap({});
      expect(c.geofences, isEmpty);
      expect(c.place, isNull);
      expect(
        RadarContext.fromMap({'geofences': 'x', 'state': 1}).state,
        isNull,
      );
    });
  });
}
