import 'package:flutter_radar/src/models/radar_location.dart';
import 'package:flutter_radar/src/models/radar_reveal_risk_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
            'timeZone': {
              'id': 'America/New_York',
              'name': 'Eastern Standard Time',
              'code': 'EST',
            },
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
      expect(t.expiresIn, const Duration(minutes: 10));
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
      expect(ip.timeZone?.id, 'America/New_York');
      expect(ip.timeZone?.code, 'EST');
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
      final ip = RadarRevealRiskTokenNetworkIpAddress.fromMap({
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

    test('non-finite and out-of-range numbers do not throw', () {
      final t = RadarRevealRiskToken.fromMap({
        'expiresIn': double.nan,
        'expiresAt': 9223372036854775807,
        'network': {
          'ipAddress': {'distance': double.infinity, 'timeZone': 'EST'},
        },
      });
      expect(t.expiresIn, isNull);
      expect(t.expiresAt, isNull);
      expect(t.network?.ipAddress?.distance, isNull);
      expect(t.network?.ipAddress?.timeZone, isNull);
      expect(
        RadarRevealRiskToken.fromMap({
          'expiresIn': double.negativeInfinity,
          'expiresAt': double.infinity,
        }).expiresAt,
        isNull,
      );
      expect(
        RadarRevealRiskToken.fromMap({'expiresIn': 600.0}).expiresIn,
        const Duration(minutes: 10),
      );
    });
  });
}
