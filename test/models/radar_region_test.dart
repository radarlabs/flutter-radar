import 'package:flutter_radar/src/models/radar_region.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadarRegion', () {
    test('parses a full map', () {
      final r = RadarRegion.fromMap({
        '_id': 'r1',
        'name': 'United States',
        'code': 'US',
        'type': 'country',
        'flag': '🇺🇸',
        'allowed': true,
        'passed': false,
        'inExclusionZone': false,
        'inBufferZone': true,
        'distanceToBorder': 1234.5,
        'expected': true,
      });
      expect(r.id, 'r1');
      expect(r.name, 'United States');
      expect(r.code, 'US');
      expect(r.type, 'country');
      expect(r.flag, '🇺🇸');
      expect(r.allowed, isTrue);
      expect(r.passed, isFalse);
      expect(r.inExclusionZone, isFalse);
      expect(r.inBufferZone, isTrue);
      expect(r.distanceToBorder, 1234.5);
      expect(r.expected, isTrue);
    });

    test('iOS NaN distance and empty map', () {
      expect(
        RadarRegion.fromMap({'distanceToBorder': double.nan}).distanceToBorder,
        isNull,
      );
      final r = RadarRegion.fromMap({});
      expect(r.id, '');
      expect(r.allowed, isFalse);
      expect(r.passed, isFalse);
      expect(r.inExclusionZone, isFalse);
      expect(r.inBufferZone, isFalse);
      expect(r.expected, isFalse);
    });
  });
}
