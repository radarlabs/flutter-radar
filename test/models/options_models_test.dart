import 'package:flutter/foundation.dart';
import 'package:flutter_radar/src/models/radar_enums.dart';
import 'package:flutter_radar/src/models/radar_foreground_service_options.dart';
import 'package:flutter_radar/src/models/radar_in_app_message.dart';
import 'package:flutter_radar/src/models/radar_notification_options.dart';
import 'package:flutter_radar/src/models/radar_tracking_options.dart';
import 'package:flutter_test/flutter_test.dart';

// The preset maps from flutter_radar 3.x (`Radar.presetResponsiveIOS` etc.),
// copied verbatim, so the typed presets can be checked against them.
const Map<String, Object?> _oldContinuousIOS = {
  "desiredStoppedUpdateInterval": 30,
  "desiredMovingUpdateInterval": 30,
  "desiredSyncInterval": 20,
  "desiredAccuracy": 'high',
  "stopDuration": 140,
  "stopDistance": 70,
  "replay": 'none',
  "useStoppedGeofence": false,
  "showBlueBar": true,
  "startTrackingAfter": null,
  "stopTrackingAfter": null,
  "stoppedGeofenceRadius": 0,
  "useMovingGeofence": false,
  "movingGeofenceRadius": 0,
  "syncGeofences": true,
  "useVisits": false,
  "useSignificantLocationChanges": false,
  "beacons": false,
  "useMotion": false,
  "usePressure": false,
  "sync": 'all',
};

const Map<String, Object?> _oldContinuousAndroid = {
  "desiredStoppedUpdateInterval": 30,
  "fastestStoppedUpdateInterval": 30,
  "desiredMovingUpdateInterval": 30,
  "fastestMovingUpdateInterval": 30,
  "desiredSyncInterval": 20,
  "desiredAccuracy": 'high',
  "stopDuration": 140,
  "stopDistance": 70,
  "replay": 'none',
  "sync": 'all',
  "useStoppedGeofence": false,
  "stoppedGeofenceRadius": 0,
  "useMovingGeofence": false,
  "movingGeofenceRadius": 0,
  "syncGeofences": true,
  "syncGeofencesLimit": 0,
  "foregroundServiceEnabled": true,
  "beacons": false,
  "useMotion": false,
  "usePressure": false,
  "startTrackingAfter": null,
  "stopTrackingAfter": null,
};

const Map<String, Object?> _oldResponsiveIOS = {
  "desiredStoppedUpdateInterval": 0,
  "desiredMovingUpdateInterval": 150,
  "desiredSyncInterval": 20,
  "desiredAccuracy": 'medium',
  "stopDuration": 140,
  "stopDistance": 70,
  "replay": 'stops',
  "useStoppedGeofence": true,
  "showBlueBar": false,
  "startTrackingAfter": null,
  "stopTrackingAfter": null,
  "stoppedGeofenceRadius": 100,
  "useMovingGeofence": true,
  "movingGeofenceRadius": 100,
  "syncGeofences": true,
  "useVisits": true,
  "useSignificantLocationChanges": true,
  "beacons": false,
  "useMotion": false,
  "usePressure": false,
  "sync": 'all',
};

const Map<String, Object?> _oldResponsiveAndroid = {
  "desiredStoppedUpdateInterval": 0,
  "fastestStoppedUpdateInterval": 0,
  "desiredMovingUpdateInterval": 150,
  "fastestMovingUpdateInterval": 30,
  "desiredSyncInterval": 20,
  "desiredAccuracy": "medium",
  "stopDuration": 140,
  "stopDistance": 70,
  "replay": 'stops',
  "sync": 'all',
  "useStoppedGeofence": true,
  "stoppedGeofenceRadius": 100,
  "useMovingGeofence": true,
  "movingGeofenceRadius": 100,
  "syncGeofences": true,
  "syncGeofencesLimit": 10,
  "foregroundServiceEnabled": false,
  "beacons": false,
  "useMotion": false,
  "usePressure": false,
  "startTrackingAfter": null,
  "stopTrackingAfter": null,
};

const Map<String, Object?> _oldEfficientIOS = {
  "desiredStoppedUpdateInterval": 0,
  "desiredMovingUpdateInterval": 0,
  "desiredSyncInterval": 0,
  "desiredAccuracy": "medium",
  "stopDuration": 0,
  "stopDistance": 0,
  "replay": 'stops',
  "useStoppedGeofence": false,
  "showBlueBar": false,
  "startTrackingAfter": null,
  "stopTrackingAfter": null,
  "stoppedGeofenceRadius": 0,
  "useMovingGeofence": false,
  "movingGeofenceRadius": 0,
  "syncGeofences": true,
  "useVisits": true,
  "useSignificantLocationChanges": false,
  "beacons": false,
  "useMotion": false,
  "usePressure": false,
  "sync": 'all',
};

const Map<String, Object?> _oldEfficientAndroid = {
  "desiredStoppedUpdateInterval": 3600,
  "fastestStoppedUpdateInterval": 1200,
  "desiredMovingUpdateInterval": 1200,
  "fastestMovingUpdateInterval": 360,
  "desiredSyncInterval": 140,
  "desiredAccuracy": 'medium',
  "stopDuration": 140,
  "stopDistance": 70,
  "replay": 'stops',
  "sync": 'all',
  "useStoppedGeofence": false,
  "stoppedGeofenceRadius": 0,
  "useMovingGeofence": false,
  "movingGeofenceRadius": 0,
  "syncGeofences": true,
  "syncGeofencesLimit": 10,
  "foregroundServiceEnabled": false,
  "beacons": false,
  "useMotion": false,
  "usePressure": false,
  "startTrackingAfter": null,
  "stopTrackingAfter": null,
};

/// The old presets sent explicit nulls for the dates; the native parsers
/// treat a null and a missing key the same.
Map<String, Object?> _withoutNulls(Map<String, Object?> map) =>
    Map.of(map)..removeWhere((_, v) => v == null);

void main() {
  group('RadarTrackingOptions presets', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    final cases = {
      'responsiveIOS': (RadarTrackingOptions.responsiveIOS, _oldResponsiveIOS),
      'responsiveAndroid': (
        RadarTrackingOptions.responsiveAndroid,
        _oldResponsiveAndroid,
      ),
      'continuousIOS': (RadarTrackingOptions.continuousIOS, _oldContinuousIOS),
      'continuousAndroid': (
        RadarTrackingOptions.continuousAndroid,
        _oldContinuousAndroid,
      ),
      'efficientIOS': (RadarTrackingOptions.efficientIOS, _oldEfficientIOS),
      'efficientAndroid': (
        RadarTrackingOptions.efficientAndroid,
        _oldEfficientAndroid,
      ),
    };
    for (final MapEntry(key: name, value: (options, old)) in cases.entries) {
      test('$name matches the 3.x preset map', () {
        expect(options.toMap(), _withoutNulls(old));
      });
    }

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
      expect(
        options,
        RadarTrackingOptions.responsiveAndroid.copyWith(
          batchInterval: Duration.zero,
          batchSize: 0,
          type: RadarTrackingOptionsType.defaultType,
        ),
      );
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
        RadarTrackingOptions.continuousIOS.copyWith(
          startTrackingAfter: start,
          useIndoorScan: false,
          batchInterval: Duration.zero,
          batchSize: 0,
          type: RadarTrackingOptionsType.defaultType,
        ),
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
      expect(options.type, isNull);
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

  group('RadarNotificationOptions', () {
    test('toMap matches RadarNotificationOptions.fromJson keys', () {
      const options = RadarNotificationOptions(
        iconString: 'ic',
        iconColor: '#111111',
        foregroundServiceIconString: 'fg',
        foregroundServiceIconColor: '#222222',
        eventIconString: 'ev',
        eventIconColor: '#333333',
        deepLink: 'app://x',
      );
      expect(options.toMap(), {
        'iconString': 'ic',
        'iconColor': '#111111',
        'foregroundServiceIconString': 'fg',
        'foregroundServiceIconColor': '#222222',
        'eventIconString': 'ev',
        'eventIconColor': '#333333',
        'deepLink': 'app://x',
      });
    });

    test('toMap omits null fields', () {
      expect(const RadarNotificationOptions(iconString: 'ic').toMap(), {
        'iconString': 'ic',
      });
    });
  });

  group('RadarForegroundServiceOptions', () {
    test('toMap matches RadarTrackingOptionsForegroundService.fromJson', () {
      const options = RadarForegroundServiceOptions(
        text: 'Tracking',
        title: 'Radar',
        icon: 42,
        iconString: 'ic',
        iconColor: '#FF0000',
        updatesOnly: true,
        activity: 'com.example.MainActivity',
        importance: 3,
        id: 7,
        channelName: 'Location',
        deepLink: 'app://x',
      );
      expect(options.toMap(), {
        'text': 'Tracking',
        'title': 'Radar',
        'icon': 42,
        'iconString': 'ic',
        'iconColor': '#FF0000',
        'updatesOnly': true,
        'activity': 'com.example.MainActivity',
        'importance': 3,
        'id': 7,
        'channelName': 'Location',
        'deepLink': 'app://x',
      });
    });

    test('toMap omits null fields', () {
      expect(const RadarForegroundServiceOptions().toMap(), {
        'updatesOnly': false,
      });
    });
  });

  group('RadarInAppMessage', () {
    const message = RadarInAppMessage(
      title: RadarInAppMessageText(text: 'Hi', color: '#000000'),
      body: RadarInAppMessageText(text: 'Body', color: '#111111'),
      button: RadarInAppMessageButton(
        text: 'Go',
        color: '#FFFFFF',
        backgroundColor: '#0000FF',
        deepLink: 'app://go',
      ),
      image: RadarInAppMessageImage(
        name: 'hero',
        url: 'https://example.com/a.png',
      ),
      metadata: {'campaign': 'x', 'n': 1},
    );

    test('toMap matches what both SDKs parse', () {
      expect(message.toMap(), {
        'title': {'text': 'Hi', 'color': '#000000'},
        'body': {'text': 'Body', 'color': '#111111'},
        'button': {
          'text': 'Go',
          'color': '#FFFFFF',
          'backgroundColor': '#0000FF',
          'deepLink': 'app://go',
        },
        'image': {'name': 'hero', 'url': 'https://example.com/a.png'},
        'metadata': {'campaign': 'x', 'n': 1},
      });
    });

    test('toMap omits optional parts and null strings', () {
      // iOS casts these sub-maps to [String: String], so they must not
      // contain nulls.
      const minimal = RadarInAppMessage(
        title: RadarInAppMessageText(text: 'Hi', color: '#000000'),
        body: RadarInAppMessageText(text: 'Body', color: '#111111'),
        button: RadarInAppMessageButton(
          text: 'Go',
          color: '#FFFFFF',
          backgroundColor: '#0000FF',
        ),
        image: RadarInAppMessageImage(name: 'hero'),
      );
      expect(minimal.toMap(), {
        'title': {'text': 'Hi', 'color': '#000000'},
        'body': {'text': 'Body', 'color': '#111111'},
        'button': {
          'text': 'Go',
          'color': '#FFFFFF',
          'backgroundColor': '#0000FF',
        },
        'image': {'name': 'hero'},
        'metadata': <String, Object?>{},
      });
    });

    test('fromMap round-trips toMap', () {
      final parsed = RadarInAppMessage.fromMap(message.toMap())!;
      expect(parsed.toMap(), message.toMap());
    });

    test('fromMap treats Android empty-string defaults as null', () {
      final parsed =
          RadarInAppMessage.fromMap({
            'title': {'text': 'Hi', 'color': '#000000'},
            'body': {'text': 'Body', 'color': '#111111'},
            'button': {
              'text': 'Go',
              'color': '#FFFFFF',
              'backgroundColor': '#0000FF',
              'deepLink': '',
            },
            'image': {'name': 'hero', 'url': ''},
          })!;
      expect(parsed.button!.deepLink, isNull);
      expect(parsed.image!.url, isNull);
      expect(parsed.metadata, isEmpty);
    });

    test('fromMap returns null without a valid title or body', () {
      expect(RadarInAppMessage.fromMap(null), isNull);
      expect(RadarInAppMessage.fromMap({}), isNull);
      expect(
        RadarInAppMessage.fromMap({
          'title': {'text': 'Hi'},
          'body': {'text': 'Body', 'color': '#111111'},
        }),
        isNull,
      );
    });

    test('fromMap drops an invalid button', () {
      final parsed =
          RadarInAppMessage.fromMap({
            'title': {'text': 'Hi', 'color': '#000000'},
            'body': {'text': 'Body', 'color': '#111111'},
            'button': {'text': 'Go'},
          })!;
      expect(parsed.button, isNull);
    });
  });

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
