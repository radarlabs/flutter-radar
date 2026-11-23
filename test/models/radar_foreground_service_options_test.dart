import 'package:flutter_radar/src/models/radar_foreground_service_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadarForegroundServiceOptions', () {
    test('toMap matches RadarTrackingOptionsForegroundService.fromJson', () {
      const options = RadarForegroundServiceOptions(
        text: 'Tracking',
        title: 'Radar',
        icon: 42,
        iconString: 'ic',
        iconColor: '#FF0000',
        updatesOnly: true,
        activity: 'com.example.MainActivity',
        importance: 3,
        id: 7,
        channelName: 'Location',
        deepLink: 'app://x',
      );
      expect(options.toMap(), {
        'text': 'Tracking',
        'title': 'Radar',
        'icon': 42,
        'iconString': 'ic',
        'iconColor': '#FF0000',
        'updatesOnly': true,
        'activity': 'com.example.MainActivity',
        'importance': 3,
        'id': 7,
        'channelName': 'Location',
        'deepLink': 'app://x',
      });
    });

    test('toMap omits null fields', () {
      expect(const RadarForegroundServiceOptions().toMap(), {
        'updatesOnly': false,
      });
    });
  });
}
