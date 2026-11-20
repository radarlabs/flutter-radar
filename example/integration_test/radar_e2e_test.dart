// End-to-end tests: the real plugin, native SDKs and Radar API, on a simulator
// or emulator. Run with scripts/e2e.sh; see example/README.md.
//
// Assertions check meaning and shape (status, the user we set, coordinates we
// sent), not exact server content, so any fairly standard project passes.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_radar/flutter_radar.dart';
import 'package:flutter_radar_example/environment.dart' show setRadarHosts;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/e2e_config.dart';

// The point scripts/e2e.sh sets as the simulated device location.
const _nyc = <String, dynamic>{
  'latitude': 40.7342,
  'longitude': -73.9911,
  'accuracy': 10.0,
};
// Kilometers from the test location and the geofences, so tracking here puts
// the user outside them.
const _brooklyn = <String, double>{
  'latitude': 40.7039,
  'longitude': -73.9867,
  'accuracy': 10.0,
};

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

const _androidNestedTripOptions =
    'Known bug: the Android bridge copies nested lists and maps in trip '
    'options (jsonForMap) as raw ArrayList/HashMap values, which the SDK '
    "can't read, so legs and metadata never reach the API.";

const _paymentRequired =
    'Address validation needs an Enterprise plan or trial '
    '(ERROR_PAYMENT_REQUIRED).';

/// Fails instead of hanging when a bridge never replies.
Future<T> replied<T>(Future<T> call) => call.timeout(_callbackTimeout);

List<String> eventTypes(Map result) => [
  for (final event in result['events'] as List)
    (event as Map)['type'] as String,
];

/// The event of [type] in [result], failing the test if there isn't one.
Map eventOf(Map result, String type) {
  expect(eventTypes(result), contains(type), reason: '$result');
  return (result['events'] as List).cast<Map>().firstWhere(
    (event) => event['type'] == type,
  );
}

/// Collects every event delivered to [Radar.onEvents], from any track.
class DeliveredEvents {
  DeliveredEvents() {
    Radar.onEvents((result) {
      _events.addAll((result['events'] as List).cast<Map>());
    });
    addTearDown(Radar.offEvents);
  }

  final _events = <Map>[];

  /// Waits for an event of [type] for the geofence with [geofenceId].
  Future<Map> waitFor(String type, Object? geofenceId) async {
    final deadline = DateTime.now().add(_callbackTimeout);
    while (true) {
      for (final event in _events) {
        final geofence = event['geofence'] as Map?;
        if (event['type'] == type && geofence?['_id'] == geofenceId) {
          return event;
        }
      }
      if (DateTime.now().isAfter(deadline)) {
        fail(
          'No $type event for geofence $geofenceId was delivered to '
          'onEvents. Delivered: ${_events.map((e) => e['type']).toList()}',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }
}

/// The status of the leg with [legId] in the trip in [result].
Object? legStatus(Map result, String legId) =>
    ((result['trip'] as Map)['legs'] as List).cast<Map>().firstWhere(
      (leg) => leg['_id'] == legId,
    )['status'];

List<Object?> idsOf(Object? list) => [
  for (final item in list as List) (item as Map)['_id'],
];

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

      test('setExpectedAddress sets and clears', () async {
        // There's no getter, so this checks that both calls complete.
        await replied(
          Radar.setExpectedAddress('841 Broadway, New York, NY 10003'),
        );
        await replied(Radar.setExpectedAddress(null));
      });
    });

    group('trackOnce with an explicit location', () {
      test('returns the location and the user we set', () async {
        final result = await Radar.trackOnce(location: _nyc);
        expectSuccess(result);

        final location = result!['location'] as Map;
        // The SDKs return the location they were given, unchanged.
        expect(location['latitude'], _nyc['latitude']);
        expect(location['longitude'], _nyc['longitude']);

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

      test('startTrackingCustom and isUsingRemoteTrackingOptions', () async {
        if (!await hasLocationPermission())
          return markTestSkipped(_noPermission);
        // Start from the SDK's own options so every field is valid on both
        // platforms, and change one to check that the options reach native.
        await Radar.startTracking('responsive');
        final options = Map<String, dynamic>.from(
          (await Radar.getTrackingOptions())!,
        );
        await Radar.stopTracking();
        options['desiredStoppedUpdateInterval'] = 170;

        await replied(Radar.startTrackingCustom(options));
        expect(await Radar.isTracking(), isTrue);
        expect(await Radar.isUsingRemoteTrackingOptions(), isA<bool>());
        expect(
          (await Radar.getTrackingOptions())!['desiredStoppedUpdateInterval'],
          170,
        );
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

      test('validateStreetAddress', () async {
        final result = await Radar.validateStreetAddress(
          street: 'BROADWAY',
          number: '841',
          city: 'NEW YORK',
          stateCode: 'NY',
          postalCode: '10003',
          countryCode: 'US',
        );
        if (result?['status'] == 'ERROR_PAYMENT_REQUIRED') {
          return markTestSkipped(_paymentRequired);
        }
        expectSuccess(result);
        expect(result!['address'], isA<Map>());
      });

      test('validateAddressLabel', () async {
        final result = await Radar.validateAddressLabel(
          addressLabel: '841 BROADWAY',
          city: 'NEW YORK',
          stateCode: 'NY',
          postalCode: '10003',
          countryCode: 'US',
        );
        if (result?['status'] == 'ERROR_PAYMENT_REQUIRED') {
          return markTestSkipped(_paymentRequired);
        }
        expectSuccess(result);
        expect(result!['address'], isA<Map>());
      });
    });

    // Methods that do little or nothing on one platform, or have no observable
    // result. Each test checks only that the call completes.
    group('platform-specific methods complete', () {
      test('logBackgrounding and logResigningActive', () async {
        await replied(Radar.logBackgrounding());
        await replied(Radar.logResigningActive());
      });

      test(
        'logTermination',
        skip:
            Platform.isAndroid
                ? 'Known bug: the Android bridge never replies to '
                    'logTermination (an iOS-only method), so the Future never '
                    'completes.'
                : null,
        () async {
          await replied(Radar.logTermination());
        },
      );

      test('setPushNotificationToken', () async {
        await replied(Radar.setPushNotificationToken('flutter-e2e-token'));
        await replied(Radar.setPushNotificationToken(null));
      });

      test(
        'setNotificationOptions',
        skip:
            Platform.isIOS
                ? 'Known bug: the iOS bridge never replies to '
                    'setNotificationOptions (an Android-only method), so the '
                    'Future never completes.'
                : null,
        () async {
          await replied(
            Radar.setNotificationOptions({
              'iconString': 'ic_launcher',
              'iconColor': '#000000',
            }),
          );
        },
      );

      test(
        'setForegroundServiceOptions',
        skip:
            Platform.isIOS
                ? 'Known bug: the iOS bridge never replies to '
                    'setForegroundServiceOptions (an Android-only method), so '
                    'the Future never completes.'
                : null,
        () async {
          await replied(
            Radar.setForegroundServiceOptions({
              'title': 'flutter_radar e2e',
              'text': 'Tracking for the e2e suite',
              'updatesOnly': true,
            }),
          );
        },
      );
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

      test('getTrip returns the active trip', () async {
        final externalId = '$runId-get';
        expectSuccess(
          await Radar.startTrip(tripOptions: {'externalId': externalId}),
        );
        final trip = await Radar.getTrip();
        expect(trip, isNotNull);
        expect(trip, isNot(contains('error')), reason: '$trip');
        expect(trip!['externalId'], externalId);
      });

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

    // Needs geofences tagged E2EConfig.geofenceTag near the test location; see
    // example/README.md. Each test that depends on geofence state uses a new
    // user, so entries and exits from earlier runs or tests don't interfere.
    group('geofences', () {
      final tag = E2EConfig.geofenceTag;
      var geofences = <Map>[];

      setUpAll(() async {
        final result = await Radar.searchGeofences(
          near: _nyc,
          radius: 10000,
          limit: 10,
          tags: [tag],
          metadata: {},
          includeGeometry: false,
        );
        expectSuccess(result);
        geofences =
            (result!['geofences'] as List).cast<Map>().toList()..sort(
              (a, b) => '${a['externalId']}'.compareTo('${b['externalId']}'),
            );
      });

      tearDown(() async {
        await Radar.cancelTrip();
        await Radar.setUserId(runId);
      });

      /// Marks the test skipped and returns true if there are fewer than
      /// [count] geofences.
      bool skipWithout(int count) {
        if (geofences.length >= count) return false;
        markTestSkipped(
          'Needs $count geofence${count == 1 ? '' : 's'} tagged "$tag" within '
          '10 km of the test location; found ${geofences.length}. See '
          'example/README.md.',
        );
        return true;
      }

      Map<String, dynamic> centerOf(Map geofence) {
        final coordinates =
            (geofence['geometryCenter'] as Map)['coordinates'] as List;
        return {
          'latitude': coordinates[1],
          'longitude': coordinates[0],
          'accuracy': 10.0,
        };
      }

      Future<void> useNewUser(String name) => Radar.setUserId('$runId-$name');

      test('searchGeofences filters by tag and metadata', () async {
        if (skipWithout(1)) return;
        expect(geofences.map((g) => g['tag']), everyElement(tag));

        // An unused tag or metadata value finds nothing, which shows the
        // filters reach the API.
        final otherTag = await Radar.searchGeofences(
          near: _nyc,
          radius: 10000,
          limit: 10,
          tags: ['$tag-unused'],
          metadata: {},
          includeGeometry: false,
        );
        expectSuccess(otherTag);
        expect(otherTag!['geofences'], isEmpty);

        final otherMetadata = await Radar.searchGeofences(
          near: _nyc,
          radius: 10000,
          limit: 10,
          tags: [tag],
          metadata: {'flutterE2E': 'unused'},
          includeGeometry: false,
        );
        expectSuccess(otherMetadata);
        expect(otherMetadata!['geofences'], isEmpty);
      });

      test('getContext includes the geofence', () async {
        if (skipWithout(1)) return;
        final result = await Radar.getContext(centerOf(geofences.first));
        expectSuccess(result);
        expect(
          idsOf((result!['context'] as Map)['geofences']),
          contains(geofences.first['_id']),
        );
      });

      test('entering and exiting generates events and onEvents', () async {
        if (skipWithout(1)) return;
        final geofence = geofences.first;
        await useNewUser('enter-exit');
        final delivered = DeliveredEvents();

        expectSuccess(await Radar.trackOnce(location: _brooklyn));

        final entered = await Radar.trackOnce(location: centerOf(geofence));
        expectSuccess(entered);
        expect(
          idsOf((entered!['user'] as Map)['geofences']),
          contains(geofence['_id']),
        );
        final entry = eventOf(entered, 'user.entered_geofence');
        expect((entry['geofence'] as Map)['_id'], geofence['_id']);
        final deliveredEntry = await delivered.waitFor(
          'user.entered_geofence',
          geofence['_id'],
        );
        expect(deliveredEntry['_id'], entry['_id']);

        expectSuccess(await Radar.trackOnce(location: _brooklyn));
        // On Android, startTrip, completeTrip and cancelTrip each start a
        // device-location trackOnce, which can resolve seconds later. If one
        // lands after the entry, its track (from the device location, also
        // outside) reports the exit before ours does, so look for the exit in
        // everything delivered to onEvents rather than in our track's result.
        await delivered.waitFor('user.exited_geofence', geofence['_id']);
      });

      test('acceptEvent and rejectEvent', () async {
        if (skipWithout(1)) return;
        final geofence = geofences.first;
        await useNewUser('verify');
        final delivered = DeliveredEvents();
        expectSuccess(await Radar.trackOnce(location: _brooklyn));
        expectSuccess(await Radar.trackOnce(location: centerOf(geofence)));
        expectSuccess(await Radar.trackOnce(location: _brooklyn));
        final entry = await delivered.waitFor(
          'user.entered_geofence',
          geofence['_id'],
        );
        final exit = await delivered.waitFor(
          'user.exited_geofence',
          geofence['_id'],
        );

        // The native SDKs send these without a callback, so this checks only
        // that the bridge passes them on and replies.
        await replied(Radar.acceptEvent(entry['_id'] as String));
        await replied(Radar.rejectEvent(exit['_id'] as String));
      });

      test('trip to a geofence destination', () async {
        if (skipWithout(1)) return;
        final geofence = geofences.first;
        await useNewUser('trip-destination');
        expectSuccess(await Radar.trackOnce(location: _brooklyn));

        final started = await Radar.startTrip(
          tripOptions: {
            'externalId': '$runId-destination',
            'destinationGeofenceTag': tag,
            'destinationGeofenceExternalId': geofence['externalId'],
            'mode': 'car',
          },
        );
        expectSuccess(started);
        final trip = started!['trip'] as Map;
        expect(trip['destinationGeofenceTag'], tag);
        expect(trip['destinationGeofenceExternalId'], geofence['externalId']);

        final arrived = await Radar.trackOnce(location: centerOf(geofence));
        expectSuccess(arrived);
        // ignore: avoid_print
        print('trip arrival events: ${eventTypes(arrived!)}');
        eventOf(arrived, 'user.arrived_at_trip_destination');
      });

      test(
        'multi-leg trip: reorder and update legs',
        skip: Platform.isAndroid ? _androidNestedTripOptions : null,
        () async {
          if (skipWithout(2)) return;
          await useNewUser('trip-legs');
          final started = await Radar.startTrip(
            tripOptions: {
              'externalId': '$runId-legs',
              'mode': 'car',
              'metadata': {'runId': runId},
              'legs': [
                for (final geofence in geofences.take(2))
                  {
                    'destination': {
                      'destinationGeofenceTag': tag,
                      'destinationGeofenceExternalId': geofence['externalId'],
                    },
                  },
              ],
            },
          );
          expectSuccess(started);
          final trip = started!['trip'] as Map;
          if (trip['legs'] == null) {
            // The API ignores legs unless the project allows them.
            return markTestSkipped(
              'The project has multi-destination trips turned off '
              '(enableMultipleDestinationTrips), so the trip has no legs.',
            );
          }
          expect(trip['metadata'], containsPair('runId', runId));
          final legIds = idsOf(trip['legs']);
          expect(legIds, hasLength(2));
          expect(legIds, everyElement(isA<String>()));

          final newOrder = legIds.reversed.cast<String>().toList();
          final reordered = await Radar.reorderTripLegs(legIds: newOrder);
          expectSuccess(reordered);
          expect(idsOf((reordered!['trip'] as Map)['legs']), newOrder);

          // Reordering starts the new first leg, so move it on from there.
          final updated = await Radar.updateTripLeg(
            legId: newOrder.first,
            status: 'approaching',
          );
          expectSuccess(updated);
          // The API's response has no separate leg, so the SDKs return none;
          // read the leg from the trip.
          expect(legStatus(updated!, newOrder.first), 'approaching');

          final current = await Radar.updateCurrentTripLeg(status: 'arrived');
          expectSuccess(current);
          expect(legStatus(current!, newOrder.first), 'arrived');
        },
      );
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
