import 'package:flutter_radar/src/models/radar_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadarLogLevel', () {
    test('wire values match the bridges', () {
      expect(RadarLogLevel.values.map((e) => e.wireValue), [
        'none',
        'error',
        'warning',
        'info',
        'debug',
      ]);
      expect(RadarLogLevel.fromWire('DEBUG'), RadarLogLevel.debug);
      expect(RadarLogLevel.fromWire('x'), RadarLogLevel.none);
    });
  });

  group('RadarPermissionsStatus', () {
    test('parses every value both bridges return', () {
      expect(
        RadarPermissionsStatus.fromWire('GRANTED_FOREGROUND'),
        RadarPermissionsStatus.grantedForeground,
      );
      expect(
        RadarPermissionsStatus.fromWire('GRANTED_BACKGROUND'),
        RadarPermissionsStatus.grantedBackground,
      );
      expect(
        RadarPermissionsStatus.fromWire('DENIED'),
        RadarPermissionsStatus.denied,
      );
      expect(
        RadarPermissionsStatus.fromWire('NOT_DETERMINED'),
        RadarPermissionsStatus.notDetermined,
      );
    });

    test('falls back to unknown', () {
      expect(
        RadarPermissionsStatus.fromWire('RESTRICTED'),
        RadarPermissionsStatus.unknown,
      );
      expect(
        RadarPermissionsStatus.fromWire(null),
        RadarPermissionsStatus.unknown,
      );
    });

    test('isGranted', () {
      expect(RadarPermissionsStatus.grantedForeground.isGranted, isTrue);
      expect(RadarPermissionsStatus.grantedBackground.isGranted, isTrue);
      expect(RadarPermissionsStatus.denied.isGranted, isFalse);
    });
  });

  group('routing enums', () {
    test('RadarRouteMode wire values and fallback', () {
      expect(RadarRouteMode.values.map((e) => e.wireValue), [
        'foot',
        'bike',
        'car',
        'truck',
        'motorbike',
      ]);
      expect(RadarRouteMode.fromWire('FOOT'), RadarRouteMode.foot);
      expect(RadarRouteMode.fromWire('plane'), RadarRouteMode.car);
    });

    test('RadarRouteUnits wire values and fallback', () {
      expect(RadarRouteUnits.values.map((e) => e.wireValue), [
        'imperial',
        'metric',
      ]);
      expect(RadarRouteUnits.fromWire('METRIC'), RadarRouteUnits.metric);
      expect(RadarRouteUnits.fromWire(null), RadarRouteUnits.imperial);
    });
  });
}
