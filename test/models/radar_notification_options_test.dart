import 'package:flutter_radar/src/models/radar_notification_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadarNotificationOptions', () {
    test('toMap matches RadarNotificationOptions.fromJson keys', () {
      const options = RadarNotificationOptions(
        iconString: 'ic',
        iconColor: '#111111',
        foregroundServiceIconString: 'fg',
        foregroundServiceIconColor: '#222222',
        eventIconString: 'ev',
        eventIconColor: '#333333',
        deepLink: 'app://x',
      );
      expect(options.toMap(), {
        'iconString': 'ic',
        'iconColor': '#111111',
        'foregroundServiceIconString': 'fg',
        'foregroundServiceIconColor': '#222222',
        'eventIconString': 'ev',
        'eventIconColor': '#333333',
        'deepLink': 'app://x',
      });
    });

    test('toMap omits null fields', () {
      expect(const RadarNotificationOptions(iconString: 'ic').toMap(), {
        'iconString': 'ic',
      });
    });
  });
}
