// End-to-end tests: the real plugin, native SDKs and Radar API, on a simulator
// or emulator. Run with scripts/e2e.sh; see example/README.md.
//
// Assertions check meaning and shape (the user we set, coordinates we sent),
// not exact server content, so any fairly standard project passes. Requests
// throw RadarException on a failure status, so a call that returns succeeded.

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show Color;

import 'package:flutter_radar/flutter_radar.dart';
import 'package:flutter_radar_example/environment.dart' show setRadarHosts;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/e2e_config.dart';

// The point scripts/e2e.sh sets as the simulated device location.
const _nyc = RadarLocation(
  latitude: 40.7342,
  longitude: -73.9911,
  accuracy: 10,
);
// Kilometers from the test location and the geofences, so tracking here puts
// the user outside them.
const _brooklyn = RadarLocation(
  latitude: 40.7039,
  longitude: -73.9867,
  accuracy: 10,
);
const _jfk = RadarLocation(latitude: 40.64189, longitude: -73.78779);

const _callbackTimeout = Duration(seconds: 15);

Future<bool> hasLocationPermission() async {
  final status = await Radar.getPermissionsStatus();
  return status == RadarPermissionsStatus.grantedForeground ||
      status == RadarPermissionsStatus.grantedBackground;
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

/// The event of [type] in [result], failing the test if there isn't one.
RadarEvent eventOf(RadarTrackResult result, RadarEventType type) {
  expect(result.events.map((e) => e.type), contains(type));
  return result.events.firstWhere((event) => event.type == type);
}

/// Collects every event delivered to [Radar.onEvents], from any track.
class DeliveredEvents {
  DeliveredEvents() {
    Radar.onEvents((update) => _events.addAll(update.events));
    addTearDown(Radar.offEvents);
  }

  final _events = <RadarEvent>[];

  /// Waits for an event of [type] for the geofence with [geofenceId].
  Future<RadarEvent> waitFor(RadarEventType type, String geofenceId) async {
    final deadline = DateTime.now().add(_callbackTimeout);
    while (true) {
      for (final event in _events) {
        if (event.type == type && event.geofence?.id == geofenceId) {
          return event;
        }
      }
      if (DateTime.now().isAfter(deadline)) {
        fail(
          'No ${type.name} event for geofence $geofenceId was delivered '
          'to onEvents. Delivered: ${_events.map((e) => e.type).toList()}',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }
}

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
      await Radar.setLogLevel(RadarLogLevel.debug);
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

      test('tags round-trip', () async {
        await Radar.setTags(['e2e', 'flutter']);
        expect(await Radar.getTags(), unorderedEquals(['e2e', 'flutter']));
        await Radar.addTags(['extra']);
        expect(await Radar.getTags(), contains('extra'));
        await Radar.removeTags(['extra']);
        expect(await Radar.getTags(), isNot(contains('extra')));
      });

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

        // The SDKs return the location they were given, unchanged.
        expect(result.location.latitude, _nyc.latitude);
        expect(result.location.longitude, _nyc.longitude);
        expect(result.user?.userId, runId);
        expect(result.user?.description, description);
      });

      test(
        'returns the user metadata we set',
        skip:
            Platform.isIOS
                ? 'Known native iOS SDK bug (FENCE-3218): RadarAPIClient replaces '
                    'user.metadata in the track response with its '
                    'locationMetadata, so custom metadata never reaches the app.'
                : null,
        () async {
          final result = await Radar.trackOnce(location: _nyc);
          expect(result.user?.metadata, containsPair('runId', runId));
        },
      );

      test('delivers onLocation to Dart', () async {
        final received = Completer<RadarLocationUpdate>();
        Radar.onLocation((update) {
          if (!received.isCompleted) received.complete(update);
        });
        addTearDown(Radar.offLocation);

        await Radar.trackOnce(location: _nyc);

        final update = await received.future.timeout(_callbackTimeout);
        expect(update.user.userId, runId);
        expect(update.location, isNotNull);
      });

      test('delivers onLog to Dart at debug level', () async {
        final received = Completer<RadarLogUpdate>();
        Radar.onLog((update) {
          if (!received.isCompleted) received.complete(update);
        });
        addTearDown(Radar.offLog);

        await Radar.trackOnce(location: _nyc);

        final update = await received.future.timeout(_callbackTimeout);
        expect(update.message, isNotEmpty);
      });
    });

    group('device location', () {
      test('getLocation', () async {
        if (!await hasLocationPermission()) {
          return markTestSkipped(_noPermission);
        }
        final result = await Radar.getLocation(
          desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.high,
        );
        expect(result.location.latitude, closeTo(_nyc.latitude, 0.1));
        expect(result.location.longitude, closeTo(_nyc.longitude, 0.1));
      });

      test('trackOnce without a location delivers onClientLocation', () async {
        if (!await hasLocationPermission()) {
          return markTestSkipped(_noPermission);
        }
        final received = Completer<RadarClientLocationUpdate>();
        Radar.onClientLocation((update) {
          if (!received.isCompleted) received.complete(update);
        });
        addTearDown(Radar.offClientLocation);

        final result = await Radar.trackOnce();
        expect(result.user?.userId, runId);

        final update = await received.future.timeout(_callbackTimeout);
        expect(update.location, isNotNull);
      });

      test('reverseGeocode without a location', () async {
        if (!await hasLocationPermission()) {
          return markTestSkipped(_noPermission);
        }
        expect(await Radar.reverseGeocode(), isNotEmpty);
      });

      test('startTracking, isTracking, stopTracking', () async {
        if (!await hasLocationPermission()) {
          return markTestSkipped(_noPermission);
        }
        await Radar.startTracking(RadarTrackingOptions.responsive);
        expect(await Radar.isTracking(), isTrue);
        expect(await Radar.getTrackingOptions(), isNotNull);
        await Radar.stopTracking();
        expect(await Radar.isTracking(), isFalse);
      });

      test('startTracking with adjusted options', () async {
        if (!await hasLocationPermission()) {
          return markTestSkipped(_noPermission);
        }
        // Change one field from a preset to check that the options reach
        // native.
        const interval = Duration(seconds: 170);
        await replied(
          Radar.startTracking(
            RadarTrackingOptions.responsive.copyWith(
              desiredStoppedUpdateInterval: interval,
            ),
          ),
        );
        expect(await Radar.isTracking(), isTrue);
        expect(await Radar.isUsingRemoteTrackingOptions(), isA<bool>());
        expect(
          (await Radar.getTrackingOptions())?.desiredStoppedUpdateInterval,
          interval,
        );
        await Radar.stopTracking();
        expect(await Radar.isTracking(), isFalse);
      });
    });

    group('trackVerified', skip: E2EConfig.verifiedSkipReason, () {
      test('returns a token for the user and delivers onToken', () async {
        if (!await hasLocationPermission()) {
          return markTestSkipped(_noPermission);
        }
        final received = Completer<RadarTokenUpdate>();
        Radar.onToken((update) {
          if (!received.isCompleted) received.complete(update);
        });
        addTearDown(Radar.offToken);

        final token = await Radar.trackVerified(
          reason: 'e2e',
          transactionId: runId,
        );

        expect(token.token, isNotEmpty);
        // Simulators and emulators fail attestation, so passed is usually
        // false here; the typed field being parsed is what's checked.
        expect(token.expiresAt, isNotNull);
        expect(token.user?.userId, runId);

        final update = await received.future.timeout(_callbackTimeout);
        expect(update.token.token, isNotEmpty);
      });

      test('getVerifiedLocationToken returns a token', () async {
        if (!await hasLocationPermission()) {
          return markTestSkipped(_noPermission);
        }
        final token = await Radar.getVerifiedLocationToken();
        expect(token.token, isNotEmpty);
      });

      test('clearVerifiedLocationToken and isTrackingVerified', () async {
        await Radar.clearVerifiedLocationToken();
        expect(await Radar.isTrackingVerified(), isFalse);
      });
    });

    group('network APIs', () {
      test('geocode', () async {
        final addresses = await Radar.geocode('20 Jay St, Brooklyn, NY');
        expect(addresses, isNotEmpty);
        expect(addresses.first.coordinate, isNotNull);
      });

      test('reverseGeocode with a location', () async {
        expect(await Radar.reverseGeocode(location: _nyc), isNotEmpty);
      });

      test('ipGeocode', () async {
        final result = await Radar.ipGeocode();
        expect(result.address.countryCode, isNotNull);
      });

      test('autocomplete', () async {
        final addresses = await Radar.autocomplete(
          query: '20 Jay St',
          near: _nyc,
          limit: 5,
        );
        expect(addresses, isNotEmpty);
      });

      test('searchPlaces', () async {
        // Completing without a RadarException is the check; a project's
        // place data varies.
        await Radar.searchPlaces(
          near: _nyc,
          radius: 1000,
          chains: ['starbucks'],
          limit: 5,
        );
      });

      test('searchGeofences with every argument', () async {
        // The project may have no geofences nearby, so an empty list is fine.
        await Radar.searchGeofences(
          near: _nyc,
          radius: 1000,
          limit: 10,
          tags: [],
          metadata: {},
          includeGeometry: false,
        );
      });

      test(
        'searchGeofences with only near, radius and limit',
        skip:
            Platform.isAndroid
                ? 'Known bug: the Android bridge throws NullPointerException for '
                    'omitted tags (ArrayList.toArray) and includeGeometry '
                    '(Boolean unboxing).'
                : null,
        () async {
          await Radar.searchGeofences(near: _nyc, radius: 1000, limit: 10);
        },
      );

      test('getContext', () async {
        final result = await Radar.getContext(_nyc);
        // Both native SDKs pass the request location back unchanged.
        expect(result.location.latitude, _nyc.latitude);
        expect(result.location.longitude, _nyc.longitude);
      });

      test(
        'getDistance returns a route for each requested mode',
        skip:
            Platform.isAndroid
                ? 'Known bug: the Android bridge ignores modes (loops over an '
                    'empty array), so the API returns ERROR_BAD_REQUEST.'
                : null,
        () async {
          final routes = await Radar.getDistance(
            origin: _nyc,
            destination: _brooklyn,
            modes: {RadarRouteMode.car, RadarRouteMode.foot},
            units: RadarRouteUnits.imperial,
          );
          expect(routes.car, isNotNull);
          expect(routes.foot, isNotNull);
        },
      );

      test('getMatrix', () async {
        final matrix = await Radar.getMatrix(
          origins: [_nyc, _brooklyn],
          destinations: [_jfk],
          mode: RadarRouteMode.car,
          units: RadarRouteUnits.imperial,
        );
        expect(matrix.rows, hasLength(2));
      });

      test('logConversion', () async {
        final event = await Radar.logConversion(
          name: 'flutter_e2e',
          revenue: 1.5,
          metadata: {'runId': runId},
        );
        expect(event.id, isNotEmpty);
      });

      test('validateStreetAddress', () async {
        try {
          final result = await Radar.validateStreetAddress(
            street: 'BROADWAY',
            number: '841',
            city: 'NEW YORK',
            stateCode: 'NY',
            postalCode: '10003',
            countryCode: 'US',
          );
          expect(result.address.countryCode, 'US');
        } on RadarException catch (e) {
          if (e.status != RadarStatus.errorPaymentRequired) rethrow;
          markTestSkipped(_paymentRequired);
        }
      });

      test('validateAddressLabel', () async {
        try {
          final result = await Radar.validateAddressLabel(
            addressLabel: '841 BROADWAY',
            city: 'NEW YORK',
            stateCode: 'NY',
            postalCode: '10003',
            countryCode: 'US',
          );
          expect(result.address.countryCode, 'US');
        } on RadarException catch (e) {
          if (e.status != RadarStatus.errorPaymentRequired) rethrow;
          markTestSkipped(_paymentRequired);
        }
      });
    });

    // Methods that do little or nothing on one platform, or have no observable
    // result. Each test checks only that the call completes. On the other
    // platform, the platform-only methods return without calling native.
    group('platform-specific methods complete', () {
      test('logBackgrounding and logResigningActive', () async {
        await replied(Radar.logBackgrounding());
        await replied(Radar.logResigningActive());
      });

      test('logTermination', () async {
        await replied(Radar.logTermination());
      });

      test('setPushNotificationToken', () async {
        await replied(Radar.setPushNotificationToken('flutter-e2e-token'));
        await replied(Radar.setPushNotificationToken(null));
      });

      test('setNotificationOptions', () async {
        await replied(
          Radar.setNotificationOptions(
            const RadarNotificationOptions(
              iconString: 'ic_launcher',
              iconColor: Color(0xFF000000),
            ),
          ),
        );
      });

      test('setForegroundServiceOptions', () async {
        await replied(
          Radar.setForegroundServiceOptions(
            const RadarForegroundServiceOptions(
              title: 'flutter_radar e2e',
              text: 'Tracking for the e2e suite',
              updatesOnly: true,
            ),
          ),
        );
      });
    });

    group('trips', () {
      tearDown(() async {
        // Leave no active trip behind if an assertion failed midway. With no
        // active trip this throws, which is fine.
        try {
          await Radar.cancelTrip();
        } on RadarException {
          // No active trip.
        }
        await Radar.stopTracking();
      });

      test('start, update, complete', () async {
        final externalId = '$runId-complete';
        final started = await Radar.startTrip(
          tripOptions: RadarTripOptions(
            externalId: externalId,
            metadata: {'runId': runId},
          ),
        );
        expect(started.trip.externalId, externalId);
        expect((await Radar.getTripOptions())?.externalId, externalId);

        await Radar.updateTrip(
          options: RadarTripOptions(
            externalId: externalId,
            metadata: {'runId': runId, 'updated': true},
          ),
          status: RadarTripStatus.approaching,
        );

        final completed = await Radar.completeTrip();
        expect(completed.trip.status, RadarTripStatus.completed);
      });

      test('getTrip returns the active trip', () async {
        final externalId = '$runId-get';
        await Radar.startTrip(
          tripOptions: RadarTripOptions(externalId: externalId),
        );
        final trip = await Radar.getTrip();
        expect(trip?.externalId, externalId);
      });

      test('start, cancel', () async {
        final externalId = '$runId-cancel';
        await Radar.startTrip(
          tripOptions: RadarTripOptions(externalId: externalId),
        );
        final canceled = await Radar.cancelTrip();
        expect(canceled.trip.status, RadarTripStatus.canceled);
      });
    });

    // Needs geofences tagged E2EConfig.geofenceTag near the test location; see
    // example/README.md. Each test that depends on geofence state uses a new
    // user, so entries and exits from earlier runs or tests don't interfere.
    group('geofences', () {
      final tag = E2EConfig.geofenceTag;
      var geofences = <RadarGeofence>[];

      setUpAll(() async {
        final result = await Radar.searchGeofences(
          near: _nyc,
          radius: 10000,
          limit: 10,
          tags: [tag],
          metadata: {},
          includeGeometry: false,
        );
        geofences = [...result.geofences]
          ..sort((a, b) => '${a.externalId}'.compareTo('${b.externalId}'));
      });

      tearDown(() async {
        try {
          await Radar.cancelTrip();
        } on RadarException {
          // No active trip.
        }
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

      RadarLocation centerOf(RadarGeofence geofence) {
        final center = geofence.geometry!.center;
        return RadarLocation(
          latitude: center.latitude,
          longitude: center.longitude,
          accuracy: 10,
        );
      }

      Future<void> useNewUser(String name) => Radar.setUserId('$runId-$name');

      test('searchGeofences filters by tag and metadata', () async {
        if (skipWithout(1)) return;
        expect(geofences.map((g) => g.tag), everyElement(tag));

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
        expect(otherTag.geofences, isEmpty);

        final otherMetadata = await Radar.searchGeofences(
          near: _nyc,
          radius: 10000,
          limit: 10,
          tags: [tag],
          metadata: {'flutterE2E': 'unused'},
          includeGeometry: false,
        );
        expect(otherMetadata.geofences, isEmpty);
      });

      test('getContext includes the geofence', () async {
        if (skipWithout(1)) return;
        final result = await Radar.getContext(centerOf(geofences.first));
        expect(
          result.context.geofences.map((g) => g.id),
          contains(geofences.first.id),
        );
      });

      test('entering and exiting generates events and onEvents', () async {
        if (skipWithout(1)) return;
        final geofence = geofences.first;
        await useNewUser('enter-exit');
        final delivered = DeliveredEvents();

        await Radar.trackOnce(location: _brooklyn);

        final entered = await Radar.trackOnce(location: centerOf(geofence));
        expect(entered.user?.geofences.map((g) => g.id), contains(geofence.id));
        final entry = eventOf(entered, RadarEventType.userEnteredGeofence);
        expect(entry.geofence?.id, geofence.id);
        final deliveredEntry = await delivered.waitFor(
          RadarEventType.userEnteredGeofence,
          geofence.id,
        );
        expect(deliveredEntry.id, entry.id);

        await Radar.trackOnce(location: _brooklyn);
        // On Android, startTrip, completeTrip and cancelTrip each start a
        // device-location trackOnce, which can resolve seconds later. If one
        // lands after the entry, its track (from the device location, also
        // outside) reports the exit before ours does, so look for the exit in
        // everything delivered to onEvents rather than in our track's result.
        await delivered.waitFor(RadarEventType.userExitedGeofence, geofence.id);
      });

      test('acceptEvent and rejectEvent', () async {
        if (skipWithout(1)) return;
        final geofence = geofences.first;
        await useNewUser('verify');
        final delivered = DeliveredEvents();
        await Radar.trackOnce(location: _brooklyn);
        await Radar.trackOnce(location: centerOf(geofence));
        await Radar.trackOnce(location: _brooklyn);
        final entry = await delivered.waitFor(
          RadarEventType.userEnteredGeofence,
          geofence.id,
        );
        final exit = await delivered.waitFor(
          RadarEventType.userExitedGeofence,
          geofence.id,
        );

        // The native SDKs send these without a callback, so this checks only
        // that the bridge passes them on and replies.
        await replied(Radar.acceptEvent(entry.id));
        await replied(Radar.rejectEvent(exit.id));
      });

      test('trip to a geofence destination', () async {
        if (skipWithout(1)) return;
        final geofence = geofences.first;
        await useNewUser('trip-destination');
        await Radar.trackOnce(location: _brooklyn);

        final started = await Radar.startTrip(
          tripOptions: RadarTripOptions(
            externalId: '$runId-destination',
            destinationGeofenceTag: tag,
            destinationGeofenceExternalId: geofence.externalId,
            mode: RadarRouteMode.car,
          ),
        );
        expect(started.trip.destinationGeofenceTag, tag);
        expect(started.trip.destinationGeofenceExternalId, geofence.externalId);

        final arrived = await Radar.trackOnce(location: centerOf(geofence));
        eventOf(arrived, RadarEventType.userArrivedAtTripDestination);
      });

      test(
        'multi-leg trip: reorder and update legs',
        skip: Platform.isAndroid ? _androidNestedTripOptions : null,
        () async {
          if (skipWithout(2)) return;
          await useNewUser('trip-legs');
          final started = await Radar.startTrip(
            tripOptions: RadarTripOptions(
              externalId: '$runId-legs',
              mode: RadarRouteMode.car,
              metadata: {'runId': runId},
              legs: [
                for (final geofence in geofences.take(2))
                  RadarTripLeg.geofence(
                    tag: tag,
                    externalId: geofence.externalId!,
                  ),
              ],
            ),
          );
          if (started.trip.legs.isEmpty) {
            // The API ignores legs unless the project allows them.
            return markTestSkipped(
              'The project has multi-destination trips turned off '
              '(enableMultipleDestinationTrips), so the trip has no legs.',
            );
          }
          expect(started.trip.metadata, containsPair('runId', runId));
          final legIds = [for (final leg in started.trip.legs) leg.id!];
          expect(legIds, hasLength(2));

          final newOrder = legIds.reversed.toList();
          final reordered = await Radar.reorderTripLegs(legIds: newOrder);
          expect(reordered.trip.legs.map((leg) => leg.id), newOrder);

          RadarTripLegStatus? statusOf(RadarTrip trip, String legId) =>
              trip.legs.firstWhere((leg) => leg.id == legId).status;

          // Reordering starts the new first leg, so move it on from there.
          final updated = await Radar.updateTripLeg(
            legId: newOrder.first,
            status: RadarTripLegStatus.approaching,
          );
          expect(
            statusOf(updated.trip, newOrder.first),
            RadarTripLegStatus.approaching,
          );

          final current = await Radar.updateCurrentTripLeg(
            status: RadarTripLegStatus.arrived,
          );
          expect(
            statusOf(current.trip, newOrder.first),
            RadarTripLegStatus.arrived,
          );
        },
      );
    });

    group('mock tracking', () {
      test('mockTracking delivers mocked locations', () async {
        // Wait for a mocked location: a track the SDK started earlier, such
        // as the device-location track iOS sends on startTrip, can still
        // arrive first.
        final received = Completer<RadarLocationUpdate>();
        Radar.onLocation((update) {
          if (!received.isCompleted &&
              update.user.source == RadarLocationSource.mockLocation) {
            received.complete(update);
          }
        });
        addTearDown(Radar.offLocation);

        await Radar.mockTracking(
          origin: _nyc,
          destination: _brooklyn,
          mode: RadarRouteMode.car,
          steps: 2,
          interval: const Duration(seconds: 1),
        );

        final update = await received.future.timeout(_callbackTimeout);
        expect(update.user.userId, runId);
      });
    });
  });
}
