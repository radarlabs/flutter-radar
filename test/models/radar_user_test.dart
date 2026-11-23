import 'package:flutter_radar/src/models/radar_location.dart';
import 'package:flutter_radar/src/models/radar_update.dart';
import 'package:flutter_radar/src/models/radar_user.dart';
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
  'fraud': fraud,
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

void main() {
  group('RadarUser', () {
    test('parses an Android-shaped user', () {
      final user = RadarUser.fromMap(_androidUser)!;
      expect(user.id, 'user-1');
      expect(user.userId, 'alice');
      expect(user.deviceId, 'device-1');
      expect(user.description, 'Alice');
      expect(user.metadata, {'plan': 'pro'});
      expect(user.location.latitude, 40.7342);
      expect(user.location.longitude, -73.9911);
      expect(user.location.accuracy, isNull);
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
      expect(
        user.expectedAddress!.coordinate,
        const RadarCoordinate(latitude: 40.7342, longitude: -73.9911),
      );
      expect(user.locationInsights, isNull);
    });

    test('parses an iOS-shaped user', () {
      final user = RadarUser.fromMap(iosUser)!;
      expect(user.id, 'user-2');
      expect(user.userId, isNull);
      expect(user.location.latitude, 37.7749);
      expect(user.activityType, RadarActivityType.stationary);
      expect(user.source, RadarLocationSource.visitArrival);
      expect(user.debug, isTrue);
      expect(user.foreground, isTrue);
      expect(user.trip, isNull);
      expect(user.altitude, isNull);
      expect(user.locationInsights!.atHome, isTrue);
      expect(user.locationInsights!.commuting, isFalse);
    });

    test('commuting is null when iOS leaves it out', () {
      final insights = RadarUserLocationInsights.fromMap({'atHome': true});
      expect(insights.atHome, isTrue);
      expect(insights.commuting, isNull);
    });

    test('a user without a location is null', () {
      expect(RadarUser.fromMap({'_id': 'user-1'}), isNull);
    });

    test('an expected address without coordinates has no coordinate', () {
      final address = RadarExpectedAddress.fromMap({
        'expectedAddress': 'nowhere',
        'latitude': 40.7,
      });
      expect(address.coordinate, isNull);
    });

    test('reads locationAccuracy and barometricAltitude from API users', () {
      final user =
          RadarUser.fromMap({
            ...iosUser,
            'locationAccuracy': 15,
            'barometricAltitude': 3.5,
            'altitude': 9.0,
          })!;
      expect(user.location.accuracy, 15);
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
}
