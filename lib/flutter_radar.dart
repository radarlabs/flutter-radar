import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

@pragma('vm:entry-point')
void callbackDispatcher() {
  const MethodChannel _backgroundChannel =
      MethodChannel('flutter_radar_background');
  WidgetsFlutterBinding.ensureInitialized();

  _backgroundChannel.setMethodCallHandler((MethodCall call) async {
    final args = call.arguments;
    final CallbackHandle handle = CallbackHandle.fromRawHandle(args[0]);
    final Function? callback = PluginUtilities.getCallbackFromHandle(handle);
    final Map res = args[1];

    callback?.call(res);
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

  static attachListeners() async {
    try {
      await _channel.invokeMethod('attachListeners', {
        'callbackDispatcherHandle':
            PluginUtilities.getCallbackHandle(callbackDispatcher)?.toRawHandle()
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

  static Future setAnonymousTrackingEnabled(bool enabled) async {
    try {
      await _channel
          .invokeMethod('setAnonymousTrackingEnabled', {'enabled': enabled});
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

  static Future<Map?> trackOnce(
      {Map<String, dynamic>? location,
      String? desiredAccuracy,
      bool? beacons}) async {
    try {
      return await _channel.invokeMethod('trackOnce', {
        'location': location,
        'desiredAccuracy': desiredAccuracy,
        'beacons': beacons
      });
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

  static Future startTrackingVerified(int interval, bool beacons) async {
    try {
      await _channel.invokeMethod('startTrackingVerified',
          {'interval': interval, 'beacons': beacons});
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

  static Future stopTrackingVerified() async {
    try {
      await _channel.invokeMethod('stopTrackingVerified');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<bool?> isTracking() async {
    return await _channel.invokeMethod('isTracking');
  }

  static Future<Map?> getTrackingOptions() async {
    try {
      return await _channel.invokeMethod('getTrackingOptions');
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
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

  static Future<Map?> startTrip(
      {Map<String, dynamic>? tripOptions,
      Map<String, dynamic>? trackingOptions}) async {
    try {
      return await _channel.invokeMethod('startTrip',
          {'tripOptions': tripOptions, 'trackingOptions': trackingOptions});
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future<Map?> updateTrip(
      {required Map<String, dynamic> options, required String status}) async {
    try {
      return await _channel.invokeMethod(
          'updateTrip', {'tripOptions': options, 'status': status});
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future<Map?> getTripOptions() async {
    return await _channel.invokeMethod('getTripOptions');
  }

  static Future<Map?> completeTrip() async {
    try {
      return await _channel.invokeMethod('completeTrip');
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future<Map?> cancelTrip() async {
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
      int? limit,
      bool? includeGeometry}) async {
    try {
      return await _channel.invokeMethod('searchGeofences', <String, dynamic>{
        'near': near,
        'radius': radius,
        'limit': limit,
        'tags': tags,
        'metadata': metadata,
        'includeGeometry': includeGeometry
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
      Map<String, String>? chainMetadata,
      List? categories,
      List? groups}) async {
    try {
      return await _channel.invokeMethod('searchPlaces', {
        'near': near,
        'radius': radius,
        'limit': limit,
        'chains': chains,
        'chainMetadata': chainMetadata,
        'categories': categories,
        'groups': groups
      });
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future<Map?> autocomplete(
      {String? query,
      Map<String, dynamic>? near,
      int? limit,
      String? country,
      List? layers,
      bool? mailable}) async {
    try {
      return await _channel.invokeMethod('autocomplete', {
        'query': query,
        'near': near,
        'limit': limit,
        'country': country,
        'layers': layers,
        'mailable': mailable
      });
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

  static Future<Map?> logConversion(
      {required String name,
      double? revenue,
      required Map<String, dynamic> metadata}) async {
    try {
      return await _channel.invokeMethod('logConversion',
          {'name': name, 'revenue': revenue, 'metadata': metadata});
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  // iOS only
  static Future logTermination() async {
    try {
      await _channel.invokeMethod('logTermination');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future logBackgrounding() async {
    try {
      await _channel.invokeMethod('logBackgrounding');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future logResigningActive() async {
    try {
      await _channel.invokeMethod('logResigningActive');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  // Android only
  static Future setNotificationOptions(
      Map<String, dynamic> notificationOptions) async {
    try {
      await _channel.invokeMethod(
          'setNotificationOptions', notificationOptions);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<Map?> getMatrix(
      {required List origins,
      required List destinations,
      required String mode,
      required String units}) async {
    try {
      return await _channel.invokeMethod('getMatrix', {
        'origins': origins,
        'destinations': destinations,
        'mode': mode,
        'units': units
      });
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future setForegroundServiceOptions(
      Map<String, dynamic> foregroundServiceOptions) async {
    try {
      await _channel.invokeMethod(
          'setForegroundServiceOptions', foregroundServiceOptions);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<Map?> trackVerified({bool? beacons}) async {
    try {
      return await _channel.invokeMethod('trackVerified', {'beacons': beacons});
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future<bool?> isUsingRemoteTrackingOptions() async {
    return await _channel.invokeMethod('isUsingRemoteTrackingOptions');
  }

  static Future<Map?> validateAddress(Map address) async {
    try {
      return await _channel
          .invokeMethod('validateAddress', {'address': address});
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static Future requestForegroundLocationPermission() async {
    try {
      await _channel.invokeMethod('requestForegroundLocationPermission');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future requestBackgroundLocationPermission() async {
    try {
      await _channel.invokeMethod('requestBackgroundLocationPermission');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<Map?> getLocationPermissionStatus() async {
    try {
      return await _channel.invokeMethod('getLocationPermissionStatus');
    } on PlatformException catch (e) {
      print(e);
      return {'error': e.code};
    }
  }

  static onLocation(Function(Map res) callback) async {
    try {
      final CallbackHandle handle =
          PluginUtilities.getCallbackHandle(callback)!;
      await _channel.invokeMethod('on',
          {'listener': 'location', 'callbackHandle': handle.toRawHandle()});
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
      final CallbackHandle handle =
          PluginUtilities.getCallbackHandle(callback)!;
      await _channel.invokeMethod('on', {
        'listener': 'clientLocation',
        'callbackHandle': handle.toRawHandle()
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
      final CallbackHandle handle =
          PluginUtilities.getCallbackHandle(callback)!;
      await _channel.invokeMethod(
          'on', {'listener': 'error', 'callbackHandle': handle.toRawHandle()});
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
      final CallbackHandle handle =
          PluginUtilities.getCallbackHandle(callback)!;
      await _channel.invokeMethod(
          'on', {'listener': 'log', 'callbackHandle': handle.toRawHandle()});
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

  static onEvents(Function(Map res) callback) async {
    try {
      final CallbackHandle handle =
          PluginUtilities.getCallbackHandle(callback)!;
      await _channel.invokeMethod(
          'on', {'listener': 'events', 'callbackHandle': handle.toRawHandle()});
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

  static onToken(Function(Map res) callback) async {
    try {
      final CallbackHandle handle =
          PluginUtilities.getCallbackHandle(callback)!;
      await _channel.invokeMethod(
          'on', {'listener': 'token', 'callbackHandle': handle.toRawHandle()});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static offToken() async {
    try {
      await _channel.invokeMethod('off', {'listener': 'token'});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static onLocationPermissionStatus(Function(Map res) callback) async {
    try {
      final CallbackHandle handle =
          PluginUtilities.getCallbackHandle(callback)!;
      await _channel.invokeMethod(
          'on', {'listener': 'locationPermissionStatus', 'callbackHandle': handle.toRawHandle()});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static offLocationPermissionStatus() async {
    try {
      await _channel.invokeMethod('off', {'listener': 'locationPermissionStatus'});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Map<String, dynamic> presetContinuousIOS = {
  "desiredStoppedUpdateInterval": 30,
  "desiredMovingUpdateInterval": 30,
  "desiredSyncInterval": 20,
  "desiredAccuracy":'high',
  "stopDuration": 140,
  "stopDistance": 70,
  "replay": 'none',
  "useStoppedGeofence": false,
  "showBlueBar": true,
  "startTrackingAfter": null,
  "stopTrackingAfter": null,
  "stoppedGeofenceRadius": 0,
  "useMovingGeofence": false,
  "movingGeofenceRadius": 0,
  "syncGeofences": true,
  "useVisits": false,
  "useSignificantLocationChanges": false,
  "beacons": false,
  "sync": 'all',
};

  static Map<String, dynamic> presetContinuousAndroid =  {
  "desiredStoppedUpdateInterval": 30,
  "fastestStoppedUpdateInterval": 30,
  "desiredMovingUpdateInterval": 30,
  "fastestMovingUpdateInterval": 30,
  "desiredSyncInterval": 20,
  "desiredAccuracy": 'high',
  "stopDuration": 140,
  "stopDistance": 70,
  "replay": 'none',
  "sync": 'all',
  "useStoppedGeofence": false,
  "stoppedGeofenceRadius": 0,
  "useMovingGeofence": false,
  "movingGeofenceRadius": 0,
  "syncGeofences": true,
  "syncGeofencesLimit": 0,
  "foregroundServiceEnabled": true,
  "beacons": false,
  "startTrackingAfter": null,
  "stopTrackingAfter": null,
};

  static Map<String, dynamic> presetResponsiveIOS = {
    "desiredStoppedUpdateInterval": 0,
    "desiredMovingUpdateInterval": 150,
    "desiredSyncInterval": 20,
    "desiredAccuracy": 'medium',
    "stopDuration": 140,
    "stopDistance": 70,
    "replay": 'stops',
    "useStoppedGeofence": true,
    "showBlueBar": false,
    "startTrackingAfter": null,
    "stopTrackingAfter": null,
    "stoppedGeofenceRadius": 100,
    "useMovingGeofence": true,
    "movingGeofenceRadius": 100,
    "syncGeofences": true,
    "useVisits": true,
    "useSignificantLocationChanges": true,
    "beacons": false,
    "sync": 'all',
  };

  static Map<String, dynamic> presetResponsiveAndroid = {
    "desiredStoppedUpdateInterval": 0,
    "fastestStoppedUpdateInterval": 0,
    "desiredMovingUpdateInterval": 150,
    "fastestMovingUpdateInterval": 30,
    "desiredSyncInterval": 20,
    "desiredAccuracy": "medium",
    "stopDuration": 140,
    "stopDistance": 70,
    "replay": 'stops',
    "sync": 'all',
    "useStoppedGeofence": true,
    "stoppedGeofenceRadius": 100,
    "useMovingGeofence": true,
    "movingGeofenceRadius": 100,
    "syncGeofences": true,
    "syncGeofencesLimit": 10,
    "foregroundServiceEnabled": false,
    "beacons": false,
    "startTrackingAfter": null,
    "stopTrackingAfter": null,
  };

  static Map<String, dynamic> presetEfficientIOS = {
  "desiredStoppedUpdateInterval": 0,
  "desiredMovingUpdateInterval": 0,
  "desiredSyncInterval": 0,
  "desiredAccuracy": "medium",
  "stopDuration": 0,
  "stopDistance": 0,
  "replay": 'stops',
  "useStoppedGeofence": false,
  "showBlueBar": false,
  "startTrackingAfter": null,
  "stopTrackingAfter": null,
  "stoppedGeofenceRadius": 0,
  "useMovingGeofence": false,
  "movingGeofenceRadius": 0,
  "syncGeofences": true,
  "useVisits": true,
  "useSignificantLocationChanges": false,
  "beacons": false,
  "sync": 'all',
};

  static Map<String, dynamic> presetEfficientAndroid ={
  "desiredStoppedUpdateInterval": 3600,
  "fastestStoppedUpdateInterval": 1200,
  "desiredMovingUpdateInterval": 1200,
  "fastestMovingUpdateInterval": 360,
  "desiredSyncInterval": 140,
  "desiredAccuracy": 'medium',
  "stopDuration": 140,
  "stopDistance": 70,
  "replay": 'stops',
  "sync": 'all',
  "useStoppedGeofence": false,
  "stoppedGeofenceRadius": 0,
  "useMovingGeofence": false,
  "movingGeofenceRadius": 0,
  "syncGeofences": true,
  "syncGeofencesLimit": 10,
  "foregroundServiceEnabled": false,
  "beacons": false,
  "startTrackingAfter": null,
  "stopTrackingAfter": null,
};

  static Map<String, dynamic> presetResponsive =
      Platform.isIOS ? presetResponsiveIOS : presetResponsiveAndroid;
  static Map<String, dynamic> presetContinuous =
      Platform.isIOS ? presetContinuousIOS : presetContinuousAndroid;
    static Map<String, dynamic> presetEfficient=
      Platform.isIOS ? presetEfficientIOS : presetEfficientAndroid;
}
