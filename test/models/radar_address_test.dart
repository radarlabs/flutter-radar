import 'package:flutter_radar/src/models/radar_address.dart';
import 'package:flutter_radar/src/models/radar_location.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('RadarAddress', () {
    test('parses a full map', () {
      final a = RadarAddress.fromMap(addressMap);
      expect(
        a.coordinate,
        const RadarCoordinate(latitude: 40.7342, longitude: -73.9911),
      );
      expect(a.formattedAddress, '841 Broadway, New York, NY 10003 US');
      expect(a.countryCode, 'US');
      expect(a.countryFlag, '🇺🇸');
      expect(a.dmaCode, '501');
      expect(a.stateCode, 'NY');
      expect(a.borough, 'Manhattan');
      expect(a.number, '841');
      expect(a.unit, 'Fl 2');
      expect(a.plus4, '4703');
      expect(a.distance, 12);
      expect(a.layer, 'address');
      expect(a.metadata, {'foo': 'bar'});
      expect(a.confidence, RadarAddressConfidence.exact);
      expect(a.timeZone?.id, 'America/New_York');
      expect(a.timeZone?.code, 'EST');
      expect(a.timeZone?.utcOffset, -18000);
      expect(a.timeZone?.currentTime, DateTime.utc(2026, 11, 19, 15));
      expect(a.categories, ['office']);
      expect(a.resultId, 'res_1');
    });

    test('Android "null" and empty strings, and empty maps', () {
      final a = RadarAddress.fromMap({
        'city': 'null',
        'unit': '',
        'confidence': 'none',
      });
      expect(a.city, isNull);
      expect(a.unit, isNull);
      expect(a.coordinate, isNull);
      expect(a.confidence, RadarAddressConfidence.none);
      expect(RadarAddress.fromMap({}).categories, isEmpty);
    });

    test('garbage values do not throw', () {
      final a = RadarAddress.fromMap({
        'latitude': 'x',
        'longitude': [],
        'distance': {},
        'confidence': 42,
        'timeZone': 'nope',
        'categories': 'office',
        'metadata': 'm',
      });
      expect(a.coordinate, isNull);
      expect(a.distance, isNull);
      expect(a.confidence, RadarAddressConfidence.none);
      expect(a.timeZone, isNull);
      expect(a.categories, isEmpty);
      expect(a.metadata, isNull);
    });

    test('missing and out-of-range coordinates', () {
      // iOS sends its invalid coordinate when the server sent none.
      expect(
        RadarAddress.fromMap({'latitude': -180, 'longitude': -180}).coordinate,
        isNull,
      );
      expect(
        RadarAddress.fromMap({
          'latitude': double.nan,
          'longitude': double.infinity,
        }).coordinate,
        isNull,
      );
      // Android sends (0, 0) when the server sent none, but it's also a real
      // location, so it's kept.
      expect(
        RadarAddress.fromMap({'latitude': 0, 'longitude': 0}).coordinate,
        const RadarCoordinate(latitude: 0, longitude: 0),
      );
      expect(
        RadarAddress.fromMap({'latitude': 90, 'longitude': -180}).coordinate,
        const RadarCoordinate(latitude: 90, longitude: -180),
      );
    });

    test('confidence fallback', () {
      expect(
        RadarAddressConfidence.fromWire('INTERPOLATED'),
        RadarAddressConfidence.interpolated,
      );
      expect(
        RadarAddressConfidence.fromWire('bogus'),
        RadarAddressConfidence.none,
      );
    });
  });

  group('RadarAddressVerificationStatus', () {
    test('parses Android and iOS strings', () {
      expect(
        RadarAddressVerificationStatus.fromWire('VERIFIED'),
        RadarAddressVerificationStatus.verified,
      );
      expect(
        RadarAddressVerificationStatus.fromWire('PARTIALLY_VERIFIED'),
        RadarAddressVerificationStatus.partiallyVerified,
      );
      expect(
        RadarAddressVerificationStatus.fromWire('partially verified'),
        RadarAddressVerificationStatus.partiallyVerified,
      );
      expect(
        RadarAddressVerificationStatus.fromWire('AMBIGUOUS'),
        RadarAddressVerificationStatus.ambiguous,
      );
      expect(
        RadarAddressVerificationStatus.fromWire('UNVERIFIED'),
        RadarAddressVerificationStatus.unverified,
      );
      // Android
      expect(
        RadarAddressVerificationStatus.fromWire('NONE'),
        RadarAddressVerificationStatus.none,
      );
      // iOS
      expect(
        RadarAddressVerificationStatus.fromWire('UNKNOWN'),
        RadarAddressVerificationStatus.none,
      );
      expect(
        RadarAddressVerificationStatus.fromWire(null),
        RadarAddressVerificationStatus.none,
      );
    });
  });
}
