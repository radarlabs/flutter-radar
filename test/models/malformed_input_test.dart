import 'package:flutter_radar/src/models/radar_enums.dart';
import 'package:flutter_radar/src/models/radar_event.dart';
import 'package:flutter_radar/src/models/radar_fraud.dart';
import 'package:flutter_radar/src/models/radar_routes.dart';
import 'package:flutter_radar/src/models/radar_trip.dart';
import 'package:flutter_radar/src/models/radar_user.dart';
import 'package:flutter_radar/src/models/radar_verified_location_token.dart';
import 'package:flutter_test/flutter_test.dart';

const _point = <Object?, Object?>{
  'type': 'Point',
  'coordinates': [-73.99, 40.73],
};

void main() {
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
      expect(RadarUser.fromMap(garbage), isNull);
      final user = RadarUser.fromMap({...garbage, 'location': _point})!;
      expect(user.id, '');
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

      expect(RadarEvent.fromMap(const {'type': 'user.unknown_thing'}), isNull);
      final event =
          RadarEvent.fromMap(const {
            'type': 'user.unknown_thing',
            'createdAt': '2026-11-19T15:00:00.000Z',
          })!;
      expect(event.type, RadarEventType.unknown);
      expect(event.location, isNull);
    });
  });
}
