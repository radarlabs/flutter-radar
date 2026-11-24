import 'package:flutter_radar/src/models/radar_fraud.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('RadarFraud', () {
    test('parses every flag', () {
      final all = RadarFraud.fromMap({for (final key in fraud.keys) key: true});
      expect([
        all.passed,
        all.bypassed,
        all.verified,
        all.proxy,
        all.mocked,
        all.compromised,
        all.jumped,
        all.inaccurate,
        all.sharing,
        all.blocked,
      ], everyElement(isTrue));
    });

    test('missing and garbage values are false', () {
      for (final map in const <Map<Object?, Object?>>[
        {},
        {'passed': 'yes', 'proxy': [], 'mocked': {}, 'blocked': null},
      ]) {
        final f = RadarFraud.fromMap(map);
        expect([
          f.passed,
          f.proxy,
          f.mocked,
          f.blocked,
          f.verified,
        ], everyElement(isFalse));
      }
    });
  });
}
