import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void callbackDispatcher() {
  const MethodChannel _backgroundChannel =
      MethodChannel('flutter_radar_background');

  WidgetsFlutterBinding.ensureInitialized();

  _backgroundChannel.setMethodCallHandler((MethodCall call) async {
    final args = call.arguments;

    final Function callback = PluginUtilities.getCallbackFromHandle(
        CallbackHandle.fromRawHandle(args[0]));
    assert(callback != null);

    final Map res = args[1].cast<Map>();

    callback(res);
  });
}

class Radar {
  static const MethodChannel _channel = const MethodChannel('flutter_radar');

  static Future initialize(String publishableKey) async {
    try {
      await _channel.invokeMethod('initialize', {
        'publishableKey': publishableKey,
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future setLogLevel(String logLevel) async {
    try {
      await _channel.invokeMethod('setLogLevel', {'logLevel': logLevel});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<String> getPermissionsStatus() async {
    final String permissionsStatus =
        await _channel.invokeMethod('getPermissionsStatus');
    return permissionsStatus;
  }

  static Future requestPermissions(bool background) async {
    try {
      await _channel
          .invokeMethod('requestPermissions', {'background': background});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future setUserId(String userId) async {
    try {
      await _channel.invokeMethod('setUserId', {'userId': userId});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<String> getUserId() async {
    final String userId = await _channel.invokeMethod('getUserId');
    return userId;
  }

  static Future setDescription(String description) async {
    try {
      await _channel
          .invokeMethod('setDescription', {'description': description});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<String> getDescription() async {
    final String description = await _channel.invokeMethod('getDescription');
    return description;
  }

  static Future setMetadata(Map<String, dynamic> metadata) async {
    try {
      await _channel.invokeMethod('setMetadata', metadata);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<Map> getMetadata() async {
    final Map metadata = await _channel.invokeMethod('getMetadata');
    return metadata;
  }

  static Future setAdIdEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setAdIdEnabled', {'enabled': enabled});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<Map> getLocation([String accuracy]) async {
    try {
      final Map res =
          await _channel.invokeMethod('getLocation', {'accuracy': accuracy});
      return res;
    } on PlatformException catch (e) {
      print(e);
      Map<String, String> err = {'error': e.code};
      return err;
    }
  }

  static Future<Map> trackOnce([Map<String, dynamic> location]) async {
    try {
      if (location == null) {
        final Map trackOnceResult = await _channel.invokeMethod('trackOnce');
        return trackOnceResult;
      } else {
        final Map trackOnceResult =
            await _channel.invokeMethod('trackOnce', {'location': location});
        return trackOnceResult;
      }
    } on PlatformException catch (e) {
      print(e);
      Map<String, String> trackError = {'error': e.code};
      return trackError;
    }
  }

  static Future startTracking(String preset) async {
    try {
      await _channel.invokeMethod('startTracking', {
        'preset': preset,
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future startTrackingCustom(Map<String, dynamic> options) async {
    try {
      await _channel.invokeMethod('startTrackingCustom', options);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future stopTracking() async {
    try {
      await _channel.invokeMethod('stopTracking');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<bool> isTracking() async {
    final bool isTracking = await _channel.invokeMethod('isTracking');
    return isTracking;
  }

  static Future<Map> mockTracking(
      {Map<String, double> origin,
      Map<String, double> destination,
      String mode,
      int steps,
      int interval}) async {
    try {
      final Map res = await _channel.invokeMethod('mockTracking', {
        'origin': origin,
        'destination': destination,
        'mode': mode,
        'steps': steps,
        'interval': interval
      });
      return res;
    } on PlatformException catch (e) {
      print(e);
      Map<String, String> err = {'error': e.code};
      return err;
    }
  }

  static Future startTrip(Map<String, dynamic> tripOptions) async {
    try {
      await _channel.invokeMethod('startTrip', tripOptions);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<Map> getTripOptions() async {
    final Map res = await _channel.invokeMethod('getTripOptions');
    return res;
  }

  static Future completeTrip() async {
    try {
      await _channel.invokeMethod('completeTrip');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future cancelTrip() async {
    try {
      await _channel.invokeMethod('cancelTrip');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<Map> getContext(Map<String, dynamic> location) async {
    try {
      final Map res =
          await _channel.invokeMethod('getContext', {'location': location});
      return res;
    } on PlatformException catch (e) {
      print(e);
      Map<String, String> err = {'error': e.code};
      return err;
    }
  }

  static Future<Map> searchGeofences(
      {Map<String, dynamic> near,
      int radius,
      List tags,
      Map<String, dynamic> metadata,
      int limit}) async {
    try {
      final Map res =
          await _channel.invokeMethod('searchGeofences', <String, dynamic>{
        'near': near,
        'radius': radius,
        'limit': limit,
        'tags': tags,
        'metadata': metadata
      });
      return res;
    } on PlatformException catch (e) {
      print(e);
      Map<String, String> err = {'error': e.code};
      return err;
    }
  }

  static Future<Map> searchPlaces(
      {Map<String, dynamic> near,
      int radius,
      int limit,
      List chains,
      List categories,
      List groups}) async {
    try {
      final Map res = await _channel.invokeMethod('searchPlaces', {
        'near': near,
        'radius': radius,
        'limit': limit,
        'chains': chains,
        'catgories': categories,
        'groups': groups
      });
      return res;
    } on PlatformException catch (e) {
      print(e);
      Map<String, String> err = {'error': e.code};
      return err;
    }
  }

  static Future<Map> autocomplete(
      {String query, Map<String, dynamic> near, int limit}) async {
    try {
      final Map res = await _channel.invokeMethod(
          'autocomplete', {'query': query, 'near': near, 'limit': limit});
      return res;
    } on PlatformException catch (e) {
      print(e);
      Map<String, String> err = {'error': e.code};
      return err;
    }
  }

  static Future<Map> geocode(String query) async {
    try {
      final Map geocodeResult =
          await _channel.invokeMethod('forwardGeocode', {'query': query});
      return geocodeResult;
    } on PlatformException catch (e) {
      print(e);
      Map<String, String> geocodeError = {'error': e.code};
      return geocodeError;
    }
  }

  static Future<Map> reverseGeocode(Map<String, dynamic> location) async {
    try {
      final Map res =
          await _channel.invokeMethod('reverseGeocode', {'location': location});
      return res;
    } on PlatformException catch (e) {
      print(e);
      Map<String, String> err = {'error': e.code};
      return err;
    }
  }

  static Future<Map> ipGeocode() async {
    try {
      final Map res = await _channel.invokeMethod('ipGeocode');
      return res;
    } on PlatformException catch (e) {
      print(e);
      Map<String, String> err = {'error': e.code};
      return err;
    }
  }

  static Future<Map> getDistance(
      {Map<String, double> origin,
      Map<String, double> destination,
      List modes,
      String units}) async {
    try {
      final Map res = await _channel.invokeMethod('getDistance', {
        'origin': origin,
        'destination': destination,
        'modes': modes,
        'units': units
      });
      return res;
    } on PlatformException catch (e) {
      print(e);
      Map<String, String> err = {'error': e.code};
      return err;
    }
  }

  static Future startForegroundService(
      Map<String, String> foregroundServiceOptions) async {
    try {
      await _channel.invokeMethod(
          'startForegroundService', foregroundServiceOptions);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future stopForegroundService() async {
    try {
      await _channel.invokeMethod('stopForegroundService');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static attachListeners() async {
    try {
      await _channel.invokeMethod('attachListeners', {
        'callbackDispatcherHandle':
            PluginUtilities.getCallbackHandle(callbackDispatcher).toRawHandle()
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future detachListeners() async {
    try {
      await _channel.invokeMethod('detachListeners');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static onEvents(Function(Map res) callback) async {
    try {
      await _channel.invokeMethod('on', {
        'listener': 'events',
        'callbackHandle':
            PluginUtilities.getCallbackHandle(callback).toRawHandle()
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static offEvents() async {
    try {
      await _channel.invokeMethod('off', {'listener': 'events'});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static onLocation(Function(Map res) callback) async {
    try {
      await _channel.invokeMethod('on', {
        'listener': 'location',
        'callbackHandle':
            PluginUtilities.getCallbackHandle(callback).toRawHandle()
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static offLocation() async {
    try {
      await _channel.invokeMethod('off', {'listener': 'location'});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static onClientLocation(Function(Map res) callback) async {
    try {
      await _channel.invokeMethod('on', {
        'listener': 'clientLocation',
        'callbackHandle':
            PluginUtilities.getCallbackHandle(callback).toRawHandle()
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static offClientLocation() async {
    try {
      await _channel.invokeMethod('off', {'listener': 'clientLocation'});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static onError(Function(Map res) callback) async {
    try {
      await _channel.invokeMethod('on', {
        'listener': 'error',
        'callbackHandle':
            PluginUtilities.getCallbackHandle(callback).toRawHandle()
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static offError() async {
    try {
      await _channel.invokeMethod('off', {'listener': 'error'});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static onLog(Function(Map res) callback) async {
    try {
      await _channel.invokeMethod('on', {
        'listener': 'log',
        'callbackHandle':
            PluginUtilities.getCallbackHandle(callback).toRawHandle()
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static offLog() async {
    try {
      await _channel.invokeMethod('off', {'listener': 'log'});
    } on PlatformException catch (e) {
      print(e);
    }
  }
}
