// End-to-end tests: the real plugin, native SDKs and Radar API, on a simulator
// or emulator. Run with scripts/e2e.sh; see example/README.md.
//
// Assertions check meaning and shape (status, the user we set, coordinates we
// sent), not exact server content, so any fairly standard project passes.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_radar/flutter_radar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/e2e_config.dart';
import 'support/e2e_host.dart';

// The point scripts/e2e.sh sets as the simulated device location.
const _nyc = <String, dynamic>{
  'latitude': 40.7342,
  'longitude': -73.9911,
  'accuracy': 10.0,
};
const _brooklyn = <String, double>{'latitude': 40.7039, 'longitude': -73.9867};

const _callbackTimeout = Duration(seconds: 15);

void expectSuccess(Map? result) {
  expect(result, isNotNull, reason: 'native returned null');
  expect(result, isNot(contains('error')), reason: '$result');
  expect(result!['status'], 'SUCCESS', reason: '$result');
}

Future<bool> hasLocationPermission() async {
  final status = await Radar.getPermissionsStatus();
  return status != null && status.startsWith('GRANTED');
}

const _noPermission =
    'Location permission not granted. scripts/e2e.sh grants it; if running '
    'by hand, grant it on the device first.';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final platform = Platform.isIOS ? 'ios' : 'android';
  final runId =
      'flutter-e2e-$platform-${DateTime.now().millisecondsSinceEpoch}';
  const description = 'flutter_radar e2e';
  final metadata = <String, dynamic>{'e2e': true, 'runId': runId};

  group('Radar e2e', skip: E2EConfig.skipReason, () {
    setUpAll(() async {
      await setRadarHosts(
        host: E2EConfig.host,
        verifiedHost: E2EConfig.verifiedHost,
      );
      await Radar.initialize(E2EConfig.publishableKey);
      await Radar.setLogLevel('debug');
      await Radar.setAnonymousTrackingEnabled(false);
      await Radar.setUserId(runId);
      await Radar.setDescription(description);
      await Radar.setMetadata(metadata);
      // ignore: avoid_print
      print('flutter_radar e2e userId: $runId');
    });

    tearDownAll(() async {
      await Radar.stopTracking();
    });

    group('local state', () {
      test('isInitialized and sdkVersion', () async {
        expect(await Radar.isInitialized(), isTrue);
        expect(await Radar.sdkVersion(), isNotEmpty);
      });

      test('user fields round-trip', () async {
        expect(await Radar.getUserId(), runId);
        expect(await Radar.getDescription(), description);
        expect(await Radar.getMetadata(), metadata);
      });

      test(
        'tags round-trip',
        skip:
            'Known bug: getTags casts the List<Object?> from the channel to '
            'List<String>?, so it always throws.',
        () async {
          await Radar.setTags(['e2e', 'flutter']);
          expect(await Radar.getTags(), unorderedEquals(['e2e', 'flutter']));
          await Radar.addTags(['extra']);
          expect(await Radar.getTags(), contains('extra'));
          await Radar.removeTags(['extra']);
          expect(await Radar.getTags(), isNot(contains('extra')));
        },
      );

      test('product and language round-trip', () async {
        await Radar.setProduct('flutter-e2e');
        expect(await Radar.getProduct(), 'flutter-e2e');
        await Radar.setUserLanguage('en');
        expect(await Radar.getUserLanguage(), 'en');
      });
    });

    group('trackOnce with an explicit location', () {
      test('returns the location and the user we set', () async {
        final result = await Radar.trackOnce(location: _nyc);
        expectSuccess(result);

        final location = result!['location'] as Map;
        expect(location['latitude'], closeTo(_nyc['latitude'] as double, 1e-4));
        expect(
          location['longitude'],
          closeTo(_nyc['longitude'] as double, 1e-4),
        );

        final user = result['user'] as Map;
        expect(user['userId'], runId);
        expect(user['description'], description);
        expect(result['events'], isA<List>());
      });

      test(
        'returns the user metadata we set',
        skip:
            Platform.isIOS
                ? 'Known native iOS SDK bug: RadarAPIClient replaces user.metadata '
                    'in the track response with its locationMetadata '
                    '(radar-sdk-ios #439), so custom metadata never reaches the '
                    'app.'
                : null,
        () async {
          final result = await Radar.trackOnce(location: _nyc);
          expectSuccess(result);
          final user = result!['user'] as Map;
          expect(user['metadata'], containsPair('runId', runId));
        },
      );

      test('delivers onLocation to Dart', () async {
        final received = Completer<Map>();
        Radar.onLocation((event) {
          if (!received.isCompleted) received.complete(event);
        });
        addTearDown(Radar.offLocation);

        expectSuccess(await Radar.trackOnce(location: _nyc));

        final event = await received.future.timeout(_callbackTimeout);
        expect((event['user'] as Map)['userId'], runId);
        expect(event['location'], isA<Map>());
      });

      test('delivers onLog to Dart at debug level', () async {
        final received = Completer<Map>();
        Radar.onLog((event) {
          if (!received.isCompleted) received.complete(event);
        });
        addTearDown(Radar.offLog);

        expectSuccess(await Radar.trackOnce(location: _nyc));

        final event = await received.future.timeout(_callbackTimeout);
        expect(event['message'], isA<String>());
      });
    });

    group('device location', () {
      test('getLocation', () async {
        if (!await hasLocationPermission())
          return markTestSkipped(_noPermission);
        final result = await Radar.getLocation('high');
        expectSuccess(result);
        final location = result!['location'] as Map;
        expect(location['latitude'], isA<num>());
        expect(location['longitude'], isA<num>());
      });

      test('trackOnce without a location delivers onClientLocation', () async {
        if (!await hasLocationPermission())
          return markTestSkipped(_noPermission);
        final received = Completer<Map>();
        Radar.onClientLocation((event) {
          if (!received.isCompleted) received.complete(event);
        });
        addTearDown(Radar.offClientLocation);

        final result = await Radar.trackOnce();
        expectSuccess(result);
        expect((result!['user'] as Map)['userId'], runId);

        final event = await received.future.timeout(_callbackTimeout);
        expect(event['location'], isA<Map>());
      });

      test('reverseGeocode without a location', () async {
        if (!await hasLocationPermission())
          return markTestSkipped(_noPermission);
        final result = await Radar.reverseGeocode();
        expectSuccess(result);
        expect(result!['addresses'], isNotEmpty);
      });

      test('startTracking, isTracking, stopTracking', () async {
        if (!await hasLocationPermission())
          return markTestSkipped(_noPermission);
        await Radar.startTracking('responsive');
        expect(await Radar.isTracking(), isTrue);
        expect(await Radar.getTrackingOptions(), isNotNull);
        await Radar.stopTracking();
        expect(await Radar.isTracking(), isFalse);
      });
    });

    group('trackVerified', skip: E2EConfig.verifiedSkipReason, () {
      test('returns a token for the user and delivers onToken', () async {
        if (!await hasLocationPermission())
          return markTestSkipped(_noPermission);
        final received = Completer<Map>();
        Radar.onToken((event) {
          if (!received.isCompleted) received.complete(event);
        });
        addTearDown(Radar.offToken);

        final result = await Radar.trackVerified(
          reason: 'e2e',
          transactionId: runId,
        );
        expectSuccess(result);

        final token = result!['token'] as Map;
        expect(
          token['token'],
          isA<String>().having((t) => t, 'token', isNotEmpty),
        );
        // Simulators and emulators fail attestation, so passed is usually
        // false here. Only its presence is checked.
        expect(token['passed'], isA<bool>());
        expect(token['expiresAt'], isNotNull);
        expect((token['user'] as Map)['userId'], runId);

        final event = await received.future.timeout(_callbackTimeout);
        expect(event['token'], isA<Map>());
      });

      test('getVerifiedLocationToken returns a token', () async {
        if (!await hasLocationPermission())
          return markTestSkipped(_noPermission);
        final result = await Radar.getVerifiedLocationToken();
        expectSuccess(result);
        expect((result!['token'] as Map)['token'], isNotEmpty);
      });

      test('clearVerifiedLocationToken and isTrackingVerified', () async {
        await Radar.clearVerifiedLocationToken();
        expect(await Radar.isTrackingVerified(), isFalse);
      });
    });

    group('network APIs', () {
      test('geocode', () async {
        final result = await Radar.geocode('20 Jay St, Brooklyn, NY');
        expectSuccess(result);
        final addresses = result!['addresses'] as List;
        expect(addresses, isNotEmpty);
        expect((addresses.first as Map)['latitude'], isA<num>());
      });

      test('reverseGeocode with a location', () async {
        final result = await Radar.reverseGeocode(location: _nyc);
        expectSuccess(result);
        expect(result!['addresses'], isNotEmpty);
      });

      test('ipGeocode', () async {
        final result = await Radar.ipGeocode();
        expectSuccess(result);
        expect(result!['address'], isA<Map>());
      });

      test('autocomplete', () async {
        final result = await Radar.autocomplete(
          query: '20 Jay St',
          near: _nyc,
          limit: 5,
        );
        expectSuccess(result);
        expect(result!['addresses'], isNotEmpty);
      });

      test('searchPlaces', () async {
        final result = await Radar.searchPlaces(
          near: _nyc,
          radius: 1000,
          chains: ['starbucks'],
          limit: 5,
        );
        expectSuccess(result);
        expect(result!['places'], isA<List>());
      });

      test('searchGeofences', () async {
        // Passes every optional argument: omitting them is a known bug
        // (see 'known bridge bugs').
        final result = await Radar.searchGeofences(
          near: _nyc,
          radius: 1000,
          limit: 10,
          tags: [],
          metadata: {},
          includeGeometry: false,
        );
        expectSuccess(result);
        // The project may have no geofences nearby, so empty is fine.
        expect(result!['geofences'], isA<List>());
      });

      test('getContext', () async {
        final result = await Radar.getContext(_nyc);
        expectSuccess(result);
        expect(result!['context'], isA<Map>());
      });

      test(
        'getDistance returns a route for each requested mode',
        skip:
            Platform.isAndroid
                ? 'Known bug: the Android bridge ignores modes (loops over an '
                    'empty array), so the API returns ERROR_BAD_REQUEST.'
                : null,
        () async {
          final result = await Radar.getDistance(
            origin: {'latitude': 40.7342, 'longitude': -73.9911},
            destination: _brooklyn,
            modes: ['car', 'foot'],
            units: 'imperial',
          );
          expectSuccess(result);
          final routes = result!['routes'] as Map;
          expect(routes, contains('car'));
          expect(routes, contains('foot'));
        },
      );

      test('getMatrix', () async {
        final result = await Radar.getMatrix(
          origins: [
            {'latitude': 40.7342, 'longitude': -73.9911},
            _brooklyn,
          ],
          destinations: [
            {'latitude': 40.64189, 'longitude': -73.78779},
          ],
          mode: 'car',
          units: 'imperial',
        );
        expectSuccess(result);
        expect(result!['matrix'], isNotNull);
      });

      test('logConversion', () async {
        final result = await Radar.logConversion(
          name: 'flutter_e2e',
          revenue: 1.5,
          metadata: {'runId': runId},
        );
        expectSuccess(result);
        expect(result!['event'], isA<Map>());
      });

      test('validateAddress', () async {
        final result = await Radar.validateAddress({
          'city': 'NEW YORK',
          'stateCode': 'NY',
          'postalCode': '10003',
          'countryCode': 'US',
          'street': 'BROADWAY',
          'number': '841',
        });
        expect(result, isNotNull);
        expect(result, isNot(contains('error')), reason: '$result');
        // Address validation is a paid feature, so a plan error also counts
        // as the bridge working.
        expect(
          result!['status'],
          isIn(['SUCCESS', 'ERROR_PAYMENT_REQUIRED', 'ERROR_FORBIDDEN']),
          reason: '$result',
        );
      });
    });

    group('trips', () {
      tearDown(() async {
        // Leave no active trip behind if an assertion failed midway. With no
        // active trip this returns an error status, which is fine.
        await Radar.cancelTrip();
        await Radar.stopTracking();
      });

      test('start, update, complete', () async {
        final externalId = '$runId-complete';
        final started = await Radar.startTrip(
          tripOptions: {
            'externalId': externalId,
            'mode': 'car',
            'metadata': {'runId': runId},
          },
        );
        expectSuccess(started);
        expect((started!['trip'] as Map)['externalId'], externalId);
        expect((await Radar.getTripOptions())!['externalId'], externalId);

        final updated = await Radar.updateTrip(
          options: {
            'externalId': externalId,
            'metadata': {'runId': runId, 'updated': true},
          },
          status: 'approaching',
        );
        expectSuccess(updated);

        final completed = await Radar.completeTrip();
        expectSuccess(completed);
        expect((completed!['trip'] as Map)['status'], 'completed');
      });

      test(
        'getTrip returns the active trip',
        skip:
            Platform.isAndroid
                ? 'Known bug: the Android bridge throws JSONException (Forbidden '
                    'numeric value: NaN) converting the active trip to JSON.'
                : null,
        () async {
          final externalId = '$runId-get';
          expectSuccess(
            await Radar.startTrip(tripOptions: {'externalId': externalId}),
          );
          final trip = await Radar.getTrip();
          expect(trip, isNotNull);
          expect(trip, isNot(contains('error')), reason: '$trip');
          expect(trip!['externalId'], externalId);
        },
      );

      test('start, cancel', () async {
        final externalId = '$runId-cancel';
        expectSuccess(
          await Radar.startTrip(tripOptions: {'externalId': externalId}),
        );
        final canceled = await Radar.cancelTrip();
        expectSuccess(canceled);
        expect((canceled!['trip'] as Map)['status'], 'canceled');
      });
    });

    group('known bridge bugs', () {
      test(
        'searchGeofences with only near, radius and limit',
        skip:
            Platform.isIOS
                ? 'Known bug: the iOS bridge passes NSNull for omitted tags and '
                    'metadata, and the SDK crashes the app.'
                : 'Known bug: the Android bridge throws NullPointerException for '
                    'omitted tags (ArrayList.toArray) and includeGeometry '
                    '(Boolean unboxing).',
        () async {
          final result = await Radar.searchGeofences(
            near: _nyc,
            radius: 1000,
            limit: 10,
          );
          expectSuccess(result);
        },
      );

      test(
        'mockTracking completes',
        skip:
            'Known bug: neither native bridge replies to mockTracking, so '
            'the Future never completes.',
        () async {
          final result = await Radar.mockTracking(
            origin: {'latitude': 40.7342, 'longitude': -73.9911},
            destination: _brooklyn,
            mode: 'car',
            steps: 2,
            interval: 1,
          );
          expectSuccess(result);
        },
      );
    });
  });
}
