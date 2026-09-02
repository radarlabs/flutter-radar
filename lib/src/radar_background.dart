import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The Radar callback represented by a [RadarBackgroundEvent].
enum RadarBackgroundEventType {
  /// A location update corresponding to `Radar.onLocation`.
  location,

  /// A client location update corresponding to `Radar.onClientLocation`.
  clientLocation,

  /// An events update corresponding to `Radar.onEvents`.
  events,

  /// An SDK error corresponding to `Radar.onError`.
  error,

  /// An SDK log message corresponding to `Radar.onLog`.
  log,

  /// A verified-location token corresponding to `Radar.onToken`.
  token,

  /// An IP address change corresponding to `Radar.onIpChanged`.
  ipChanged,

  /// A location-sharing change corresponding to `Radar.onSharingChanged`.
  sharingChanged,
}

/// An event delivered to the durable Radar background handler.
///
/// The [payload] uses the same map shape as the corresponding `Radar.onX`
/// listener. For [RadarBackgroundEventType.ipChanged], the payload is empty.
/// For [RadarBackgroundEventType.sharingChanged], it contains a `sharing`
/// boolean.
final class RadarBackgroundEvent {
  const RadarBackgroundEvent({required this.type, required this.payload});

  /// Identifies the Radar callback that produced this event.
  final RadarBackgroundEventType type;

  /// The event data supplied by the native Radar SDK.
  final Map<String, dynamic> payload;
}

/// A durable Radar event handler that can run in a primary or headless isolate.
///
/// Implementations must be top-level or static functions annotated with
/// `@pragma('vm:entry-point')`.
typedef RadarBackgroundHandler =
    Future<void> Function(RadarBackgroundEvent event);

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

  late final RadarBackgroundEventType eventType;
  try {
    eventType = RadarBackgroundEventType.values.byName(call.method);
  } on ArgumentError {
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
      'RadarBackgroundEvent.',
    );
  }

  final event = RadarBackgroundEvent(
    type: eventType,
    payload: Map<String, dynamic>.from(rawPayload),
  );

  await callback(event);
}
