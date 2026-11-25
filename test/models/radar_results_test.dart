import 'package:flutter_radar/src/models/radar_event.dart';
import 'package:flutter_radar/src/models/radar_exception.dart';
import 'package:flutter_radar/src/models/radar_results.dart';
import 'package:flutter_radar/src/models/radar_status.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

const _location = <Object?, Object?>{
  'latitude': 40.7342,
  'longitude': -73.9911,
};

const _event = <Object?, Object?>{
  '_id': 'event-9',
  'type': 'user.updated_trip',
  'createdAt': '2026-11-19T12:00:00.000Z',
};

final _throwsErrorServer = throwsA(
  isA<RadarException>().having(
    (e) => e.status,
    'status',
    RadarStatus.errorServer,
  ),
);

void main() {
  group('results', () {
    // Each result parser, a minimal payload the bridges send on success, and
    // that payload without each field the result requires.
    final cases = <
      String,
      (
        Object Function(Map<Object?, Object?>),
        Map<Object?, Object?>,
        List<String>,
      )
    >{
      'RadarLocationResult': (
        RadarLocationResult.fromMap,
        {'location': _location, 'stopped': true},
        ['location'],
      ),
      'RadarTrackResult': (
        RadarTrackResult.fromMap,
        {
          'location': _location,
          'user': iosUser,
          'events': [_event],
        },
        ['location'],
      ),
      'RadarTripResult': (
        RadarTripResult.fromMap,
        {
          'trip': iosTrip,
          'events': [_event],
        },
        ['trip'],
      ),
      'RadarContextResult': (
        RadarContextResult.fromMap,
        {'location': _location, 'context': <Object?, Object?>{}},
        ['location', 'context'],
      ),
      'RadarSearchGeofencesResult': (
        RadarSearchGeofencesResult.fromMap,
        {
          'location': _location,
          'geofences': [circleGeofenceMap],
        },
        ['location'],
      ),
      'RadarSearchPlacesResult': (
        RadarSearchPlacesResult.fromMap,
        {'location': _location, 'places': <Object?>[]},
        ['location'],
      ),
      'RadarIpGeocodeResult': (
        RadarIpGeocodeResult.fromMap,
        {'address': addressMap, 'proxy': true},
        ['address'],
      ),
      'RadarValidateAddressResult': (
        RadarValidateAddressResult.fromMap,
        {'address': addressMap, 'verificationStatus': 'VERIFIED'},
        ['address'],
      ),
    };

    for (final MapEntry(key: name, value: (parse, payload, required))
        in cases.entries) {
      test('$name parses a success payload', () {
        expect(() => parse(payload), returnsNormally);
      });

      test('$name throws errorServer without a required field', () {
        expect(() => parse(const {}), _throwsErrorServer);
        for (final key in required) {
          expect(() => parse({...payload}..remove(key)), _throwsErrorServer);
          expect(() => parse({...payload, key: 'garbage'}), _throwsErrorServer);
        }
      });
    }

    test('RadarTrackResult reads the location, user, and events', () {
      final result = RadarTrackResult.fromMap({
        'location': _location,
        'user': iosUser,
        'events': [_event],
      });
      expect(result.location.latitude, 40.7342);
      expect(result.user, isNotNull);
      expect(result.events.single.type, RadarEventType.userUpdatedTrip);
    });

    test('RadarTrackResult allows no user or events, as after a replay', () {
      final result = RadarTrackResult.fromMap({'location': _location});
      expect(result.location.longitude, -73.9911);
      expect(result.user, isNull);
      expect(result.events, isEmpty);
    });

    test('RadarTripResult reads the trip and events', () {
      final result = RadarTripResult.fromMap({
        'trip': iosTrip,
        'events': [_event],
      });
      expect(result.trip.id, 'trip-2');
      expect(result.trip.legs.single.id, 'leg-3');
      expect(result.events.single.type, RadarEventType.userUpdatedTrip);
    });

    test('reorderTripLegs results have no events', () {
      expect(RadarTripResult.fromMap({'trip': iosTrip}).events, isEmpty);
    });
  });
}
