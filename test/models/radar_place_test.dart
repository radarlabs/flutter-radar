import 'package:flutter_radar/src/models/radar_location.dart';
import 'package:flutter_radar/src/models/radar_place.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('RadarPlace', () {
    test('parses a full map', () {
      final p =
          RadarPlace.fromMap({
            '_id': 'p1',
            'name': 'Starbucks',
            'categories': ['food-beverage', 'coffee-shop'],
            'chain': {
              'slug': 'starbucks',
              'name': 'Starbucks',
              'externalId': 'sb',
              'metadata': {'x': true},
            },
            'location': {
              'type': 'Point',
              'coordinates': [-73.99, 40.73],
            },
            'group': 'g',
            'metadata': {'m': 1},
            'address': addressMap,
            'geometryRadius': 30.0,
          })!;
      expect(p.id, 'p1');
      expect(p.name, 'Starbucks');
      expect(p.categories, ['food-beverage', 'coffee-shop']);
      expect(p.chain?.slug, 'starbucks');
      expect(p.chain?.name, 'Starbucks');
      expect(p.chain?.externalId, 'sb');
      expect(p.chain?.metadata, {'x': true});
      expect(
        p.location,
        const RadarCoordinate(latitude: 40.73, longitude: -73.99),
      );
      expect(p.group, 'g');
      expect(p.metadata, {'m': 1});
      expect(p.address?.city, 'New York');
      expect(p.geometryRadius, 30);
    });

    test('a place without a location is dropped', () {
      expect(RadarPlace.fromMap({}), isNull);
      expect(RadarPlace.fromMap({'_id': 'p1', 'location': 'y'}), isNull);
    });

    test('garbage fields', () {
      final junk =
          RadarPlace.fromMap({
            'chain': 'x',
            'location': {
              'type': 'Point',
              'coordinates': [-73.99, 40.73],
            },
            'address': 1,
            'categories': [1, 'a'],
          })!;
      expect(junk.id, '');
      expect(junk.chain, isNull);
      expect(junk.address, isNull);
      expect(junk.categories, ['a']);
      expect(RadarChain.fromMap({}).slug, '');
    });
  });
}
