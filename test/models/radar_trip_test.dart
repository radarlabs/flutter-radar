import 'package:flutter_radar/src/models/radar_enums.dart';
import 'package:flutter_radar/src/models/radar_location.dart';
import 'package:flutter_radar/src/models/radar_trip.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

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

void main() {
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
      expect(trip.etaDuration, const Duration(minutes: 4, seconds: 30));
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
      expect(first.stopDuration, const Duration(minutes: 5));
      expect(first.etaDuration, const Duration(minutes: 4, seconds: 30));

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
      final trip = RadarTrip.fromMap(iosTrip);
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
    test('leg constructors set one destination', () {
      expect(
        const RadarTripLeg.geofence(
          tag: 'store',
          externalId: '123',
          stopDuration: Duration(minutes: 5),
        ).toMap(),
        {
          'destination': {
            'destinationGeofenceTag': 'store',
            'destinationGeofenceExternalId': '123',
          },
          'stopDuration': 5,
        },
      );
      expect(const RadarTripLeg.geofenceId('geofence-9').toMap(), {
        'destination': {'destinationGeofenceId': 'geofence-9'},
      });
      expect(
        const RadarTripLeg.address('841 Broadway', metadata: {'n': 1}).toMap(),
        {
          'destination': {'address': '841 Broadway'},
          'metadata': {'n': 1},
        },
      );
      const leg = RadarTripLeg.coordinates(
        RadarCoordinate(latitude: 40.73, longitude: -73.99),
        arrivalRadius: 50,
      );
      expect(leg.destinationType, RadarTripLegDestinationType.coordinates);
      expect(leg.toMap(), {
        'destination': {
          'coordinates': [-73.99, 40.73],
          'arrivalRadius': 50,
        },
      });
    });

    test('durations are sent in whole minutes', () {
      expect(
        const RadarTripLeg.address(
          'a',
          stopDuration: Duration(minutes: 3),
        ).toMap()['stopDuration'],
        3,
      );
      expect(
        const RadarTripOptions(
          externalId: 'x',
          approachingThreshold: Duration(minutes: 2),
        ).toMap()['approachingThreshold'],
        2,
      );
      expect(
        const RadarTripLeg.address(
          'a',
          stopDuration: Duration(minutes: 2, seconds: 40),
        ).toMap,
        throwsA(isA<AssertionError>()),
      );
      expect(
        const RadarTripOptions(
          externalId: 'x',
          approachingThreshold: Duration(seconds: 20),
        ).toMap,
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith replaces only the given fields, and == compares values', () {
      const options = RadarTripOptions(
        externalId: 'order-1',
        metadata: {'customer': 'alice'},
        legs: [RadarTripLeg.address('841 Broadway')],
      );
      final copy = options.copyWith(mode: RadarRouteMode.bike);
      expect(copy.mode, RadarRouteMode.bike);
      expect(copy.externalId, 'order-1');
      expect(copy.legs, options.legs);
      expect(copy, isNot(options));
      expect(copy.copyWith(mode: RadarRouteMode.car), options);
      expect(
        copy.copyWith(mode: RadarRouteMode.car).hashCode,
        options.hashCode,
      );
      expect(
        options,
        const RadarTripOptions(
          externalId: 'order-1',
          metadata: {'customer': 'alice'},
          legs: [RadarTripLeg.address('841 Broadway')],
        ),
      );
    });

    test('an order without updatedAt is dropped', () {
      expect(RadarTripOrder.fromMap({'_id': 'order-1'}), isNull);
    });

    final options = RadarTripOptions(
      externalId: 'order-1',
      metadata: const {'customer': 'alice'},
      destinationGeofenceTag: 'store',
      destinationGeofenceExternalId: '123',
      mode: RadarRouteMode.bike,
      scheduledArrivalAt: DateTime.utc(2026, 11, 19, 18),
      approachingThreshold: const Duration(minutes: 5),
      startTracking: false,
      legs: const [
        RadarTripLeg(
          destinationGeofenceTag: 'store',
          destinationGeofenceExternalId: '123',
          stopDuration: Duration(minutes: 10),
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
      expect(parsed.legs[0].stopDuration, const Duration(minutes: 10));
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
      expect(android.approachingThreshold, Duration.zero);

      final ios = RadarTripOptions.fromMap({
        'externalId': 'order-4',
        'mode': 'motorbike',
        'approachingThreshold': 3,
        'startTracking': 0,
      });
      expect(ios.mode, RadarRouteMode.motorbike);
      expect(ios.approachingThreshold, const Duration(minutes: 3));
      expect(ios.startTracking, isFalse);
    });
  });
}
