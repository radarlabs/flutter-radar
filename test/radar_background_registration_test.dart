import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:flutter_radar/src/radar_background.dart' as background;
import 'package:flutter_test/flutter_test.dart';

RadarBackgroundEvent? receivedBackgroundEvent;

@pragma('vm:entry-point')
Future<void> testBackgroundHandler(RadarBackgroundEvent event) async {
  receivedBackgroundEvent = event;
}

Future<void> sendClientLocationEvent() async {
  final callbackHandle =
      PluginUtilities.getCallbackHandle(testBackgroundHandler)!;

  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'flutter_radar_background',
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('clientLocation', {
            'callbackHandle': callbackHandle.toRawHandle(),
            'payload': {
              'location': {'latitude': 47.0, 'longitude': -122.0},
              'stopped': false,
              'source': 'background',
            },
          }),
        ),
        null,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_radar');
  MethodCall? receivedCall;
  const backgroundChannel = MethodChannel('flutter_radar_background');

  setUp(() {
    receivedCall = null;
    receivedBackgroundEvent = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          receivedCall = call;
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    backgroundChannel.setMethodCallHandler(null);
  });

  group('Radar.registerBackgroundHandler', () {
    test('sends the dispatcher and callback handles to native', () async {
      await Radar.registerBackgroundHandler(testBackgroundHandler);

      final dispatcherHandle = PluginUtilities.getCallbackHandle(
        background.radarBackgroundCallbackDispatcher,
      );
      final callbackHandle = PluginUtilities.getCallbackHandle(
        testBackgroundHandler,
      );

      expect(dispatcherHandle, isNotNull);
      expect(callbackHandle, isNotNull);
      expect(receivedCall?.method, 'registerBackgroundHandler');
      expect(receivedCall?.arguments, {
        'dispatcherHandle': dispatcherHandle!.toRawHandle(),
        'callbackHandle': callbackHandle!.toRawHandle(),
      });
    });

    test('rejects closures before calling native', () async {
      var capturedValue = 0;

      final handler = (RadarBackgroundEvent event) async {
        capturedValue++;
      };

      await expectLater(
        Radar.registerBackgroundHandler(handler),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'handler'),
        ),
      );

      expect(receivedCall, isNull);
      expect(capturedValue, 0);
    });

    test('propagates native registration failures', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(
              code: 'registration_failed',
              message: 'Could not persist callback handles.',
            );
          });

      await expectLater(
        Radar.registerBackgroundHandler(testBackgroundHandler),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'registration_failed',
          ),
        ),
      );
    });

    test('receives durable events on the primary isolate', () async {
      await Radar.registerBackgroundHandler(testBackgroundHandler);

      await sendClientLocationEvent();

      expect(
        receivedBackgroundEvent?.type,
        RadarBackgroundEventType.clientLocation,
      );
      expect(receivedBackgroundEvent?.payload, {
        'location': {'latitude': 47.0, 'longitude': -122.0},
        'stopped': false,
        'source': 'background',
      });
    });
  });

  group('Radar.unregisterBackgroundHandler', () {
    test('asks native to remove the persisted handler', () async {
      await Radar.unregisterBackgroundHandler();

      expect(receivedCall?.method, 'unregisterBackgroundHandler');
      expect(receivedCall?.arguments, isNull);
    });

    test('stops primary-isolate delivery after unregistration', () async {
      await Radar.registerBackgroundHandler(testBackgroundHandler);
      await Radar.unregisterBackgroundHandler();

      await sendClientLocationEvent();

      expect(receivedBackgroundEvent, isNull);
    });

    test(
      'keeps primary-isolate delivery when native unregistration fails',
      () async {
        await Radar.registerBackgroundHandler(testBackgroundHandler);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              throw PlatformException(
                code: 'unregistration_failed',
                message: 'Could not remove callback handles.',
              );
            });

        await expectLater(
          Radar.unregisterBackgroundHandler(),
          throwsA(
            isA<PlatformException>().having(
              (error) => error.code,
              'code',
              'unregistration_failed',
            ),
          ),
        );

        await sendClientLocationEvent();

        expect(
          receivedBackgroundEvent?.type,
          RadarBackgroundEventType.clientLocation,
        );
      },
    );
  });
}
