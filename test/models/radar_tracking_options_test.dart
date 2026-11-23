import 'package:flutter/foundation.dart';
import 'package:flutter_radar/src/models/radar_tracking_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadarTrackingOptions presets', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('getters pick the iOS variant on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(
        RadarTrackingOptions.responsive,
        RadarTrackingOptions.responsiveIOS,
      );
      expect(
        RadarTrackingOptions.continuous,
        RadarTrackingOptions.continuousIOS,
      );
      expect(RadarTrackingOptions.efficient, RadarTrackingOptions.efficientIOS);
      expect(
        RadarTrackingPreset.continuous.options,
        RadarTrackingOptions.continuousIOS,
      );
    });

    test('getters pick the Android variant on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(
        RadarTrackingOptions.responsive,
        RadarTrackingOptions.responsiveAndroid,
      );
      expect(
        RadarTrackingOptions.continuous,
        RadarTrackingOptions.continuousAndroid,
      );
      expect(
        RadarTrackingOptions.efficient,
        RadarTrackingOptions.efficientAndroid,
      );
      expect(
        RadarTrackingPreset.efficient.options,
        RadarTrackingOptions.efficientAndroid,
      );
    });
  });

  group('RadarTrackingOptions', () {
    final start = DateTime.utc(2026, 1, 2, 3, 4, 5, 678);
    final stop = DateTime.utc(2026, 1, 3);
    final full = RadarTrackingOptions(
      desiredStoppedUpdateInterval: const Duration(seconds: 1),
      desiredMovingUpdateInterval: const Duration(seconds: 2),
      desiredSyncInterval: const Duration(seconds: 3),
      desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.low,
      stopDuration: const Duration(minutes: 2),
      stopDistance: 50,
      replay: RadarTrackingOptionsReplay.all,
      syncLocations: RadarTrackingOptionsSyncLocations.stopsAndExits,
      useStoppedGeofence: true,
      stoppedGeofenceRadius: 75,
      useMovingGeofence: true,
      movingGeofenceRadius: 80,
      syncGeofences: false,
      beacons: true,
      useMotion: true,
      usePressure: true,
      startTrackingAfter: start,
      stopTrackingAfter: stop,
      batchInterval: const Duration(seconds: 60),
      batchSize: 5,
      type: RadarTrackingOptionsType.onTrip,
      fastestStoppedUpdateInterval: const Duration(seconds: 4),
      fastestMovingUpdateInterval: const Duration(seconds: 5),
      syncGeofencesLimit: 7,
      foregroundServiceEnabled: true,
      showBlueBar: true,
      useVisits: true,
      useSignificantLocationChanges: true,
      useIndoorScan: true,
    );

    test('toMap emits every key both native parsers read', () {
      expect(full.toMap(), {
        'desiredStoppedUpdateInterval': 1,
        'desiredMovingUpdateInterval': 2,
        'desiredSyncInterval': 3,
        'desiredAccuracy': 'low',
        'stopDuration': 120,
        'stopDistance': 50,
        'replay': 'all',
        'sync': 'stopsAndExits',
        'useStoppedGeofence': true,
        'stoppedGeofenceRadius': 75,
        'useMovingGeofence': true,
        'movingGeofenceRadius': 80,
        'syncGeofences': false,
        'beacons': true,
        'useMotion': true,
        'usePressure': true,
        'startTrackingAfter': start.millisecondsSinceEpoch,
        'stopTrackingAfter': stop.millisecondsSinceEpoch,
        'batchInterval': 60,
        'batchSize': 5,
        'type': 'on-trip',
        'fastestStoppedUpdateInterval': 4,
        'fastestMovingUpdateInterval': 5,
        'syncGeofencesLimit': 7,
        'foregroundServiceEnabled': true,
        'showBlueBar': true,
        'useVisits': true,
        'useSignificantLocationChanges': true,
        'useIndoorScan': true,
      });
    });

    test('fromMap round-trips toMap', () {
      expect(RadarTrackingOptions.fromMap(full.toMap()), full);
      for (final preset in [
        RadarTrackingOptions.responsiveIOS,
        RadarTrackingOptions.responsiveAndroid,
        RadarTrackingOptions.continuousIOS,
        RadarTrackingOptions.continuousAndroid,
        RadarTrackingOptions.efficientIOS,
        RadarTrackingOptions.efficientAndroid,
      ]) {
        expect(RadarTrackingOptions.fromMap(preset.toMap()), preset);
      }
    });

    test('fromMap parses Android getTrackingOptions output', () {
      // Shape of RadarTrackingOptions.toJson() on Android (null dates are
      // dropped by JSONObject.put).
      final options = RadarTrackingOptions.fromMap({
        'desiredStoppedUpdateInterval': 0,
        'fastestStoppedUpdateInterval': 0,
        'desiredMovingUpdateInterval': 150,
        'fastestMovingUpdateInterval': 30,
        'desiredSyncInterval': 20,
        'desiredAccuracy': 'medium',
        'stopDuration': 140,
        'stopDistance': 70,
        'replay': 'stops',
        'sync': 'all',
        'useStoppedGeofence': true,
        'stoppedGeofenceRadius': 100,
        'useMovingGeofence': true,
        'movingGeofenceRadius': 100,
        'syncGeofences': 'nearest',
        'syncGeofencesLimit': 10,
        'foregroundServiceEnabled': false,
        'beacons': false,
        'useMotion': false,
        'usePressure': false,
        'batchInterval': 0,
        'batchSize': 0,
        'type': 'default',
      });
      // What Android reports after startTrackingCustom(responsiveAndroid).
      expect(options, RadarTrackingOptions.responsiveAndroid);
      expect(
        RadarTrackingOptions.fromMap({'syncGeofences': 'none'}).syncGeofences,
        isFalse,
      );
      expect(
        RadarTrackingOptions.fromMap({
          'syncGeofences': 'campaign-only',
        }).syncGeofences,
        isTrue,
      );
    });

    test('fromMap parses iOS getTrackingOptions output', () {
      // Shape of -[RadarTrackingOptions dictionaryValue] on iOS: dates are
      // doubles in milliseconds.
      final options = RadarTrackingOptions.fromMap({
        'desiredStoppedUpdateInterval': 30,
        'desiredMovingUpdateInterval': 30,
        'desiredSyncInterval': 20,
        'desiredAccuracy': 'high',
        'stopDuration': 140,
        'stopDistance': 70,
        'startTrackingAfter': start.millisecondsSinceEpoch.toDouble(),
        'sync': 'all',
        'replay': 'none',
        'showBlueBar': true,
        'useStoppedGeofence': false,
        'stoppedGeofenceRadius': 0,
        'useMovingGeofence': false,
        'movingGeofenceRadius': 0,
        'syncGeofences': true,
        'useVisits': false,
        'useSignificantLocationChanges': false,
        'beacons': false,
        'useIndoorScan': false,
        'useMotion': false,
        'usePressure': false,
        'batchInterval': 0,
        'batchSize': 0,
        'type': 'default',
      });
      expect(
        options,
        RadarTrackingOptions.continuousIOS.copyWith(startTrackingAfter: start),
      );
    });

    test('fromMap never throws on an empty or malformed map', () {
      final options = RadarTrackingOptions.fromMap({
        'desiredAccuracy': 3,
        'replay': 'bogus',
        'stopDistance': 'x',
      });
      expect(
        options.desiredAccuracy,
        RadarTrackingOptionsDesiredAccuracy.medium,
      );
      expect(options.replay, RadarTrackingOptionsReplay.none);
      expect(options.syncLocations, RadarTrackingOptionsSyncLocations.all);
      expect(options.stopDistance, 0);
      expect(options.foregroundServiceEnabled, isNull);
      expect(options.type, RadarTrackingOptionsType.defaultType);
      expect(options.batchInterval, Duration.zero);
      expect(options.batchSize, 0);
    });

    test('toMap asserts that durations are whole seconds', () {
      final options = RadarTrackingOptions.responsive.copyWith(
        desiredSyncInterval: const Duration(milliseconds: 1500),
      );
      expect(options.toMap, throwsA(isA<AssertionError>()));
      expect(
        RadarTrackingOptions.responsive
            .copyWith(fastestMovingUpdateInterval: const Duration(seconds: 30))
            .toMap()['fastestMovingUpdateInterval'],
        30,
      );
    });

    test('copyWith replaces only the given fields', () {
      final copy = RadarTrackingOptions.responsiveIOS.copyWith(beacons: true);
      expect(copy.beacons, isTrue);
      expect(copy.toMap(), {
        ...RadarTrackingOptions.responsiveIOS.toMap(),
        'beacons': true,
      });
      expect(
        RadarTrackingOptions.responsiveIOS.copyWith(),
        RadarTrackingOptions.responsiveIOS,
      );
    });
  });

  group('tracking enums', () {
    test('wire values', () {
      expect(
        RadarTrackingOptionsDesiredAccuracy.values.map((e) => e.wireValue),
        ['high', 'medium', 'low', 'none'],
      );
      expect(RadarTrackingOptionsReplay.values.map((e) => e.wireValue), [
        'stops',
        'none',
        'all',
      ]);
      expect(RadarTrackingOptionsSyncLocations.values.map((e) => e.wireValue), [
        'all',
        'stopsAndExits',
        'events',
        'none',
      ]);
      expect(RadarTrackingOptionsType.values.map((e) => e.wireValue), [
        'default',
        'on-trip',
        'in-geofence',
        'is-user',
      ]);
      expect(RadarTrackingPreset.values.map((e) => e.wireValue), [
        'responsive',
        'continuous',
        'efficient',
      ]);
    });

    test('fallbacks', () {
      expect(
        RadarTrackingOptionsDesiredAccuracy.fromWire('x'),
        RadarTrackingOptionsDesiredAccuracy.medium,
      );
      expect(
        RadarTrackingOptionsReplay.fromWire(null),
        RadarTrackingOptionsReplay.none,
      );
      expect(
        RadarTrackingOptionsSyncLocations.fromWire('stopsandexits'),
        RadarTrackingOptionsSyncLocations.stopsAndExits,
      );
      expect(
        RadarTrackingOptionsType.fromWire('x'),
        RadarTrackingOptionsType.defaultType,
      );
      expect(RadarTrackingPreset.fromWire('x'), RadarTrackingPreset.responsive);
    });
  });
}
