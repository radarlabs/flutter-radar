import 'package:flutter_radar/src/models/radar_beacon.dart';
import 'package:flutter_radar/src/models/radar_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
      expect(empty.id, isNull);
      expect(empty.description, isNull);
      expect(empty.uuid, '');
      expect(empty.location, isNull);
      expect(
        RadarBeacon.fromMap({'geometry': 'x', 'rssi': 'loud'}).rssi,
        isNull,
      );
    });
  });

  group('RadarBeacon equality', () {
    test('compares uuid, major, and minor like the native SDKs', () {
      const a = RadarBeacon(id: 'b1', uuid: 'u', major: '1', minor: '2');
      const sameIdentity = RadarBeacon(
        id: 'b2',
        description: 'other',
        uuid: 'u',
        major: '1',
        minor: '2',
        rssi: -40,
      );
      expect(a, sameIdentity);
      expect(a.hashCode, sameIdentity.hashCode);
      expect(a, isNot(const RadarBeacon(uuid: 'u', major: '1', minor: '3')));
    });
  });
}
