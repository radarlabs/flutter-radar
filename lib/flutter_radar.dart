import 'dart:async';
import 'package:flutter/services.dart';

class Radar {
  static const MethodChannel _channel = const MethodChannel('flutter_radar');

  static const EventChannel _eventsChannel =
      const EventChannel('flutter_radar/events');
  static const EventChannel _locationChannel =
      const EventChannel('flutter_radar/location');
  static const EventChannel _clientLocationChannel =
      const EventChannel('flutter_radar/clientLocation');
  static const EventChannel _errorChannel =
      const EventChannel('flutter_radar/error');
  static const EventChannel _logChannel =
      const EventChannel('flutter_radar/log');

  static Function(Map? res)? _eventsCallback;
  static Function(Map? res)? _locationCallback;
  static Function(Map? res)? _clientLocationCallback;
  static Function(Map? res)? _errorCallback;
  static Function(Map? res)? _logCallback;

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

  static Future<String?> getPermissionsStatus() async {
    return await _channel.invokeMethod('getPermissionsStatus');
  }

  static Future requestPermissions(bool background) async {
    try {
      return await _channel
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

  static Future<String?> getUserId() async {
    return await _channel.invokeMethod('getUserId');
  }

  static Future setDescription(String description) async {
    try {
      await _channel
          .invokeMethod('setDescription', {'description': description});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<String?> getDescription() async {
    return await _channel.invokeMethod('getDescription');
  }

  static Future setMetadata(Map<String, dynamic> metadata) async {
    try {
      await _channel.invokeMethod('setMetadata', metadata);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<Map?> getMetadata() async {
    return await _channel.invokeMethod('getMetadata');
  }

  static Future setAdIdEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setAdIdEnabled', {'enabled': enabled});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<Map?> getLocation([String? accuracy]) async {
    try {
      return await _channel.invokeMethod('getLocation', {'accuracy': accuracy});
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future<Map?> trackOnce([Map<String, dynamic>? location]) async {
    try {
      if (location == null) {
        return await _channel.invokeMethod('trackOnce');
      } else {
        return await _channel.invokeMethod('trackOnce', {'location': location});
      }
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
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

  static Future<bool?> isTracking() async {
    return await _channel.invokeMethod('isTracking');
  }

  static Future<Map?> mockTracking(
      {Map<String, double>? origin,
      Map<String, double>? destination,
      String? mode,
      int? steps,
      int? interval}) async {
    try {
      return await _channel.invokeMethod('mockTracking', {
        'origin': origin,
        'destination': destination,
        'mode': mode,
        'steps': steps,
        'interval': interval
      });
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future startTrip(Map<String, dynamic> tripOptions) async {
    try {
      return await _channel.invokeMethod('startTrip', tripOptions);
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future<Map?> getTripOptions() async {
    return await _channel.invokeMethod('getTripOptions');
  }

  static Future completeTrip() async {
    try {
      return await _channel.invokeMethod('completeTrip');
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future cancelTrip() async {
    try {
      return await _channel.invokeMethod('cancelTrip');
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future<Map?> getContext(Map<String, dynamic> location) async {
    try {
      return await _channel.invokeMethod('getContext', {'location': location});
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future<Map?> searchGeofences(
      {Map<String, dynamic>? near,
      int? radius,
      List? tags,
      Map<String, dynamic>? metadata,
      int? limit}) async {
    try {
      return await _channel.invokeMethod('searchGeofences', <String, dynamic>{
        'near': near,
        'radius': radius,
        'limit': limit,
        'tags': tags,
        'metadata': metadata
      });
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future<Map?> searchPlaces(
      {Map<String, dynamic>? near,
      int? radius,
      int? limit,
      List? chains,
      List? categories,
      List? groups}) async {
    try {
      return await _channel.invokeMethod('searchPlaces', {
        'near': near,
        'radius': radius,
        'limit': limit,
        'chains': chains,
        'categories': categories,
        'groups': groups
      });
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future<Map?> autocomplete(
      {String? query, Map<String, dynamic>? near, int? limit}) async {
    try {
      return await _channel.invokeMethod(
          'autocomplete', {'query': query, 'near': near, 'limit': limit});
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future<Map?> geocode(String query) async {
    try {
      final Map? geocodeResult =
          await _channel.invokeMethod('forwardGeocode', {'query': query});
      return geocodeResult;
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future<Map?> reverseGeocode(Map<String, dynamic> location) async {
    try {
      return await _channel
          .invokeMethod('reverseGeocode', {'location': location});
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future<Map?> ipGeocode() async {
    try {
      return await _channel.invokeMethod('ipGeocode');
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future<Map?> getDistance(
      {Map<String, double>? origin,
      Map<String, double>? destination,
      List? modes,
      String? units}) async {
    try {
      return await _channel.invokeMethod('getDistance', {
        'origin': origin,
        'destination': destination,
        'modes': modes,
        'units': units
      });
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future startForegroundService(
      Map<String, dynamic> foregroundServiceOptions) async {
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

  static onEvents(Function(Map<dynamic, dynamic>? result) callback) {
    _eventsCallback = callback;
    _eventsChannel.receiveBroadcastStream().listen((data) {
      if (_eventsCallback != null) {
        _eventsCallback!(data);
      }
    });
  }

  static offEvents() {
    _eventsCallback = null;
  }

  static onLocation(Function(Map<dynamic, dynamic>? result) callback) {
    _locationCallback = callback;
    _locationChannel.receiveBroadcastStream().listen((data) {
      if (_locationCallback != null) {
        _locationCallback!(data);
      }
    });
  }

  static offLocation() {
    _locationCallback = null;
  }

  static onClientLocation(Function(Map<dynamic, dynamic>? result) callback) {
    _clientLocationCallback = callback;
    _clientLocationChannel.receiveBroadcastStream().listen((data) {
      if (_clientLocationCallback != null) {
        _clientLocationCallback!(data);
      }
    });
  }

  static offClientLocation() {
    _clientLocationCallback = null;
  }

  static onError(Function(Map<dynamic, dynamic>? result) callback) {
    _errorCallback = callback;
    _errorChannel.receiveBroadcastStream().listen((data) {
      if (_errorCallback != null) {
        _errorCallback!(data);
      }
    });
  }

  static offError() {
    _errorCallback = null;
  }

  static onLog(Function(Map<dynamic, dynamic>? result) callback) {
    _logCallback = callback;
    _logChannel.receiveBroadcastStream().listen((data) {
      if (_logCallback != null) {
        _logCallback!(data);
      }
    });
  }

  static offLog() {
    _logCallback = null;
  }
}
