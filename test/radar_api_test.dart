import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests that each [Radar] method sends the arguments the native bridges read
/// and parses what they send back into typed results.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_radar');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  Object? response;

  setUp(() {
    calls = [];
    response = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      final r = response;
      if (r is PlatformException) throw r;
      return r;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  MethodCall lastCall() => calls.single;

  const location = RadarLocation(
    latitude: 40.70390,
    longitude: -73.98670,
    accuracy: 65,
  );
  const locationMap = {
    'latitude': 40.70390,
    'longitude': -73.98670,
    'accuracy': 65.0,
  };
  const userMap = {
    '_id': 'u1',
    'location': {
      'type': 'Point',
      'coordinates': [-73.99, 40.73],
    },
    'userId': 'user-1',
    'description': 'Jordan',
    'stopped': true,
  };
  const eventMap = {
    '_id': 'e1',
    'type': 'user.entered_geofence',
    'createdAt': '2026-11-19T15:00:00.000Z',
    'live': true,
    'geofence': {
      '_id': 'g1',
      'description': 'Office',
      'tag': 'office',
      'type': 'Circle',
      'geometryCenter': {
        'type': 'Point',
        'coordinates': [-73.98670, 40.70390],
      },
      'geometryRadius': 100,
    },
  };
  const addressMap = {
    'latitude': 40.70390,
    'longitude': -73.98670,
    'formattedAddress': '20 Jay St, Brooklyn, NY 11201 US',
    'number': '20',
    'street': 'Jay St',
    'city': 'Brooklyn',
    'stateCode': 'NY',
    'postalCode': '11201',
    'countryCode': 'US',
  };

  group('requests', () {
    test('getTags converts the decoded list', () async {
      response = ['a', 'b'];
      expect(await Radar.getTags(), ['a', 'b']);

      response = null;
      expect(await Radar.getTags(), isNull);
    });

    test('getLocation', () async {
      response = {
        'status': 'SUCCESS',
        'location': locationMap,
        'stopped': true,
      };

      final result = await Radar.getLocation(
        desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.high,
      );

      expect(lastCall().method, 'getLocation');
      expect(lastCall().arguments, {'desiredAccuracy': 'high'});
      expect(result.location.latitude, 40.70390);
      expect(result.stopped, isTrue);
    });

    test('trackOnce', () async {
      response = {
        'status': 'SUCCESS',
        'location': locationMap,
        'events': [eventMap],
        'user': userMap,
      };

      final result = await Radar.trackOnce(
        location: location,
        desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.medium,
        beacons: true,
      );

      expect(lastCall().method, 'trackOnce');
      expect(lastCall().arguments, {
        'location': locationMap,
        'desiredAccuracy': 'medium',
        'beacons': true,
      });
      expect(result.location.accuracy, 65.0);
      expect(result.user?.userId, 'user-1');
      expect(result.events.single.type, RadarEventType.userEnteredGeofence);
      expect(result.events.single.geofence?.tag, 'office');
    });

    test('trackOnce allows no events or user, as after a replay', () async {
      response = {'status': 'SUCCESS', 'location': locationMap};

      final result = await Radar.trackOnce();

      expect(result.events, isEmpty);
      expect(result.user, isNull);
    });

    Matcher throwsStatus(RadarStatus status) => throwsA(
      isA<RadarException>().having((e) => e.status, 'status', status),
    );

    test('a native error status throws RadarException', () async {
      response = {'status': 'ERROR_PERMISSIONS'};
      await expectLater(
        Radar.trackOnce(),
        throwsStatus(RadarStatus.errorPermissions),
      );

      response = {'status': 'ERROR_NETWORK', 'location': locationMap};
      await expectLater(
        Radar.searchPlaces(radius: 100),
        throwsStatus(RadarStatus.errorNetwork),
      );
    });

    test('an unrecognized or missing status throws errorUnknown', () async {
      response = {'status': 'ERROR_SOMETHING_NEW'};
      await expectLater(
        Radar.ipGeocode(),
        throwsStatus(RadarStatus.errorUnknown),
      );

      response = null;
      await expectLater(
        Radar.ipGeocode(),
        throwsStatus(RadarStatus.errorUnknown),
      );
    });

    test('a success missing a required field throws errorServer', () async {
      response = {'status': 'SUCCESS'};
      await expectLater(
        Radar.getLocation(),
        throwsStatus(RadarStatus.errorServer),
      );
      await expectLater(
        Radar.getDistance(
          destination: location,
          modes: {RadarRouteMode.car},
          units: RadarRouteUnits.metric,
        ),
        throwsStatus(RadarStatus.errorServer),
      );
      await expectLater(
        Radar.trackVerified(),
        throwsStatus(RadarStatus.errorServer),
      );
    });

    test('null arguments are left out', () async {
      // Several bridge handlers only check whether an argument is present, so
      // a null argument would skip their defaults.
      response = {
        'status': 'SUCCESS',
        'location': locationMap,
        'context': <String, Object?>{},
      };
      await Radar.getContext();
      expect(lastCall().arguments, <String, Object?>{});

      response = {
        'status': 'SUCCESS',
        'location': locationMap,
        'places': <Object?>[],
      };
      await Radar.searchPlaces(radius: 500);
      expect(calls.last.arguments, {'radius': 500});
    });

    test('a PlatformException propagates', () async {
      response = PlatformException(code: 'boom');

      await expectLater(Radar.trackOnce(), throwsA(isA<PlatformException>()));
      await expectLater(
        Radar.setUserId('u'),
        throwsA(isA<PlatformException>()),
      );
      await expectLater(Radar.getTrip(), throwsA(isA<PlatformException>()));
    });

    test('startTracking sends a preset as its full options', () async {
      await Radar.startTracking(RadarTrackingOptions.continuousAndroid);

      expect(lastCall().method, 'startTracking');
      expect(
        lastCall().arguments,
        RadarTrackingOptions.continuousAndroid.toMap(),
      );
    });

    test('startTracking sends adjusted options', () async {
      final options = RadarTrackingOptions.efficientAndroid.copyWith(
        beacons: true,
      );

      await Radar.startTracking(options);

      expect(lastCall().method, 'startTracking');
      expect(lastCall().arguments, options.toMap());
      expect((lastCall().arguments as Map)['beacons'], isTrue);
    });

    test('getTrackingOptions parses the options', () async {
      response = RadarTrackingOptions.responsiveIOS.toMap();

      final options = await Radar.getTrackingOptions();

      expect(options, RadarTrackingOptions.responsiveIOS);
    });

    test('setLogLevel and getPermissionsStatus use enums', () async {
      await Radar.setLogLevel(RadarLogLevel.debug);
      expect(lastCall().arguments, {'logLevel': 'debug'});

      response = 'GRANTED_BACKGROUND';
      expect(
        await Radar.getPermissionsStatus(),
        RadarPermissionsStatus.grantedBackground,
      );
    });

    test('startTrip', () async {
      response = {
        'status': 'SUCCESS',
        'trip': {
          '_id': 't1',
          'externalId': 'order-1',
          'status': 'started',
          'mode': 'car',
        },
        'events': [
          {
            '_id': 'e2',
            'type': 'user.started_trip',
            'createdAt': '2026-11-19T15:00:00.000Z',
          },
        ],
      };
      const tripOptions = RadarTripOptions(
        externalId: 'order-1',
        destinationGeofenceTag: 'store',
        destinationGeofenceExternalId: '123',
        mode: RadarRouteMode.car,
      );

      final result = await Radar.startTrip(
        tripOptions: tripOptions,
        trackingOptions: RadarTrackingOptions.continuousAndroid,
      );

      expect(lastCall().method, 'startTrip');
      expect(lastCall().arguments, {
        'tripOptions': tripOptions.toMap(),
        'trackingOptions': RadarTrackingOptions.continuousAndroid.toMap(),
      });
      expect(result.trip.externalId, 'order-1');
      expect(result.trip.status, RadarTripStatus.started);
      expect(result.events.single.type, RadarEventType.userStartedTrip);
    });

    test('updateTrip sends the status wire value', () async {
      response = {
        'status': 'SUCCESS',
        'trip': {
          '_id': 't1',
          'externalId': 'order-1',
          'status': 'started',
          'legs': [
            {'_id': 'leg-1', 'status': 'arrived'},
          ],
        },
      };

      await Radar.updateTrip(
        options: const RadarTripOptions(externalId: 'order-1'),
        status: RadarTripStatus.arrived,
      );

      expect((lastCall().arguments as Map)['status'], 'arrived');
    });

    test('updateTripLeg', () async {
      // The server returns the trip, not the leg.
      response = {
        'status': 'SUCCESS',
        'trip': {
          '_id': 't1',
          'externalId': 'order-1',
          'status': 'started',
          'legs': [
            {'_id': 'leg-1', 'status': 'arrived'},
          ],
        },
      };

      final result = await Radar.updateTripLeg(
        legId: 'leg-1',
        status: RadarTripLegStatus.arrived,
      );

      expect(lastCall().arguments, {
        'legId': 'leg-1',
        'status': RadarTripLegStatus.arrived.wireValue,
      });
      final leg = result.trip.legs.firstWhere((leg) => leg.id == 'leg-1');
      expect(leg.status, RadarTripLegStatus.arrived);
    });

    test('getTrip returns null when there is no trip', () async {
      expect(await Radar.getTrip(), isNull);
    });

    test('getContext', () async {
      response = {
        'status': 'SUCCESS',
        'location': locationMap,
        'context': {
          'geofences': [eventMap['geofence']],
          'country': {
            '_id': 'c1',
            'code': 'US',
            'name': 'United States',
            'type': 'country',
          },
        },
      };

      final result = await Radar.getContext(location);

      expect(lastCall().arguments, {'location': locationMap});
      expect(result.context.geofences.single.description, 'Office');
      expect(result.context.country?.code, 'US');
    });

    test('searchGeofences', () async {
      response = {
        'status': 'SUCCESS',
        'location': locationMap,
        'geofences': [eventMap['geofence']],
      };

      final result = await Radar.searchGeofences(
        near: location,
        radius: 1000,
        tags: ['office'],
        limit: 10,
      );

      expect(lastCall().arguments, {
        'near': locationMap,
        'radius': 1000,
        'limit': 10,
        'tags': ['office'],
      });
      final geometry = result.geofences.single.geometry;
      expect(geometry, isA<RadarCircleGeometry>());
      expect(geometry?.radius, 100);
      expect(geometry?.center.latitude, 40.70390);
    });

    test('searchPlaces', () async {
      response = {
        'status': 'SUCCESS',
        'location': locationMap,
        'places': [
          {
            '_id': 'p1',
            'name': 'Starbucks',
            'categories': ['coffee-shop'],
            'chain': {'slug': 'starbucks', 'name': 'Starbucks'},
            'location': {
              'type': 'Point',
              'coordinates': [-73.98, 40.70],
            },
          },
        ],
      };

      final result = await Radar.searchPlaces(
        near: location,
        radius: 1000,
        chains: ['starbucks'],
      );

      expect((lastCall().arguments as Map)['chains'], ['starbucks']);
      expect(result.places.single.chain?.slug, 'starbucks');
      expect(result.places.single.location.latitude, 40.70);
    });

    test('autocomplete, geocode, and reverseGeocode', () async {
      response = {
        'status': 'SUCCESS',
        'addresses': [addressMap],
      };

      final autocomplete = await Radar.autocomplete(
        query: '20 jay',
        near: location,
        layers: ['address'],
        mailable: true,
      );
      expect(calls.last.method, 'autocomplete');
      expect((calls.last.arguments as Map)['query'], '20 jay');
      expect(autocomplete.single.street, 'Jay St');

      final geocode = await Radar.geocode('20 jay st brooklyn');
      expect(calls.last.method, 'forwardGeocode');
      expect(geocode.single.postalCode, '11201');

      final reverse = await Radar.reverseGeocode(location: location);
      expect(calls.last.method, 'reverseGeocode');
      expect(calls.last.arguments, {'location': locationMap});
      expect(reverse.single.coordinate?.longitude, -73.98670);
    });

    test('ipGeocode', () async {
      response = {'status': 'SUCCESS', 'address': addressMap, 'proxy': true};

      final result = await Radar.ipGeocode();

      expect(result.address.city, 'Brooklyn');
      expect(result.proxy, isTrue);
    });

    test('getDistance', () async {
      response = {
        'status': 'SUCCESS',
        'routes': {
          'car': {
            'distance': {'value': 1000.0, 'text': '0.6 mi'},
            'duration': {'value': 5.0, 'text': '5 mins'},
          },
        },
      };

      final routes = await Radar.getDistance(
        destination: location,
        modes: {RadarRouteMode.car, RadarRouteMode.foot},
        units: RadarRouteUnits.imperial,
      );

      expect(lastCall().arguments, {
        'destination': locationMap,
        'modes': ['car', 'foot'],
        'units': 'imperial',
      });
      expect(routes.car?.distance?.text, '0.6 mi');
      expect(routes.foot, isNull);
    });

    test('getMatrix', () async {
      response = {
        'status': 'SUCCESS',
        'matrix': [
          [
            {
              'distance': {'value': 1000.0, 'text': '0.6 mi'},
              'duration': {'value': 5.0, 'text': '5 mins'},
            },
          ],
        ],
      };

      final matrix = await Radar.getMatrix(
        origins: [location],
        destinations: [location],
        mode: RadarRouteMode.truck,
        units: RadarRouteUnits.metric,
      );

      expect(lastCall().arguments, {
        'origins': [locationMap],
        'destinations': [locationMap],
        'mode': 'truck',
        'units': 'metric',
      });
      expect(
        matrix.routeBetween(0, 0)?.duration?.value,
        const Duration(minutes: 5),
      );
      expect(matrix.routeBetween(1, 0), isNull);
    });

    test('mockTracking returns without waiting for native', () async {
      // Neither bridge replies to mockTracking.
      messenger.setMockMethodCallHandler(channel, (call) {
        calls.add(call);
        return Completer<Object?>().future;
      });

      await Radar.mockTracking(
        origin: location,
        destination: location,
        mode: RadarRouteMode.foot,
        steps: 3,
        interval: const Duration(seconds: 1),
      );

      expect(lastCall().arguments, {
        'origin': locationMap,
        'destination': locationMap,
        'mode': 'foot',
        'steps': 3,
        'interval': 1,
      });
    });

    test('logConversion', () async {
      response = {
        'status': 'SUCCESS',
        'event': {
          '_id': 'e3',
          'type': 'purchase',
          'createdAt': '2026-11-19T15:00:00.000Z',
          'conversionName': 'purchase',
        },
      };

      final event = await Radar.logConversion(
        name: 'purchase',
        revenue: 1.5,
        metadata: {'sku': 'abc'},
      );

      expect(lastCall().arguments, {
        'name': 'purchase',
        'revenue': 1.5,
        'metadata': {'sku': 'abc'},
      });
      expect(event.id, 'e3');
    });

    test('trackVerified', () async {
      response = {
        'status': 'SUCCESS',
        'token': {
          'token': 'abc.def',
          'passed': true,
          'expiresIn': 3600,
          'user': userMap,
        },
      };

      final token = await Radar.trackVerified(
        desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.high,
        reason: 'login',
      );

      expect(lastCall().arguments, {
        'beacons': false,
        'desiredAccuracy': 'high',
        'reason': 'login',
      });
      expect(token.token, 'abc.def');
      expect(token.passed, isTrue);
      expect(token.user?.userId, 'user-1');
    });

    test(
      'validateStreetAddress sends the street fields, without a null unit',
      () async {
        response = {
          'status': 'SUCCESS',
          'address': addressMap,
          'verificationStatus': 'VERIFIED',
        };

        final result = await Radar.validateStreetAddress(
          street: 'Jay St',
          number: '20',
          city: 'Brooklyn',
          stateCode: 'NY',
          postalCode: '11201',
          countryCode: 'US',
        );

        expect(lastCall().method, 'validateStreetAddress');
        expect(lastCall().arguments, {
          'street': 'Jay St',
          'number': '20',
          'city': 'Brooklyn',
          'stateCode': 'NY',
          'postalCode': '11201',
          'countryCode': 'US',
        });
        expect(result.address.number, '20');
        expect(
          result.verificationStatus,
          RadarAddressVerificationStatus.verified,
        );
      },
    );

    test('validateAddressLabel sends the label fields', () async {
      response = {
        'status': 'SUCCESS',
        'address': addressMap,
        'verificationStatus': 'verified',
      };

      final result = await Radar.validateAddressLabel(
        addressLabel: '20 Jay St',
        unit: '5',
        city: 'Brooklyn',
        stateCode: 'NY',
        postalCode: '11201',
        countryCode: 'US',
      );

      expect(lastCall().method, 'validateAddressLabel');
      expect(lastCall().arguments, {
        'addressLabel': '20 Jay St',
        'unit': '5',
        'city': 'Brooklyn',
        'stateCode': 'NY',
        'postalCode': '11201',
        'countryCode': 'US',
      });
      expect(
        result.verificationStatus,
        RadarAddressVerificationStatus.verified,
      );
    });

    test('validateStreetAddress throws when validation fails', () async {
      response = {'status': 'ERROR_BAD_REQUEST'};

      await expectLater(
        Radar.validateStreetAddress(
          street: '',
          number: '841',
          city: 'New York',
          stateCode: 'NY',
          postalCode: '10003',
          countryCode: 'US',
        ),
        throwsA(
          isA<RadarException>().having(
            (e) => e.status,
            'status',
            RadarStatus.errorBadRequest,
          ),
        ),
      );
    });

    test('setExpectedAddress sends the address', () async {
      await Radar.setExpectedAddress('841 Broadway, New York, NY 10003');

      expect(lastCall().method, 'setExpectedAddress');
      expect(lastCall().arguments, {
        'address': '841 Broadway, New York, NY 10003',
      });
    });

    test('setExpectedAddress(null) omits the address to clear it', () async {
      await Radar.setExpectedAddress(null);

      expect(lastCall().method, 'setExpectedAddress');
      expect(lastCall().arguments, isEmpty);
    });

    test('beacon ranging takes no arguments', () async {
      await Radar.startRangingBeacons();
      await Radar.stopRangingBeacons();

      expect(calls.map((c) => c.method), [
        'startRangingBeacons',
        'stopRangingBeacons',
      ]);
      expect(calls.map((c) => c.arguments), [isNull, isNull]);
    });

    group('platform-only methods', () {
      tearDown(() => debugDefaultTargetPlatformOverride = null);

      test('Android-only methods call native on Android', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        await Radar.setNotificationOptions(
          const RadarNotificationOptions(
            iconString: 'icon',
            iconColor: Color(0xFFFF0000),
          ),
        );
        expect(calls.last.method, 'setNotificationOptions');
        expect(calls.last.arguments, {
          'iconString': 'icon',
          'iconColor': '#FF0000',
        });

        await Radar.setForegroundServiceOptions(
          const RadarForegroundServiceOptions(text: 'Tracking', title: 'Radar'),
        );
        expect(calls.last.method, 'setForegroundServiceOptions');
        expect((calls.last.arguments as Map)['text'], 'Tracking');
        expect((calls.last.arguments as Map)['title'], 'Radar');
      });

      test('Android-only methods do nothing on iOS', () async {
        // The iOS bridge never replies to these, so calling native would
        // leave the returned future pending forever.
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        await Radar.setNotificationOptions(const RadarNotificationOptions());
        await Radar.setForegroundServiceOptions(
          const RadarForegroundServiceOptions(),
        );

        expect(calls, isEmpty);
      });

      test('logTermination calls native only on iOS', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        await Radar.logTermination();
        expect(calls, isEmpty);

        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        await Radar.logTermination();
        expect(lastCall().method, 'logTermination');
      });
    });
  });

  group('listeners', () {
    setUp(() async {
      await Radar.initialize('prj_test_pk');
    });

    tearDown(() {
      Radar.offLocation();
      Radar.offClientLocation();
      Radar.offEvents();
      Radar.offError();
      Radar.offLog();
      Radar.offToken();
      Radar.offIpChanged();
      Radar.offSharingChanged();
    });

    Future<void> send(String method, Map<String, Object?> payload) async {
      await messenger.handlePlatformMessage(
        'flutter_radar',
        const StandardMethodCodec().encodeMethodCall(
          MethodCall(method, [0, payload]),
        ),
        null,
      );
    }

    test('onEvents receives typed events and user', () async {
      RadarEventsUpdate? received;
      Radar.onEvents((update) => received = update);

      await send('events', {
        'events': [eventMap],
        'user': userMap,
      });

      expect(received?.events.single.type, RadarEventType.userEnteredGeofence);
      expect(received?.user?.id, 'u1');
    });

    test(
      'onEvents tolerates iOS sending an empty string for no user',
      () async {
        RadarEventsUpdate? received;
        Radar.onEvents((update) => received = update);

        await send('events', {
          'events': [eventMap],
          'user': '',
        });

        expect(received?.events, hasLength(1));
        expect(received?.user, isNull);
      },
    );

    test('onLocation, onClientLocation, onError, onLog', () async {
      RadarLocationUpdate? location;
      RadarClientLocationUpdate? clientLocation;
      RadarErrorUpdate? error;
      RadarLogUpdate? log;
      Radar.onLocation((u) => location = u);
      Radar.onClientLocation((u) => clientLocation = u);
      Radar.onError((u) => error = u);
      Radar.onLog((u) => log = u);

      await send('location', {'location': locationMap, 'user': userMap});
      await send('clientLocation', {
        'location': locationMap,
        'stopped': false,
        'source': 'FOREGROUND_LOCATION',
      });
      await send('error', {'status': 'ERROR_NETWORK'});
      await send('log', {'message': 'hello'});

      expect(location?.location.accuracy, 65.0);
      expect(location?.user.stopped, isTrue);
      expect(clientLocation?.source, RadarLocationSource.foregroundLocation);
      expect(error?.status, RadarStatus.errorNetwork);
      expect(log?.message, 'hello');
    });

    test('onToken, onIpChanged, onSharingChanged', () async {
      RadarTokenUpdate? token;
      var ipChanged = false;
      bool? sharing;
      Radar.onToken((u) => token = u);
      Radar.onIpChanged((_) => ipChanged = true);
      Radar.onSharingChanged((u) => sharing = u.sharing);

      await send('token', {
        'token': {'token': 'abc', 'passed': false},
      });
      await send('ipChanged', {});
      await send('sharingChanged', {'sharing': true});

      expect(token?.token.token, 'abc');
      expect(token?.token.passed, isFalse);
      expect(ipChanged, isTrue);
      expect(sharing, isTrue);
    });

    test('registering a second listener throws', () {
      Radar.onLog((_) {});
      expect(
        () => Radar.onLog((_) {}),
        throwsA(isA<RadarExistingCallbackException>()),
      );
    });
  });
}
