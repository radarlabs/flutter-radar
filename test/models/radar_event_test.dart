import 'package:flutter_radar/src/models/radar_event.dart';
import 'package:flutter_radar/src/models/radar_trip.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

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

void main() {
  group('RadarEvent', () {
    test('parses an Android-shaped geofence entry', () {
      final event =
          RadarEvent.fromMap({
            '_id': 'event-1',
            'createdAt': '2026-11-19T12:00:00.000Z',
            'actualCreatedAt': '2026-11-19T12:00:01.000Z',
            'live': false,
            'type': 'user.entered_geofence',
            'geofence': _geofence,
            'confidence': 3,
            'duration': 0.0,
            'fraud': fraud,
            'alternatePlaces': <Object?>[],
            'location': {
              'type': 'Point',
              'coordinates': [-73.9911, 40.7342],
            },
            'replayed': false,
            'metadata': {'source': 'test'},
          })!;
      expect(event.id, 'event-1');
      expect(event.type, RadarEventType.userEnteredGeofence);
      expect(event.createdAt, DateTime.utc(2026, 11, 19, 12));
      expect(event.actualCreatedAt, DateTime.utc(2026, 11, 19, 12, 0, 1));
      expect(event.live, isFalse);
      expect(event.geofence!.tag, 'store');
      expect(event.confidence, RadarEventConfidence.high);
      expect(event.duration, Duration.zero);
      expect(event.fraud!.passed, isTrue);
      expect(event.location!.latitude, 40.7342);
      expect(event.location!.longitude, -73.9911);
      expect(event.verification, isNull);
      expect(event.conversionName, isNull);
      expect(event.metadata, {'source': 'test'});
    });

    test('parses an iOS-shaped region exit with a trip event', () {
      final region =
          RadarEvent.fromMap({
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
          })!;
      expect(region.type, RadarEventType.userExitedRegionCountry);
      expect(region.region!.code, 'US');
      expect(region.confidence, RadarEventConfidence.medium);
      expect(region.duration, const Duration(minutes: 12, seconds: 30));
      expect(region.live, isTrue);
      expect(region.replayed, isTrue);
      expect(region.actualCreatedAt, isNull);

      final trip =
          RadarEvent.fromMap({
            '_id': 'event-3',
            'type': 'user.arrived_at_trip_destination',
            'createdAt': '2026-11-19T12:00:00.000Z',
            'trip': iosTrip,
            'confidence': 0,
          })!;
      expect(trip.type, RadarEventType.userArrivedAtTripDestination);
      expect(trip.trip!.status, RadarTripStatus.arrived);
      expect(trip.confidence, RadarEventConfidence.none);
      expect(trip.location, isNull);
    });

    test('parses conversion events from each platform', () {
      // Android omits `type` for conversions.
      final android =
          RadarEvent.fromMap({
            '_id': 'event-4',
            'createdAt': '2026-11-19T15:00:00.000Z',
            'live': false,
            'confidence': 0,
            'metadata': {'revenue': 10},
          })!;
      expect(android.type, RadarEventType.conversion);
      expect(android.conversionName, isNull);
      expect(android.location, isNull);

      // iOS sends `custom`.
      final ios =
          RadarEvent.fromMap({
            '_id': 'event-5',
            'type': 'custom',
            'createdAt': '2026-11-19T15:00:00.000Z',
          })!;
      expect(ios.type, RadarEventType.conversion);
      expect(ios.conversionName, isNull);

      // The API sends the conversion name.
      final api =
          RadarEvent.fromMap({
            '_id': 'event-6',
            'type': 'purchase',
            'createdAt': '2026-11-19T15:00:00.000Z',
          })!;
      expect(api.type, RadarEventType.conversion);
      expect(api.conversionName, 'purchase');
    });

    test('parses API fields: verification, accuracy, verified place', () {
      final event =
          RadarEvent.fromMap({
            '_id': 'event-7',
            'type': 'user.entered_place',
            'createdAt': '2026-11-19T15:00:00.000Z',
            'place': {
              '_id': 'place-1',
              'name': 'Starbucks',
              'location': {
                'type': 'Point',
                'coordinates': [-73.99, 40.73],
              },
            },
            'verifiedPlace': {
              '_id': 'place-2',
              'name': 'Blue Bottle',
              'location': {
                'type': 'Point',
                'coordinates': [-73.99, 40.73],
              },
            },
            'alternatePlaces': [
              {
                '_id': 'place-2',
                'name': 'Blue Bottle',
                'location': {
                  'type': 'Point',
                  'coordinates': [-73.99, 40.73],
                },
              },
            ],
            'verification': -1,
            'confidence': 1,
            'location': {
              'type': 'Point',
              'coordinates': [-73.9911, 40.7342],
            },
            'locationAccuracy': 25,
          })!;
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

    test('garbage values do not throw', () {
      const garbage = <Object?, Object?>{
        '_id': 42,
        'type': 'user.unknown_thing',
        'createdAt': true,
        'actualCreatedAt': 'yesterday',
        'geofence': 'geofence',
        'place': 1,
        'region': [1, 2],
        'beacon': 'beacon',
        'trip': 'trip',
        'fraud': 'fraud',
        'alternatePlaces': 'none',
        'verifiedPlace': 3,
        'verification': 'maybe',
        'confidence': 'very',
        'duration': 'long',
        'location': 'here',
        'metadata': 'meta',
      };
      expect(RadarEvent.fromMap(garbage), isNull);

      final event =
          RadarEvent.fromMap({
            ...garbage,
            'createdAt': '2026-11-19T15:00:00.000Z',
          })!;
      expect(event.id, '');
      expect(event.type, RadarEventType.unknown);
      expect(event.actualCreatedAt, isNull);
      expect(event.geofence, isNull);
      expect(event.place, isNull);
      expect(event.region, isNull);
      expect(event.beacon, isNull);
      expect(event.trip, isNull);
      expect(event.fraud, isNull);
      expect(event.alternatePlaces, isEmpty);
      expect(event.verifiedPlace, isNull);
      expect(event.verification, isNull);
      expect(event.confidence, RadarEventConfidence.none);
      expect(event.duration, isNull);
      expect(event.location, isNull);
      expect(event.metadata, isNull);
    });

    test('an unrecognized user.* type is unknown, not a conversion', () {
      expect(RadarEvent.fromMap(const {'type': 'user.unknown_thing'}), isNull);
      final event =
          RadarEvent.fromMap(const {
            'type': 'user.unknown_thing',
            'createdAt': '2026-11-19T15:00:00.000Z',
          })!;
      expect(event.type, RadarEventType.unknown);
      expect(event.conversionName, isNull);
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
}
