import 'dart:ui';

import 'package:flutter_radar/src/models/radar_in_app_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadarInAppMessage', () {
    const message = RadarInAppMessage(
      title: RadarInAppMessageText(text: 'Hi', color: Color(0xFF000000)),
      body: RadarInAppMessageText(text: 'Body', color: Color(0xFF111111)),
      button: RadarInAppMessageButton(
        text: 'Go',
        color: Color(0xFFFFFFFF),
        backgroundColor: Color(0xFF0000FF),
        deepLink: 'app://go',
      ),
      image: RadarInAppMessageImage(
        name: 'hero',
        url: 'https://example.com/a.png',
      ),
      metadata: {'campaign': 'x', 'n': 1},
    );

    test('toMap matches what both SDKs parse', () {
      expect(message.toMap(), {
        'title': {'text': 'Hi', 'color': '#000000'},
        'body': {'text': 'Body', 'color': '#111111'},
        'button': {
          'text': 'Go',
          'color': '#FFFFFF',
          'backgroundColor': '#0000FF',
          'deepLink': 'app://go',
        },
        'image': {'name': 'hero', 'url': 'https://example.com/a.png'},
        'metadata': {'campaign': 'x', 'n': 1},
      });
    });

    test('toMap omits optional parts and null strings', () {
      // iOS casts these sub-maps to [String: String], so they must not
      // contain nulls.
      const minimal = RadarInAppMessage(
        title: RadarInAppMessageText(text: 'Hi', color: Color(0xFF000000)),
        body: RadarInAppMessageText(text: 'Body', color: Color(0xFF111111)),
        button: RadarInAppMessageButton(
          text: 'Go',
          color: Color(0xFFFFFFFF),
          backgroundColor: Color(0xFF0000FF),
        ),
        image: RadarInAppMessageImage(name: 'hero'),
      );
      expect(minimal.toMap(), {
        'title': {'text': 'Hi', 'color': '#000000'},
        'body': {'text': 'Body', 'color': '#111111'},
        'button': {
          'text': 'Go',
          'color': '#FFFFFF',
          'backgroundColor': '#0000FF',
        },
        'image': {'name': 'hero'},
        'metadata': <String, Object?>{},
      });
    });

    test('colors are sent as #RRGGBB without alpha', () {
      const text = RadarInAppMessageText(text: 'Hi', color: Color(0x80ab01cd));
      expect(text.toMap(), {'text': 'Hi', 'color': '#AB01CD'});
    });
  });
}
