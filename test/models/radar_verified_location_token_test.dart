import 'package:flutter_radar/src/models/radar_event.dart';
import 'package:flutter_radar/src/models/radar_reveal_risk_token.dart';
import 'package:flutter_radar/src/models/radar_update.dart';
import 'package:flutter_radar/src/models/radar_verified_location_token.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('RadarVerifiedLocationToken', () {
    // Both platforms send the API's response as-is.
    final tokenMap = <Object?, Object?>{
      'meta': {'code': 200},
      '_id': 'check-1',
      'token': 'eyJhbGciOi.payload.signature',
      'expiresAt': '2026-11-19T13:00:00.000Z',
      'expiresIn': 3600,
      'passed': false,
      'failureReasons': ['fraud_mocked_from_mock_provider'],
      'user': {
        ...iosUser,
        'locationAccuracy': 10,
        'fraud': {...fraud, 'passed': false, 'mocked': true},
      },
      'events': [
        {
          '_id': 'event-8',
          'type': 'user.failed_fraud',
          'createdAt': '2026-11-19T12:59:00.000Z',
          'location': {
            'type': 'Point',
            'coordinates': [-122.4194, 37.7749],
          },
          'locationAccuracy': 10,
          'confidence': 3,
          'verification': 0,
        },
      ],
    };

    test('parses a token', () {
      final token = RadarVerifiedLocationToken.fromMap(tokenMap);
      expect(token.id, 'check-1');
      expect(token.token, 'eyJhbGciOi.payload.signature');
      expect(token.format, RadarResponseFormat.jws);
      expect(token.expiresAt, DateTime.utc(2026, 11, 19, 13));
      expect(token.expiresIn, 3600);
      expect(token.passed, isFalse);
      expect(token.failureReasons, ['fraud_mocked_from_mock_provider']);
      expect(token.user!.fraud!.mocked, isTrue);
      expect(token.user!.location!.accuracy, 10);
      expect(token.events.single.type, RadarEventType.userFailedFraud);
      expect(token.events.single.verification, RadarEventVerification.unverify);
      expect(token.raw!['meta'], {'code': 200});
    });

    test('parses reduced JWE and ID responses', () {
      final jwe = RadarVerifiedLocationToken.fromMap({
        'format': 'jwe',
        '_id': 'check-2',
        'token': 'encrypted',
        'expiresIn': 600,
      });
      expect(jwe.format, RadarResponseFormat.jwe);
      expect(jwe.token, 'encrypted');
      expect(jwe.user, isNull);
      expect(jwe.events, isEmpty);

      final id = RadarVerifiedLocationToken.fromMap({
        'format': 'id',
        '_id': 'check-3',
      });
      expect(id.format, RadarResponseFormat.id);
      expect(id.id, 'check-3');
      expect(id.token, isNull);
      expect(id.passed, isFalse);
    });

    test('is parsed from token updates', () {
      final update = RadarUpdate.fromMethodCall('token', {'token': tokenMap});
      expect((update! as RadarTokenUpdate).token!.passed, isFalse);
    });
  });
}
