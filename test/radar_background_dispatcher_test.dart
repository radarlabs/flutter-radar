import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_radar/src/radar_background.dart';
import 'package:flutter_test/flutter_test.dart';

MethodCall _backgroundCall({
  String method = 'location',
  Object? callbackHandle = 42,
  Object? payload = const <String, dynamic>{},
}) {
  return MethodCall(method, {
    'callbackHandle': callbackHandle,
    'payload': payload,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('radarBackgroundCallbackDispatcher', () {
    const backgroundChannel = MethodChannel('flutter_radar_background');
    late List<MethodCall> nativeCalls;

    setUp(() {
      nativeCalls = [];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(backgroundChannel, (call) async {
            nativeCalls.add(call);
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(backgroundChannel, null);
      backgroundChannel.setMethodCallHandler(null);
    });

    test('notifies native when the background isolate is ready', () async {
      radarBackgroundCallbackDispatcher();
      await Future<void>.delayed(Duration.zero);

      expect(nativeCalls, hasLength(1));
      expect(nativeCalls.single.method, 'initialized');
      expect(nativeCalls.single.arguments, isNull);
    });
  });
  group('handleRadarBackgroundMethodCall', () {
    final eventTypes = {
      'location': RadarBackgroundEventType.location,
      'clientLocation': RadarBackgroundEventType.clientLocation,
      'events': RadarBackgroundEventType.events,
      'error': RadarBackgroundEventType.error,
      'log': RadarBackgroundEventType.log,
      'token': RadarBackgroundEventType.token,
      'ipChanged': RadarBackgroundEventType.ipChanged,
      'sharingChanged': RadarBackgroundEventType.sharingChanged,
    };

    for (final entry in eventTypes.entries) {
      test('delivers ${entry.key}', () async {
        RadarBackgroundEvent? receivedEvent;
        int? resolvedHandle;

        await handleRadarBackgroundMethodCall(
          _backgroundCall(method: entry.key, payload: {'event': entry.key}),
          callbackResolver: (handle) {
            resolvedHandle = handle.toRawHandle();

            return (RadarBackgroundEvent event) async {
              receivedEvent = event;
            };
          },
        );

        expect(resolvedHandle, 42);
        expect(receivedEvent?.type, entry.value);
        expect(receivedEvent?.payload, {'event': entry.key});
      });
    }

    test('waits for the callback to complete', () async {
      final callbackStarted = Completer<void>();
      final callbackCanFinish = Completer<void>();
      var deliveryCompleted = false;

      final delivery = handleRadarBackgroundMethodCall(
        _backgroundCall(),
        callbackResolver: (_) {
          return (RadarBackgroundEvent event) async {
            callbackStarted.complete();
            await callbackCanFinish.future;
          };
        },
      );

      final observedDelivery = delivery.then((_) {
        deliveryCompleted = true;
      });

      await callbackStarted.future;
      await Future<void>.delayed(Duration.zero);
      expect(deliveryCompleted, isFalse);

      callbackCanFinish.complete();
      await observedDelivery;
      expect(deliveryCompleted, isTrue);
    });

    test('rejects non-map arguments', () async {
      await expectLater(
        handleRadarBackgroundMethodCall(
          const MethodCall('location', 'invalid'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a non-integer callback handle', () async {
      await expectLater(
        handleRadarBackgroundMethodCall(_backgroundCall(callbackHandle: '42')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a non-map payload', () async {
      await expectLater(
        handleRadarBackgroundMethodCall(_backgroundCall(payload: 'invalid')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects an unsupported event type', () async {
      await expectLater(
        handleRadarBackgroundMethodCall(_backgroundCall(method: 'unsupported')),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('rejects an unresolved callback handle', () async {
      await expectLater(
        handleRadarBackgroundMethodCall(
          _backgroundCall(),
          callbackResolver: (_) => null,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects a callback with the wrong signature', () async {
      await expectLater(
        handleRadarBackgroundMethodCall(
          _backgroundCall(),
          callbackResolver: (_) => (String value) {},
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('propagates callback failures', () async {
      final error = StateError('Callback failed');

      await expectLater(
        handleRadarBackgroundMethodCall(
          _backgroundCall(),
          callbackResolver: (_) {
            return (RadarBackgroundEvent event) async {
              throw error;
            };
          },
        ),
        throwsA(same(error)),
      );
    });
  });
}
