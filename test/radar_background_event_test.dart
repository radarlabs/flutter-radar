import 'package:flutter_radar/flutter_radar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadarBackgroundEvent', () {
    test('exposes all supported event types', () {
      expect(RadarBackgroundEventType.values.toSet(), {
        RadarBackgroundEventType.location,
        RadarBackgroundEventType.clientLocation,
        RadarBackgroundEventType.events,
        RadarBackgroundEventType.error,
        RadarBackgroundEventType.log,
        RadarBackgroundEventType.token,
        RadarBackgroundEventType.ipChanged,
        RadarBackgroundEventType.sharingChanged,
      });
    });

    test('carries its type and payload', () {
      const event = RadarBackgroundEvent(
        type: RadarBackgroundEventType.sharingChanged,
        payload: {'sharing': true},
      );

      expect(event.type, RadarBackgroundEventType.sharingChanged);
      expect(event.payload, {'sharing': true});
    });
  });
}
