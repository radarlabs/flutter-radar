import 'package:flutter/services.dart';

const _channel = MethodChannel('io.radar.example/e2e');

/// Points the Radar SDK at [host] and [verifiedHost] by writing the storage
/// keys the native SDKs read on every request. Empty values clear the
/// override, so the SDK uses production. Call before `Radar.initialize`.
///
/// Implemented in the example app only (AppDelegate.m, MainActivity.java).
Future<void> setRadarHosts({
  required String host,
  required String verifiedHost,
}) {
  return _channel.invokeMethod<void>('setHosts', {
    'host': host,
    'verifiedHost': verifiedHost,
  });
}
