import 'package:flutter_radar/src/models/radar_enums.dart';
import 'package:flutter_radar/src/models/radar_event.dart';
import 'package:flutter_radar/src/models/radar_exception.dart';
import 'package:flutter_radar/src/models/radar_fraud.dart';
import 'package:flutter_radar/src/models/radar_location.dart';
import 'package:flutter_radar/src/models/radar_results.dart';
import 'package:flutter_radar/src/models/radar_reveal_risk_token.dart';
import 'package:flutter_radar/src/models/radar_routes.dart';
import 'package:flutter_radar/src/models/radar_status.dart';
import 'package:flutter_radar/src/models/radar_trip.dart';
import 'package:flutter_radar/src/models/radar_update.dart';
import 'package:flutter_radar/src/models/radar_user.dart';
import 'package:flutter_radar/src/models/radar_verified_location_token.dart';
import 'package:flutter_test/flutter_test.dart';

const _fraud = <Object?, Object?>{
  'passed': true,
  'bypassed': false,
  'verified': true,
  'proxy': false,
  'mocked': false,
  'compromised': false,
  'jumped': false,
  'inaccurate': false,
  'sharing': false,
  'blocked': false,
};

const _geofence = <Object?, Object?>{
  '_id': 'geofence-1',
  'description': 'Store',
  'tag': 'store',
  'externalId': '123',
  'type': 'circle',
  'geometryRadius': 100,
  'geometryCenter': {
    'type': 'Point',
    'coordinates': [-73.9911, 40.7342],
  },
};

const _region = <Object?, Object?>{
  '_id': 'region-1',
  'name': 'United States',
  'code': 'US',
  'type': 'country',
  'flag': '🇺🇸',
};

// The trip as Android's RadarTrip.toJson() serializes it: `eta` only when
// set, legs in the flat request format.
const _androidTrip = <Object?, Object?>{
  '_id': 'trip-1',
  'externalId': 'order-1',
  'metadata': {'customer': 'alice'},
  'destinationGeofenceTag': 'store',
  'destinationGeofenceExternalId': '123',
  'destinationLocation': {
    'type': 'Point',
    'coordinates': [-73.9911, 40.7342],
  },
  'mode': 'car',
  'eta': {'distance': 1200.5, 'duration': 4.5},
  'status': 'started',
  'orders': [
    {
      'id': 'order-a',
      'guid': 'guid-a',
      'handoffMode': 'curbside',
      'status': 'fired',
      'firedAt': '2026-11-19T12:00:00.000Z',
      'firedAttempts': 1,
      'firedReason': 'approaching',
      'updatedAt': '2026-11-19T12:00:01.000Z',
    },
  ],
  'legs': [
    {
      '_id': 'leg-1',
      'status': 'started',
      'createdAt': '2026-11-19T11:00:00.000Z',
      'destination': {
        'destinationGeofenceTag': 'store',
        'destinationGeofenceExternalId': '123',
      },
      'stopDuration': 5,
      'eta': {'duration': 4.5, 'distance': 1200.5},
    },
    {
      '_id': 'leg-2',
      'status': 'pending',
      'destination': {
        'coordinates': [-73.98, 40.75],
        'arrivalRadius': 50,
      },
      'metadata': {'dock': 4},
    },
  ],
  'currentLeg': 'leg-1',
};

// The trip as iOS's [RadarTrip dictionaryValue] serializes it: `eta` always
// present, mode always present.
const _iosTrip = <Object?, Object?>{
  '_id': 'trip-2',
  'externalId': 'order-2',
  'mode': 'foot',
  'eta': {'distance': 0, 'duration': 0},
  'status': 'arrived',
  'legs': [
    {
      '_id': 'leg-3',
      'status': 'arrived',
      'destination': {'address': '841 Broadway, New York, NY'},
    },
  ],
};

// A user as Android's RadarUser.toJson() serializes it.
const _androidUser = <Object?, Object?>{
  '_id': 'user-1',
  'userId': 'alice',
  'deviceId': 'device-1',
  'description': 'Alice',
  'metadata': {'plan': 'pro'},
  'location': {
    'type': 'Point',
    'coordinates': [-73.9911, 40.7342],
  },
  'geofences': [_geofence],
  'beacons': <Object?>[],
  'stopped': true,
  'foreground': false,
  'country': _region,
  'nearbyPlaceChains': [
    {'slug': 'starbucks', 'name': 'Starbucks'},
  ],
  'segments': [
    {'description': 'Commuters', 'externalId': 'commuters'},
  ],
  'topChains': <Object?>[],
  'source': 'GEOFENCE_DWELL',
  'trip': _androidTrip,
  'debug': false,
  'fraud': _fraud,
  'activityType': 'car',
  'altitude': 12.5,
  'expectedAddress': {
    'expectedAddress': '841 Broadway',
    'formattedAddress': '841 Broadway, New York, NY 10003 US',
    'latitude': 40.7342,
    'longitude': -73.9911,
    'atAddress': true,
    'confidence': 'high',
    'distance': 3.2,
  },
};

// A user as iOS's [RadarUser dictionaryValue] serializes it.
const _iosUser = <Object?, Object?>{
  '_id': 'user-2',
  'deviceId': 'device-2',
  'location': {
    'type': 'Point',
    'coordinates': [-122.4194, 37.7749],
  },
  'activityType': 'stationary',
  'geofences': <Object?>[],
  'stopped': false,
  'foreground': true,
  'nearbyPlaceChains': <Object?>[],
  'segments': <Object?>[],
  'topChains': <Object?>[],
  'source': 'VISIT_ARRIVAL',
  'debug': true,
  'fraud': _fraud,
  'locationInsights': {
    'atHome': true,
    'atWork': false,
    'traveling': false,
    'commuting': false,
  },
};

void main() {
  group('RadarUser', () {
    test('parses an Android-shaped user', () {
      final user = RadarUser.fromMap(_androidUser);
      expect(user.id, 'user-1');
      expect(user.userId, 'alice');
      expect(user.deviceId, 'device-1');
      expect(user.description, 'Alice');
      expect(user.metadata, {'plan': 'pro'});
      expect(user.location!.latitude, 40.7342);
      expect(user.location!.longitude, -73.9911);
      expect(user.location!.accuracy, isNull);
      expect(user.geofences.single.id, 'geofence-1');
      expect(user.beacons, isEmpty);
      expect(user.stopped, isTrue);
      expect(user.foreground, isFalse);
      expect(user.country!.code, 'US');
      expect(user.state, isNull);
      expect(user.nearbyPlaceChains.single.slug, 'starbucks');
      expect(user.segments.single.externalId, 'commuters');
      expect(user.segments.single.description, 'Commuters');
      expect(user.source, RadarLocationSource.geofenceDwell);
      expect(user.trip!.id, 'trip-1');
      expect(user.fraud!.passed, isTrue);
      expect(user.fraud!.verified, isTrue);
      expect(user.activityType, RadarActivityType.car);
      expect(user.altitude, 12.5);
      expect(user.expectedAddress!.atAddress, isTrue);
      expect(
        user.expectedAddress!.confidence,
        RadarExpectedAddressConfidence.high,
      );
      expect(user.expectedAddress!.distance, 3.2);
      expect(user.locationInsights, isNull);
    });

    test('parses an iOS-shaped user', () {
      final user = RadarUser.fromMap(_iosUser);
      expect(user.id, 'user-2');
      expect(user.userId, isNull);
      expect(user.location!.latitude, 37.7749);
      expect(user.activityType, RadarActivityType.stationary);
      expect(user.source, RadarLocationSource.visitArrival);
      expect(user.debug, isTrue);
      expect(user.foreground, isTrue);
      expect(user.trip, isNull);
      expect(user.altitude, isNull);
      expect(user.locationInsights!.atHome, isTrue);
    });

    test('reads locationAccuracy and barometricAltitude from API users', () {
      final user = RadarUser.fromMap({
        ..._iosUser,
        'locationAccuracy': 15,
        'barometricAltitude': 3.5,
        'altitude': 9.0,
      });
      expect(user.location!.accuracy, 15);
      expect(user.altitude, 3.5);
    });
  });

  group('RadarLocationSource', () {
    test('parses every platform string', () {
      const strings = {
        'FOREGROUND_LOCATION': RadarLocationSource.foregroundLocation,
        'BACKGROUND_LOCATION': RadarLocationSource.backgroundLocation,
        'MANUAL_LOCATION': RadarLocationSource.manualLocation,
        'VISIT_ARRIVAL': RadarLocationSource.visitArrival,
        'VISIT_DEPARTURE': RadarLocationSource.visitDeparture,
        'GEOFENCE_ENTER': RadarLocationSource.geofenceEnter,
        'GEOFENCE_DWELL': RadarLocationSource.geofenceDwell,
        'GEOFENCE_EXIT': RadarLocationSource.geofenceExit,
        'MOCK_LOCATION': RadarLocationSource.mockLocation,
        'BEACON_ENTER': RadarLocationSource.beaconEnter,
        'BEACON_EXIT': RadarLocationSource.beaconExit,
        'INDOORS': RadarLocationSource.indoors,
        'UNKNOWN': RadarLocationSource.unknown,
      };
      strings.forEach((wire, source) {
        expect(RadarLocationSource.fromWire(wire), source);
        expect(source.wireValue, wire);
      });
    });

    test('falls back to unknown', () {
      expect(
        RadarLocationSource.fromWire('NEW_SOURCE'),
        RadarLocationSource.unknown,
      );
      expect(RadarLocationSource.fromWire(null), RadarLocationSource.unknown);
      expect(RadarLocationSource.fromWire(3), RadarLocationSource.unknown);
    });

    test('is parsed from a clientLocation update', () {
      final update = RadarUpdate.fromMethodCall('clientLocation', {
        'location': {'latitude': 40.7, 'longitude': -73.9, 'accuracy': 5.0},
        'stopped': true,
        'source': 'BACKGROUND_LOCATION',
      });
      expect(update, isA<RadarClientLocationUpdate>());
      final clientLocation = update! as RadarClientLocationUpdate;
      expect(clientLocation.source, RadarLocationSource.backgroundLocation);
      expect(clientLocation.stopped, isTrue);
    });
  });

  group('RadarActivityType', () {
    test('falls back to unknown', () {
      expect(RadarActivityType.fromWire('run'), RadarActivityType.run);
      expect(RadarActivityType.fromWire('skate'), RadarActivityType.unknown);
      expect(RadarActivityType.fromWire(null), RadarActivityType.unknown);
    });
  });

  group('RadarEvent', () {
    test('parses an Android-shaped geofence entry', () {
      final event = RadarEvent.fromMap({
        '_id': 'event-1',
        'createdAt': '2026-11-19T12:00:00.000Z',
        'actualCreatedAt': '2026-11-19T12:00:01.000Z',
        'live': false,
        'type': 'user.entered_geofence',
        'geofence': _geofence,
        'confidence': 3,
        'duration': 0.0,
        'fraud': _fraud,
        'alternatePlaces': <Object?>[],
        'location': {
          'type': 'Point',
          'coordinates': [-73.9911, 40.7342],
        },
        'replayed': false,
        'metadata': {'source': 'test'},
      });
      expect(event.id, 'event-1');
      expect(event.type, RadarEventType.userEnteredGeofence);
      expect(event.createdAt, DateTime.utc(2026, 11, 19, 12));
      expect(event.actualCreatedAt, DateTime.utc(2026, 11, 19, 12, 0, 1));
      expect(event.live, isFalse);
      expect(event.geofence!.tag, 'store');
      expect(event.confidence, RadarEventConfidence.high);
      expect(event.duration, 0);
      expect(event.fraud!.passed, isTrue);
      expect(event.location!.latitude, 40.7342);
      expect(event.location!.longitude, -73.9911);
      expect(event.verification, isNull);
      expect(event.conversionName, isNull);
      expect(event.metadata, {'source': 'test'});
    });

    test('parses an iOS-shaped region exit with a trip event', () {
      final region = RadarEvent.fromMap({
        '_id': 'event-2',
        'live': true,
        'type': 'user.exited_region_country',
        'region': _region,
        'confidence': 2,
        'duration': 12.5,
        'location': {
          'type': 'Point',
          'coordinates': [-73.9911, 40.7342],
        },
        'replayed': true,
        'createdAt': '2026-11-19T12:00:00.000Z',
      });
      expect(region.type, RadarEventType.userExitedRegionCountry);
      expect(region.region!.code, 'US');
      expect(region.confidence, RadarEventConfidence.medium);
      expect(region.duration, 12.5);
      expect(region.live, isTrue);
      expect(region.replayed, isTrue);
      expect(region.actualCreatedAt, isNull);

      final trip = RadarEvent.fromMap({
        '_id': 'event-3',
        'type': 'user.arrived_at_trip_destination',
        'trip': _iosTrip,
        'confidence': 0,
      });
      expect(trip.type, RadarEventType.userArrivedAtTripDestination);
      expect(trip.trip!.status, RadarTripStatus.arrived);
      expect(trip.confidence, RadarEventConfidence.none);
      expect(trip.location, isNull);
    });

    test('parses conversion events from each platform', () {
      // Android omits `type` for conversions.
      final android = RadarEvent.fromMap({
        '_id': 'event-4',
        'live': false,
        'confidence': 0,
        'metadata': {'revenue': 10},
      });
      expect(android.type, RadarEventType.conversion);
      expect(android.conversionName, isNull);
      expect(android.location, isNull);

      // iOS sends `custom`.
      final ios = RadarEvent.fromMap({'_id': 'event-5', 'type': 'custom'});
      expect(ios.type, RadarEventType.conversion);
      expect(ios.conversionName, isNull);

      // The API sends the conversion name.
      final api = RadarEvent.fromMap({'_id': 'event-6', 'type': 'purchase'});
      expect(api.type, RadarEventType.conversion);
      expect(api.conversionName, 'purchase');
    });

    test('parses API fields: verification, accuracy, verified place', () {
      final event = RadarEvent.fromMap({
        '_id': 'event-7',
        'type': 'user.entered_place',
        'place': {'_id': 'place-1', 'name': 'Starbucks'},
        'verifiedPlace': {'_id': 'place-2', 'name': 'Blue Bottle'},
        'alternatePlaces': [
          {'_id': 'place-2', 'name': 'Blue Bottle'},
        ],
        'verification': -1,
        'confidence': 1,
        'location': {
          'type': 'Point',
          'coordinates': [-73.9911, 40.7342],
        },
        'locationAccuracy': 25,
      });
      expect(event.place!.name, 'Starbucks');
      expect(event.verifiedPlace!.id, 'place-2');
      expect(event.alternatePlaces.single.id, 'place-2');
      expect(event.verification, RadarEventVerification.reject);
      expect(event.confidence, RadarEventConfidence.low);
      expect(event.location!.accuracy, 25);
    });

    test('event types match both platforms', () {
      for (final type in RadarEventType.values) {
        expect(RadarEventType.fromWire(type.wireValue), type);
      }
      expect(
        RadarEventType.fromWire('user.entered_home'),
        RadarEventType.userEnteredHome,
      );
      expect(
        RadarEventType.fromWire('user.teleported'),
        RadarEventType.unknown,
      );
      expect(RadarEventType.fromWire('unknown'), RadarEventType.unknown);
      expect(RadarEventType.fromWire(42), RadarEventType.unknown);
    });

    test('enum fallbacks', () {
      expect(RadarEventConfidence.fromWire(9), RadarEventConfidence.none);
      expect(RadarEventConfidence.fromWire('2'), RadarEventConfidence.medium);
      expect(RadarEventVerification.fromWire(1), RadarEventVerification.accept);
      expect(
        RadarEventVerification.fromWire(0),
        RadarEventVerification.unverify,
      );
      expect(RadarEventVerification.fromWire(5), isNull);
      expect(RadarEventVerification.fromWire(null), isNull);
    });
  });

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
        ..._iosUser,
        'locationAccuracy': 10,
        'fraud': {..._fraud, 'passed': false, 'mocked': true},
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

  group('RadarTrip', () {
    test('parses an Android-shaped trip with legs and orders', () {
      final trip = RadarTrip.fromMap(_androidTrip);
      expect(trip.id, 'trip-1');
      expect(trip.externalId, 'order-1');
      expect(trip.metadata, {'customer': 'alice'});
      expect(trip.destinationGeofenceTag, 'store');
      expect(trip.destinationGeofenceExternalId, '123');
      expect(
        trip.destinationLocation,
        const RadarCoordinate(latitude: 40.7342, longitude: -73.9911),
      );
      expect(trip.mode, RadarRouteMode.car);
      expect(trip.etaDistance, 1200.5);
      expect(trip.etaDuration, 4.5);
      expect(trip.status, RadarTripStatus.started);
      expect(trip.currentLegId, 'leg-1');

      final order = trip.orders.single;
      expect(order.id, 'order-a');
      expect(order.status, RadarTripOrderStatus.fired);
      expect(order.firedAttempts, 1);
      expect(order.firedAt, DateTime.utc(2026, 11, 19, 12));

      expect(trip.legs, hasLength(2));
      final first = trip.legs[0];
      expect(first.id, 'leg-1');
      expect(first.status, RadarTripLegStatus.started);
      expect(first.destinationType, RadarTripLegDestinationType.geofence);
      expect(first.destinationGeofenceTag, 'store');
      expect(first.destinationGeofenceExternalId, '123');
      expect(first.createdAt, DateTime.utc(2026, 11, 19, 11));
      expect(first.stopDuration, 5);
      expect(first.etaDuration, 4.5);

      final second = trip.legs[1];
      expect(second.status, RadarTripLegStatus.pending);
      expect(second.destinationType, RadarTripLegDestinationType.coordinates);
      expect(
        second.coordinates,
        const RadarCoordinate(latitude: 40.75, longitude: -73.98),
      );
      expect(second.arrivalRadius, 50);
      expect(second.metadata, {'dock': 4});
    });

    test('parses an iOS-shaped trip', () {
      final trip = RadarTrip.fromMap(_iosTrip);
      expect(trip.mode, RadarRouteMode.foot);
      expect(trip.status, RadarTripStatus.arrived);
      expect(trip.etaDistance, 0);
      expect(trip.destinationLocation, isNull);
      expect(trip.orders, isEmpty);
      final leg = trip.legs.single;
      expect(leg.destinationType, RadarTripLegDestinationType.address);
      expect(leg.address, '841 Broadway, New York, NY');
    });

    test('parses API-format legs', () {
      final geofence = RadarTripLeg.fromMap({
        '_id': 'leg-4',
        'status': 'approaching',
        'destination': {
          'type': 'geofence',
          'source': {
            'geofence': 'geofence-1',
            'data': {'tag': 'store', 'externalId': '123'},
          },
          'location': {
            'type': 'Point',
            'coordinates': [-73.9911, 40.7342],
          },
        },
      });
      expect(geofence.destinationType, RadarTripLegDestinationType.geofence);
      expect(geofence.destinationGeofenceId, 'geofence-1');
      expect(geofence.destinationGeofenceTag, 'store');
      expect(geofence.destinationGeofenceExternalId, '123');
      expect(geofence.coordinates!.latitude, 40.7342);

      final address = RadarTripLeg.fromMap({
        'destination': {
          'type': 'address',
          'source': {'data': '841 Broadway'},
        },
      });
      expect(address.destinationType, RadarTripLegDestinationType.address);
      expect(address.address, '841 Broadway');
    });

    test('is parsed from trip results', () {
      final result = RadarTripResult.fromMap({
        'status': 'SUCCESS',
        'trip': _androidTrip,
        'events': [
          {
            '_id': 'event-9',
            'type': 'user.updated_trip',
            'location': {
              'type': 'Point',
              'coordinates': [-73.9911, 40.7342],
            },
          },
        ],
      });
      expect(result.trip.id, 'trip-1');
      expect(result.trip.legs.first.id, 'leg-1');
      expect(result.events.single.type, RadarEventType.userUpdatedTrip);
    });

    test('a trip result without a trip throws errorServer', () {
      expect(
        () => RadarTripResult.fromMap({'status': 'SUCCESS'}),
        throwsA(
          isA<RadarException>().having(
            (e) => e.status,
            'status',
            RadarStatus.errorServer,
          ),
        ),
      );
    });

    test('reorderTripLegs results have no events', () {
      final result = RadarTripResult.fromMap({'trip': _androidTrip});
      expect(result.events, isEmpty);
    });

    test('status enums', () {
      expect(RadarTripStatus.fromWire('canceled'), RadarTripStatus.canceled);
      expect(RadarTripStatus.fromWire('STARTED'), RadarTripStatus.started);
      expect(RadarTripStatus.fromWire('paused'), RadarTripStatus.unknown);
      expect(RadarTripStatus.fromWire(null), RadarTripStatus.unknown);
      expect(
        RadarTripLegStatus.fromWire('pending'),
        RadarTripLegStatus.pending,
      );
      expect(RadarTripLegStatus.fromWire('nope'), RadarTripLegStatus.unknown);

      // The strings the updateTrip and updateTripLeg bridges compare against.
      expect(
        [
          RadarTripStatus.started,
          RadarTripStatus.approaching,
          RadarTripStatus.arrived,
          RadarTripStatus.completed,
          RadarTripStatus.canceled,
        ].map((s) => s.wireValue),
        ['started', 'approaching', 'arrived', 'completed', 'canceled'],
      );
      expect(RadarTripLegStatus.values.map((s) => s.wireValue), [
        'unknown',
        'pending',
        'started',
        'approaching',
        'arrived',
        'completed',
        'canceled',
        'expired',
      ]);
    });
  });

  group('RadarTripOptions', () {
    final options = RadarTripOptions(
      externalId: 'order-1',
      metadata: const {'customer': 'alice'},
      destinationGeofenceTag: 'store',
      destinationGeofenceExternalId: '123',
      mode: RadarRouteMode.bike,
      scheduledArrivalAt: DateTime.utc(2026, 11, 19, 18),
      approachingThreshold: 5,
      startTracking: false,
      legs: const [
        RadarTripLeg(
          destinationGeofenceTag: 'store',
          destinationGeofenceExternalId: '123',
          stopDuration: 10,
        ),
        RadarTripLeg(destinationGeofenceId: 'geofence-9'),
        RadarTripLeg(address: '841 Broadway'),
        RadarTripLeg(
          coordinates: RadarCoordinate(latitude: 40.75, longitude: -73.98),
          arrivalRadius: 30,
          metadata: {'dock': 4},
        ),
      ],
    );

    test('toMap uses the keys the native bridges parse', () {
      expect(options.toMap(), {
        'externalId': 'order-1',
        'metadata': {'customer': 'alice'},
        'destinationGeofenceTag': 'store',
        'destinationGeofenceExternalId': '123',
        'mode': 'bike',
        'scheduledArrivalAt':
            DateTime.utc(2026, 11, 19, 18).millisecondsSinceEpoch,
        'approachingThreshold': 5,
        'startTracking': false,
        'legs': [
          {
            'destination': {
              'destinationGeofenceTag': 'store',
              'destinationGeofenceExternalId': '123',
            },
            'stopDuration': 10,
          },
          {
            'destination': {'destinationGeofenceId': 'geofence-9'},
          },
          {
            'destination': {'address': '841 Broadway'},
          },
          {
            'destination': {
              'coordinates': [-73.98, 40.75],
              'arrivalRadius': 30,
            },
            'metadata': {'dock': 4},
          },
        ],
      });
    });

    test('toMap omits unset optional fields', () {
      expect(const RadarTripOptions(externalId: 'order-2').toMap(), {
        'externalId': 'order-2',
        'mode': 'car',
        'startTracking': true,
      });
    });

    test('round trips through toMap and fromMap', () {
      final parsed = RadarTripOptions.fromMap(options.toMap());
      expect(parsed.externalId, options.externalId);
      expect(parsed.metadata, options.metadata);
      expect(parsed.destinationGeofenceTag, options.destinationGeofenceTag);
      expect(
        parsed.destinationGeofenceExternalId,
        options.destinationGeofenceExternalId,
      );
      expect(parsed.mode, options.mode);
      expect(parsed.scheduledArrivalAt, options.scheduledArrivalAt);
      expect(parsed.approachingThreshold, options.approachingThreshold);
      expect(parsed.startTracking, options.startTracking);
      expect(parsed.legs, hasLength(4));
      expect(
        parsed.legs[0].destinationType,
        RadarTripLegDestinationType.geofence,
      );
      expect(parsed.legs[0].stopDuration, 10);
      expect(parsed.legs[1].destinationGeofenceId, 'geofence-9');
      expect(parsed.legs[2].address, '841 Broadway');
      expect(parsed.legs[3].coordinates, options.legs[3].coordinates);
      expect(parsed.legs[3].arrivalRadius, 30);
      expect(parsed.legs[3].metadata, {'dock': 4});
      expect(parsed.toMap(), options.toMap());
    });

    test('parses getTripOptions from each platform', () {
      // Both send scheduledArrivalAt as an ISO string.
      final android = RadarTripOptions.fromMap({
        'externalId': 'order-3',
        'metadata': null,
        'mode': 'truck',
        'scheduledArrivalAt': '2026-11-19T18:00:00.000Z',
        'startTracking': true,
      });
      expect(android.mode, RadarRouteMode.truck);
      expect(android.scheduledArrivalAt, DateTime.utc(2026, 11, 19, 18));
      expect(android.metadata, isNull);
      expect(android.approachingThreshold, 0);

      final ios = RadarTripOptions.fromMap({
        'externalId': 'order-4',
        'mode': 'motorbike',
        'approachingThreshold': 3,
        'startTracking': 0,
      });
      expect(ios.mode, RadarRouteMode.motorbike);
      expect(ios.approachingThreshold, 3);
      expect(ios.startTracking, isFalse);
    });
  });

  group('RadarRoutes', () {
    const route = <Object?, Object?>{
      'distance': {'value': 5280.0, 'text': '1.0 mi'},
      'duration': {'value': 4.2, 'text': '4 mins'},
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [-73.9911, 40.7342],
          [-73.9851, 40.7484],
        ],
      },
    };

    test('parses routes', () {
      final routes = RadarRoutes.fromMap({
        'geodesic': {
          'distance': {'value': 4800.0, 'text': '0.9 mi'},
        },
        'car': route,
      });
      expect(routes.geodesic!.distance!.value, 4800);
      expect(routes.geodesic!.duration, isNull);
      expect(routes.car!.distance!.text, '1.0 mi');
      expect(routes.car!.duration!.value, 4.2);
      expect(routes.car!.geometry!.coordinates, const [
        RadarCoordinate(latitude: 40.7342, longitude: -73.9911),
        RadarCoordinate(latitude: 40.7484, longitude: -73.9851),
      ]);
      expect(routes.foot, isNull);
      expect(routes.truck, isNull);
    });

    test('parses a matrix, which both platforms send as a list of rows', () {
      final matrix =
          RadarRouteMatrix.fromWire([
            [route, null],
            [route, route],
          ])!;
      expect(matrix.rows, hasLength(2));
      expect(matrix.routeBetween(0, 0)!.distance!.value, 5280);
      expect(matrix.routeBetween(0, 1), isNull);
      expect(matrix.routeBetween(1, 1)!.duration!.value, 4.2);
      expect(matrix.routeBetween(2, 0), isNull);
      expect(matrix.routeBetween(0, 5), isNull);
      expect(matrix.routeBetween(-1, 0), isNull);

      expect(RadarRouteMatrix.fromWire({'not': 'a list'}), isNull);
    });
  });

  group('garbage input', () {
    const garbage = <Object?, Object?>{
      '_id': 42,
      'type': ['nope'],
      'location': 'here',
      'coordinates': 'x',
      'geofences': 'none',
      'legs': [1, 'two', null],
      'eta': 'soon',
      'destination': [1, 2],
      'createdAt': true,
      'events': {'a': 1},
      'user': 'bob',
      'distance': 'far',
      'matrix': 'rows',
      'source': 7,
      'status': 99,
      'mode': false,
      'metadata': 'meta',
      'scheduledArrivalAt': {'when': 'later'},
    };

    test('does not throw', () {
      expect(() => RadarUser.fromMap(garbage), returnsNormally);
      expect(() => RadarEvent.fromMap(garbage), returnsNormally);
      expect(() => RadarTrip.fromMap(garbage), returnsNormally);
      expect(() => RadarTripLeg.fromMap(garbage), returnsNormally);
      expect(() => RadarTripOptions.fromMap(garbage), returnsNormally);
      expect(() => RadarRoutes.fromMap(garbage), returnsNormally);
      expect(() => RadarRoute.fromMap(garbage), returnsNormally);
      expect(RadarRouteMatrix.fromWire(garbage), isNull);
      expect(
        () => RadarRouteMatrix.fromWire([
          1,
          'a',
          [2],
        ]),
        returnsNormally,
      );
      expect(
        () => RadarVerifiedLocationToken.fromMap(garbage),
        returnsNormally,
      );
      expect(() => RadarFraud.fromMap(garbage), returnsNormally);
      expect(() => RadarSegment.fromMap(garbage), returnsNormally);
    });

    test('yields defaults', () {
      final user = RadarUser.fromMap(garbage);
      expect(user.id, '');
      expect(user.location, isNull);
      expect(user.geofences, isEmpty);
      expect(user.source, RadarLocationSource.unknown);

      final trip = RadarTrip.fromMap(garbage);
      expect(trip.status, RadarTripStatus.unknown);
      expect(trip.mode, isNull);
      expect(trip.legs, isEmpty);
      expect(trip.etaDistance, isNull);

      final options = RadarTripOptions.fromMap(const {});
      expect(options.externalId, '');
      expect(options.mode, RadarRouteMode.car);
      expect(options.startTracking, isTrue);

      final token = RadarVerifiedLocationToken.fromMap(garbage);
      expect(token.token, isNull);
      expect(token.user, isNull);
      expect(token.events, isEmpty);

      final event = RadarEvent.fromMap(const {'type': 'user.unknown_thing'});
      expect(event.type, RadarEventType.unknown);
      expect(event.location, isNull);
    });
  });
}
