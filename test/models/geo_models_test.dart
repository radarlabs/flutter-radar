import 'package:flutter_radar/src/models/radar_address.dart';
import 'package:flutter_radar/src/models/radar_beacon.dart';
import 'package:flutter_radar/src/models/radar_context.dart';
import 'package:flutter_radar/src/models/radar_geofence.dart';
import 'package:flutter_radar/src/models/radar_location.dart';
import 'package:flutter_radar/src/models/radar_place.dart';
import 'package:flutter_radar/src/models/radar_region.dart';
import 'package:flutter_radar/src/models/radar_reveal_risk_token.dart';
import 'package:flutter_test/flutter_test.dart';

const _addressMap = <Object?, Object?>{
  'latitude': 40.7342,
  'longitude': -73.9911,
  'formattedAddress': '841 Broadway, New York, NY 10003 US',
  'country': 'United States',
  'countryCode': 'US',
  'countryFlag': '🇺🇸',
  'dma': 'New York',
  'dmaCode': '501',
  'state': 'New York',
  'stateCode': 'NY',
  'postalCode': '10003',
  'city': 'New York',
  'borough': 'Manhattan',
  'county': 'New York County',
  'neighborhood': 'Greenwich Village',
  'street': 'Broadway',
  'number': '841',
  'addressLabel': '841 Broadway',
  'placeLabel': 'Radar',
  'unit': 'Fl 2',
  'plus4': '4703',
  'distance': 12,
  'layer': 'address',
  'metadata': {'foo': 'bar'},
  'confidence': 'exact',
  'timeZone': {
    'id': 'America/New_York',
    'name': 'Eastern Standard Time',
    'code': 'EST',
    'currentTime': '2026-11-19T10:00:00-05:00',
    'utcOffset': -18000,
    'dstOffset': 0,
  },
  'categories': ['office'],
  'resultId': 'res_1',
};

const _circleGeofenceMap = <Object?, Object?>{
  '_id': 'g1',
  'description': 'Store',
  'tag': 'store',
  'externalId': '123',
  'metadata': {'a': 1},
  'operatingHours': {
    'monday': [
      ['08:00', '17:00'],
    ],
  },
  'geometryCenter': {
    'type': 'Point',
    'coordinates': [-73.99, 40.73],
  },
  'geometryRadius': 100,
  'type': 'Circle',
  'dwellThreshold': 5,
  'stopDetection': true,
};

final _ring = [
  [-73.0, 40.0],
  [-73.1, 40.0],
  [-73.1, 40.1],
  [-73.0, 40.0],
];

void main() {
  group('RadarAddress', () {
    test('parses a full map', () {
      final a = RadarAddress.fromMap(_addressMap);
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

    test('Android "null" strings and empty maps', () {
      final a = RadarAddress.fromMap({'city': 'null', 'confidence': 'none'});
      expect(a.city, isNull);
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
      expect(r.allowed, isNull);
    });
  });

  group('RadarGeofence', () {
    test('parses a circle', () {
      final g = RadarGeofence.fromMap(_circleGeofenceMap);
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
      final g = RadarGeofence.fromMap({'type': 'isochrone'});
      final geometry = g.geometry as RadarPolygonGeometry;
      expect(geometry.coordinates, isEmpty);
      expect(geometry.center, const RadarCoordinate(latitude: 0, longitude: 0));
    });

    test('empty and garbage maps', () {
      final g = RadarGeofence.fromMap({});
      expect(g.id, '');
      expect(g.geometry, isNull);
      final junk = RadarGeofence.fromMap({
        'type': 'Polygon',
        'coordinates': 'x',
        'geometry': 3,
        'geometryCenter': [1, 2],
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

  group('RadarPlace', () {
    test('parses a full map', () {
      final p = RadarPlace.fromMap({
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
        'address': _addressMap,
        'geometryRadius': 30.0,
      });
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

    test('empty and garbage maps', () {
      final p = RadarPlace.fromMap({});
      expect(p.id, '');
      expect(p.categories, isEmpty);
      expect(p.location, isNull);
      final junk = RadarPlace.fromMap({
        'chain': 'x',
        'location': 'y',
        'address': 1,
        'categories': [1, 'a'],
      });
      expect(junk.chain, isNull);
      expect(junk.address, isNull);
      expect(junk.categories, ['a']);
      expect(RadarChain.fromMap({}).slug, '');
    });
  });

  group('RadarBeacon', () {
    test('parses an iBeacon', () {
      final b = RadarBeacon.fromMap({
        'type': 'ibeacon',
        '_id': 'b1',
        'description': 'Front door',
        'externalId': 'door',
        'tag': 'entrance',
        'uuid': 'b9407f30-f5f8-466e-aff9-25556b57fe6d',
        'major': '100',
        'minor': '1',
        'metadata': {'floor': 1},
        'rssi': -60,
        'geometry': {
          'type': 'Point',
          'coordinates': [-73.99, 40.73],
        },
      });
      expect(b.type, RadarBeaconType.iBeacon);
      expect(b.id, 'b1');
      expect(b.description, 'Front door');
      expect(b.externalId, 'door');
      expect(b.tag, 'entrance');
      expect(b.uuid, 'b9407f30-f5f8-466e-aff9-25556b57fe6d');
      expect(b.major, '100');
      expect(b.minor, '1');
      expect(b.metadata, {'floor': 1});
      expect(b.rssi, -60);
      expect(
        b.location,
        const RadarCoordinate(latitude: 40.73, longitude: -73.99),
      );
    });

    test('parses an Android Eddystone beacon', () {
      final b = RadarBeacon.fromMap({
        'type': 'eddystone',
        'uid': 'edd1888d',
        'instance': 'abcdef',
      });
      expect(b.type, RadarBeaconType.eddystone);
      expect(b.uuid, 'edd1888d');
      expect(b.major, 'abcdef');
      expect(b.minor, '');
    });

    test('numeric major/minor, empty and garbage maps', () {
      final b = RadarBeacon.fromMap({'major': 1, 'minor': 2, 'type': 'x'});
      expect(b.major, '1');
      expect(b.minor, '2');
      expect(b.type, RadarBeaconType.iBeacon);
      final empty = RadarBeacon.fromMap({});
      expect(empty.uuid, '');
      expect(empty.location, isNull);
      expect(
        RadarBeacon.fromMap({'geometry': 'x', 'rssi': 'loud'}).rssi,
        isNull,
      );
    });
  });

  group('RadarContext', () {
    test('parses a full map', () {
      final c = RadarContext.fromMap({
        'geofences': [_circleGeofenceMap, 'junk'],
        'place': {'_id': 'p1', 'name': 'Starbucks'},
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

  group('RadarRevealRiskToken', () {
    test('parses an API response', () {
      final t = RadarRevealRiskToken.fromMap({
        '_id': 'rr1',
        'token': 'eyJ...',
        'expiresAt': '2026-11-19T15:10:00.000Z',
        'expiresIn': 600,
        'risk': {
          'level': 'high',
          'reasons': ['vpn', 'mocked'],
        },
        'network': {
          'ipAddress': {
            'ip': '1.2.3.4',
            'city': 'New York',
            'countryCode': 'US',
            'latitude': 40.7,
            'longitude': -74.0,
            'stateAllowed': true,
            'countryAllowed': false,
            'connectionType': 'wifi',
            'categories': ['residential'],
          },
          'privacy': {'vpn': true, 'proxy': false, 'service': 'NordVPN'},
          'asn': {'asn': 'AS15169', 'name': 'Google', 'type': 'hosting'},
        },
        'device': {
          'deviceId': 'dev',
          'deviceOSName': 'iOS',
          'xPlatformType': 'Flutter',
        },
        'extra': 1,
      });
      expect(t.id, 'rr1');
      expect(t.format, RadarResponseFormat.jws);
      expect(t.token, 'eyJ...');
      expect(t.expiresAt, DateTime.utc(2026, 11, 19, 15, 10));
      expect(t.expiresIn, 600);
      expect(t.risk?.level, RadarRevealRiskLevel.high);
      expect(t.risk?.reasons, ['vpn', 'mocked']);
      final ip = t.network!.ipAddress!;
      expect(ip.ip, '1.2.3.4');
      expect(
        ip.coordinate,
        const RadarCoordinate(latitude: 40.7, longitude: -74.0),
      );
      expect(ip.stateAllowed, isTrue);
      expect(ip.countryAllowed, isFalse);
      expect(ip.connectionType, 'wifi');
      expect(ip.categories, ['residential']);
      expect(t.network?.privacy?.vpn, isTrue);
      expect(t.network?.privacy?.service, 'NordVPN');
      expect(t.network?.asn?.asn, 'AS15169');
      expect(t.device?.deviceOSName, 'iOS');
      expect(t.device?.xPlatformType, 'Flutter');
      expect(t.raw['extra'], 1);
    });

    test('parses the response format', () {
      expect(
        RadarRevealRiskToken.fromMap({'_id': 'rr1', 'format': 'id'}).format,
        RadarResponseFormat.id,
      );
      expect(
        RadarRevealRiskToken.fromMap({'format': 'jwe', 'token': 'enc'}).format,
        RadarResponseFormat.jwe,
      );
      expect(
        RadarRevealRiskToken.fromMap({'format': 'future'}).format,
        RadarResponseFormat.jws,
      );
    });

    test('IP coordinate from GeoJSON geometry', () {
      final ip = RadarRevealRiskTokenIpAddress.fromMap({
        'geometry': {
          'type': 'Point',
          'coordinates': [-74.0, 40.7],
        },
      });
      expect(
        ip.coordinate,
        const RadarCoordinate(latitude: 40.7, longitude: -74.0),
      );
    });

    test('empty and garbage maps, level fallback', () {
      final t = RadarRevealRiskToken.fromMap({});
      expect(t.id, '');
      expect(t.risk, isNull);
      expect(t.raw, isEmpty);
      final junk = RadarRevealRiskToken.fromMap({
        'risk': {'level': 'extreme', 'reasons': 'x'},
        'network': 'x',
        'expiresIn': 'soon',
        'expiresAt': 5,
      });
      expect(junk.risk?.level, RadarRevealRiskLevel.none);
      expect(junk.risk?.reasons, isEmpty);
      expect(junk.network, isNull);
      expect(junk.expiresIn, isNull);
    });
  });
}
