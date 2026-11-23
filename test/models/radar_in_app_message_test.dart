import 'package:flutter_radar/src/models/radar_in_app_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadarInAppMessage', () {
    const message = RadarInAppMessage(
      title: RadarInAppMessageText(text: 'Hi', color: '#000000'),
      body: RadarInAppMessageText(text: 'Body', color: '#111111'),
      button: RadarInAppMessageButton(
        text: 'Go',
        color: '#FFFFFF',
        backgroundColor: '#0000FF',
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
        title: RadarInAppMessageText(text: 'Hi', color: '#000000'),
        body: RadarInAppMessageText(text: 'Body', color: '#111111'),
        button: RadarInAppMessageButton(
          text: 'Go',
          color: '#FFFFFF',
          backgroundColor: '#0000FF',
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

    test('fromMap round-trips toMap', () {
      final parsed = RadarInAppMessage.fromMap(message.toMap())!;
      expect(parsed.toMap(), message.toMap());
    });

    test('fromMap treats Android empty-string defaults as null', () {
      final parsed =
          RadarInAppMessage.fromMap({
            'title': {'text': 'Hi', 'color': '#000000'},
            'body': {'text': 'Body', 'color': '#111111'},
            'button': {
              'text': 'Go',
              'color': '#FFFFFF',
              'backgroundColor': '#0000FF',
              'deepLink': '',
            },
            'image': {'name': 'hero', 'url': ''},
          })!;
      expect(parsed.button!.deepLink, isNull);
      expect(parsed.image!.url, isNull);
      expect(parsed.metadata, isEmpty);
    });

    test('fromMap returns null without a valid title or body', () {
      expect(RadarInAppMessage.fromMap(null), isNull);
      expect(RadarInAppMessage.fromMap({}), isNull);
      expect(
        RadarInAppMessage.fromMap({
          'title': {'text': 'Hi'},
          'body': {'text': 'Body', 'color': '#111111'},
        }),
        isNull,
      );
    });

    test('fromMap drops an invalid button', () {
      final parsed =
          RadarInAppMessage.fromMap({
            'title': {'text': 'Hi', 'color': '#000000'},
            'body': {'text': 'Body', 'color': '#111111'},
            'button': {'text': 'Go'},
          })!;
      expect(parsed.button, isNull);
    });
  });
}
