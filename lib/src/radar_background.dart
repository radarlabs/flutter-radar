import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'models/radar_update.dart';

/// A durable Radar event handler that can run in a primary or headless isolate.
///
/// Implementations must be top-level or static functions annotated with
/// `@pragma('vm:entry-point')`.
typedef RadarBackgroundHandler = Future<void> Function(RadarUpdate update);

typedef RadarBackgroundCallbackResolver =
    Function? Function(CallbackHandle handle);

const MethodChannel _backgroundChannel = MethodChannel(
  'flutter_radar_background',
);

@pragma('vm:entry-point')
void radarBackgroundCallbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();

  installRadarBackgroundMethodCallHandler();
  unawaited(_backgroundChannel.invokeMethod<void>('initialized'));
}

void installRadarBackgroundMethodCallHandler() {
  _backgroundChannel.setMethodCallHandler(handleRadarBackgroundMethodCall);
}

void removeRadarBackgroundMethodCallHandler() {
  _backgroundChannel.setMethodCallHandler(null);
}

Future<void> handleRadarBackgroundMethodCall(
  MethodCall call, {
  RadarBackgroundCallbackResolver? callbackResolver,
}) async {
  final rawArguments = call.arguments;
  if (rawArguments is! Map) {
    throw ArgumentError.value(
      rawArguments,
      'call.arguments',
      'Background callback arguments must be a map.',
    );
  }

  final arguments = Map<Object?, Object?>.from(rawArguments);
  final rawCallbackHandle = arguments['callbackHandle'];
  if (rawCallbackHandle is! int) {
    throw ArgumentError.value(
      rawCallbackHandle,
      'callbackHandle',
      'Background callback handle must be an integer.',
    );
  }

  final rawPayload = arguments['payload'];
  if (rawPayload is! Map) {
    throw ArgumentError.value(
      rawPayload,
      'payload',
      'Background callback payload must be a map.',
    );
  }

  final update = RadarUpdate.fromMethodCall(
    call.method,
    rawPayload.cast<Object?, Object?>(),
  );
  if (update == null) {
    throw UnsupportedError(
      'Unsupported Radar background event: ${call.method}',
    );
  }

  final resolver = callbackResolver ?? PluginUtilities.getCallbackFromHandle;
  final callback = resolver(CallbackHandle.fromRawHandle(rawCallbackHandle));

  if (callback == null) {
    throw StateError('Could not resolve Radar background callback handle.');
  }

  if (callback is! RadarBackgroundHandler) {
    throw StateError(
      'Radar background callback must return Future<void> and accept a '
      'RadarUpdate.',
    );
  }

  await callback(update);
}
