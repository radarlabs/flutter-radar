import 'package:flutter_radar/src/models/radar_exception.dart';
import 'package:flutter_radar/src/models/radar_status.dart';
import 'package:flutter_radar/src/models/radar_update.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

const _location = <Object?, Object?>{
  'latitude': 40.7342,
  'longitude': -73.9911,
};

void main() {
  group('RadarUpdate', () {
    test('parses a location update', () {
      final update = RadarUpdate.fromMethodCall('location', {
        'location': _location,
        'user': iosUser,
      });
      final location = update! as RadarLocationUpdate;
      expect(location.location.latitude, 40.7342);
      expect(location.user.location.latitude, 37.7749);
    });

    test('drops updates missing a value both platforms always send', () {
      expect(
        RadarUpdate.fromMethodCall('location', {'location': _location}),
        isNull,
      );
      expect(RadarUpdate.fromMethodCall('location', {'user': iosUser}), isNull);
      expect(RadarUpdate.fromMethodCall('clientLocation', {}), isNull);
      expect(RadarUpdate.fromMethodCall('token', {}), isNull);
    });

    test('unknown methods are ignored', () {
      expect(RadarUpdate.fromMethodCall('somethingNew', {}), isNull);
    });
  });

  group('RadarException', () {
    test('toString names the Dart status', () {
      expect(
        const RadarException(RadarStatus.errorLocation).toString(),
        'RadarException(errorLocation)',
      );
    });
  });
}
