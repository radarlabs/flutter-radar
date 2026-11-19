import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/models/parsing.dart';
import 'src/models/radar_address.dart';
import 'src/models/radar_event.dart';
import 'src/models/radar_reveal_risk_token.dart';
import 'src/models/radar_routes.dart';
import 'src/models/radar_verified_location_token.dart';
import 'src/models/radar_enums.dart';
import 'src/models/radar_exception.dart';
import 'src/models/radar_foreground_service_options.dart';
import 'src/models/radar_in_app_message.dart';
import 'src/models/radar_location.dart';
import 'src/models/radar_notification_options.dart';
import 'src/models/radar_results.dart';
import 'src/models/radar_status.dart';
import 'src/models/radar_tracking_options.dart';
import 'src/models/radar_trip.dart';
import 'src/models/radar_update.dart';
import 'src/radar_background.dart';

export 'src/models/models.dart';
export 'src/radar_background.dart' show RadarBackgroundHandler;

/// The Radar SDK.
///
/// Methods that make a request, such as [trackOnce] or [searchPlaces], throw
/// a [RadarException] with a [RadarStatus] when the request fails. Any
/// location the SDK obtains along the way is still delivered to
/// [onClientLocation] and the background handler, even if the request then
/// fails.
///
/// A failure in the plugin itself, such as a native error, throws a
/// `PlatformException`. Errors from background tracking, where nothing is
/// awaiting a result, are delivered to [onError] and the background handler.
class Radar {
  static const MethodChannel _channel = const MethodChannel('flutter_radar');

  static void Function(RadarLocationUpdate update)? _onLocation;
  static void Function(RadarClientLocationUpdate update)? _onClientLocation;
  static void Function(RadarErrorUpdate update)? _onError;
  static void Function(RadarLogUpdate update)? _onLog;
  static void Function(RadarEventsUpdate update)? _onEvents;
  static void Function(RadarTokenUpdate update)? _onToken;
  static void Function(RadarIpChangedUpdate update)? _onIpChanged;
  static void Function(RadarSharingChangedUpdate update)? _onSharingChanged;

  /// Invokes [method] and parses its map result with [fromMap].
  ///
  /// Throws a [RadarException] if the native SDK reports a status other than
  /// [RadarStatus.success].
  static Future<T> _request<T>(
    String method,
    Map<String, Object?>? arguments,
    T Function(ChannelMap map) fromMap,
  ) async {
    final result =
        await _channel.invokeMapMethod<Object?, Object?>(
          method,
          _arguments(arguments),
        ) ??
        const {};
    final status = RadarStatus.fromWire(result['status']);
    if (!status.isSuccess) throw RadarException(status);
    return fromMap(result);
  }

  /// Invokes [method], leaving out arguments that are null.
  static Future<T?> _invoke<T>(
    String method, [
    Map<String, Object?>? arguments,
  ]) => _channel.invokeMethod<T>(method, _arguments(arguments));

  /// Removes null-valued arguments. Several bridge handlers check only
  /// whether an argument is present (Android `call.hasArgument`, iOS
  /// `argsDict[key]`, which is `NSNull` for null), so a null argument would
  /// skip their defaults and pass null on to the native SDK.
  static Map<String, Object?>? _arguments(Map<String, Object?>? arguments) =>
      arguments == null ? null : compact({...arguments});

  /// Returns [value], or throws [RadarException] with
  /// [RadarStatus.errorServer] if a successful response is missing it, which
  /// is what the native SDKs do when they can't parse a response.
  static T _require<T>(T? value) =>
      value ?? (throw const RadarException(RadarStatus.errorServer));

  static List<RadarAddress> _addresses(ChannelMap map) =>
      readList(map['addresses'], RadarAddress.fromMap);

  static RadarVerifiedLocationToken _token(ChannelMap map) =>
      _require(readObject(map['token'], RadarVerifiedLocationToken.fromMap));

  static Future<void> initialize(
    String publishableKey, {
    RadarInitializeOptions? options,
  }) async {
    await _invoke<void>('initialize', {
      'publishableKey': publishableKey,
      if (options != null) 'options': options.toMap(),
    });
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    final args = call.arguments;
    final payload = args is List && args.length > 1 ? readMap(args[1]) : null;
    final update = RadarUpdate.fromMethodCall(call.method, payload ?? const {});
    switch (update) {
      case RadarLocationUpdate():
        _onLocation?.call(update);
      case RadarClientLocationUpdate():
        _onClientLocation?.call(update);
      case RadarErrorUpdate():
        _onError?.call(update);
      case RadarLogUpdate():
        _onLog?.call(update);
      case RadarEventsUpdate():
        _onEvents?.call(update);
      case RadarTokenUpdate():
        _onToken?.call(update);
      case RadarIpChangedUpdate():
        _onIpChanged?.call(update);
      case RadarSharingChangedUpdate():
        _onSharingChanged?.call(update);
      case null:
        break;
    }
  }

  static Future<void> setLogLevel(RadarLogLevel logLevel) async {
    await _invoke<void>('setLogLevel', {'logLevel': logLevel.wireValue});
  }

  static Future<RadarPermissionsStatus> getPermissionsStatus() async {
    return RadarPermissionsStatus.fromWire(
      await _invoke<String>('getPermissionsStatus'),
    );
  }

  static Future<void> requestPermissions(bool background) async {
    await _invoke<void>('requestPermissions', {'background': background});
  }

  static Future<void> setUserId(String userId) async {
    await _invoke<void>('setUserId', {'userId': userId});
  }

  static Future<String?> getUserId() async {
    return await _invoke('getUserId');
  }

  static Future<void> setDescription(String description) async {
    await _invoke<void>('setDescription', {'description': description});
  }

  static Future<String?> getDescription() async {
    return await _invoke('getDescription');
  }

  static Future<void> setMetadata(Map<String, dynamic> metadata) async {
    await _channel.invokeMethod('setMetadata', metadata);
  }

  static Future<Map<String, Object?>?> getMetadata() async {
    return readJson(await _invoke('getMetadata'));
  }

  static Future<void> setAnonymousTrackingEnabled(bool enabled) async {
    await _invoke<void>('setAnonymousTrackingEnabled', {'enabled': enabled});
  }

  static Future<RadarLocationResult> getLocation([
    RadarTrackingOptionsDesiredAccuracy? accuracy,
  ]) {
    return _request('getLocation', {
      'accuracy': accuracy?.wireValue,
    }, RadarLocationResult.fromMap);
  }

  static Future<RadarTrackResult> trackOnce({
    RadarLocation? location,
    RadarTrackingOptionsDesiredAccuracy? desiredAccuracy,
    bool? beacons,
  }) {
    return _request('trackOnce', {
      'location': location?.toMap(),
      'desiredAccuracy': desiredAccuracy?.wireValue,
      'beacons': beacons,
    }, RadarTrackResult.fromMap);
  }

  static Future<void> startTracking(RadarTrackingPreset preset) async {
    await _invoke<void>('startTracking', {'preset': preset.wireValue});
  }

  static Future<void> startTrackingCustom(RadarTrackingOptions options) async {
    await _invoke<void>('startTrackingCustom', options.toMap());
  }

  static Future<void> startTrackingVerified(int interval, bool beacons) async {
    await _invoke<void>('startTrackingVerified', {
      'interval': interval,
      'beacons': beacons,
    });
  }

  static Future<void> stopTracking() async {
    await _invoke<void>('stopTracking');
  }

  static Future<void> stopTrackingVerified() async {
    await _invoke<void>('stopTrackingVerified');
  }

  /// Starts ranging nearby beacons in the foreground so `trackVerified` with
  /// `beacons: true` does not wait on a new ranging window. Requires
  /// foreground location permission and Bluetooth, and Android 8.0 or later.
  static Future<void> startRangingBeacons() async {
    await _invoke<void>('startRangingBeacons');
  }

  /// Stops ranging started by [startRangingBeacons].
  static Future<void> stopRangingBeacons() async {
    await _invoke<void>('stopRangingBeacons');
  }

  static Future<bool?> isTracking() async {
    return await _invoke('isTracking');
  }

  static Future<RadarTrackingOptions?> getTrackingOptions() async {
    return readObject(
      await _invoke<Object?>('getTrackingOptions'),
      RadarTrackingOptions.fromMap,
    );
  }

  /// Simulates a trip from [origin] to [destination] for testing, tracking
  /// [steps] locations along the route, [interval] seconds apart.
  ///
  /// Returns once the simulation starts. Each step is delivered to the
  /// listeners, such as [onLocation] and [onEvents], and to the background
  /// handler, like any other location update.
  static Future<void> mockTracking({
    required RadarLocation origin,
    required RadarLocation destination,
    RadarRouteMode? mode,
    int? steps,
    int? interval,
  }) async {
    // Neither native bridge replies to this call, so awaiting it would never
    // complete.
    unawaited(
      _invoke<void>('mockTracking', {
        'origin': origin.toMap(),
        'destination': destination.toMap(),
        'mode': mode?.wireValue,
        'steps': steps,
        'interval': interval,
      }),
    );
  }

  static Future<RadarTripResult> startTrip({
    required RadarTripOptions tripOptions,
    RadarTrackingOptions? trackingOptions,
  }) {
    return _request('startTrip', {
      'tripOptions': tripOptions.toMap(),
      'trackingOptions': trackingOptions?.toMap(),
    }, RadarTripResult.fromMap);
  }

  static Future<RadarTripResult> updateTrip({
    required RadarTripOptions options,
    required RadarTripStatus status,
  }) {
    return _request('updateTrip', {
      'tripOptions': options.toMap(),
      'status': status.wireValue,
    }, RadarTripResult.fromMap);
  }

  static Future<RadarTripOptions?> getTripOptions() async {
    return readObject(
      await _invoke<Object?>('getTripOptions'),
      RadarTripOptions.fromMap,
    );
  }

  static Future<RadarTripResult> completeTrip() {
    return _request('completeTrip', null, RadarTripResult.fromMap);
  }

  static Future<RadarTripResult> cancelTrip() {
    return _request('cancelTrip', null, RadarTripResult.fromMap);
  }

  static Future<RadarTrip?> getTrip() async {
    return readObject(await _invoke<Object?>('getTrip'), RadarTrip.fromMap);
  }

  /// Updates a leg on a multi-destination trip. Omit [tripId] to target the
  /// current trip.
  static Future<RadarTripResult> updateTripLeg({
    String? tripId,
    required String legId,
    required RadarTripLegStatus status,
  }) {
    return _request('updateTripLeg', {
      'tripId': tripId,
      'legId': legId,
      'status': status.wireValue,
    }, RadarTripResult.fromMap);
  }

  static Future<RadarTripResult> updateCurrentTripLeg({
    required RadarTripLegStatus status,
  }) {
    return _request('updateCurrentTripLeg', {
      'status': status.wireValue,
    }, RadarTripResult.fromMap);
  }

  /// Reorders legs on a multi-destination trip. Omit [tripId] to target the
  /// current trip.
  static Future<RadarTripResult> reorderTripLegs({
    String? tripId,
    required List<String> legIds,
  }) {
    return _request('reorderTripLegs', {
      'tripId': tripId,
      'legIds': legIds,
    }, RadarTripResult.fromMap);
  }

  /// Gets the context for [location], or for the device's current location
  /// if omitted.
  static Future<RadarContextResult> getContext([RadarLocation? location]) {
    return _request('getContext', {
      'location': location?.toMap(),
    }, RadarContextResult.fromMap);
  }

  static Future<RadarSearchGeofencesResult> searchGeofences({
    RadarLocation? near,
    int? radius,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    int? limit,
    bool? includeGeometry,
  }) {
    return _request('searchGeofences', <String, dynamic>{
      'near': near?.toMap(),
      'radius': radius,
      'limit': limit,
      'tags': tags,
      'metadata': metadata,
      'includeGeometry': includeGeometry,
    }, RadarSearchGeofencesResult.fromMap);
  }

  static Future<RadarSearchPlacesResult> searchPlaces({
    RadarLocation? near,
    int? radius,
    int? limit,
    List<String>? chains,
    Map<String, String>? chainMetadata,
    List<String>? categories,
    List<String>? groups,
    List<String>? countryCodes,
  }) {
    return _request('searchPlaces', {
      'near': near?.toMap(),
      'radius': radius,
      'limit': limit,
      'chains': chains,
      'chainMetadata': chainMetadata,
      'categories': categories,
      'groups': groups,
      'countryCodes': countryCodes,
    }, RadarSearchPlacesResult.fromMap);
  }

  static Future<List<RadarAddress>> autocomplete({
    required String query,
    RadarLocation? near,
    int? limit,
    String? country,
    List<String>? layers,
    bool? mailable,
  }) {
    return _request('autocomplete', {
      'query': query,
      'near': near?.toMap(),
      'limit': limit,
      'country': country,
      'layers': layers,
      'mailable': mailable,
    }, _addresses);
  }

  static Future<List<RadarAddress>> geocode(String query) {
    return _request('forwardGeocode', {'query': query}, _addresses);
  }

  static Future<List<RadarAddress>> reverseGeocode({
    RadarLocation? location,
    List<String>? layers,
  }) {
    return _request('reverseGeocode', {
      'location': location?.toMap(),
      'layers': layers,
    }, _addresses);
  }

  static Future<RadarIpGeocodeResult> ipGeocode() {
    return _request('ipGeocode', null, RadarIpGeocodeResult.fromMap);
  }

  static Future<RadarRevealRiskToken> revealRisk() {
    return _request(
      'revealRisk',
      null,
      (map) =>
          _require(readObject(map['revealRisk'], RadarRevealRiskToken.fromMap)),
    );
  }

  /// Gets the distance and duration to [destination] from [origin], or from
  /// the device's current location if [origin] is omitted.
  static Future<RadarRoutes> getDistance({
    RadarLocation? origin,
    required RadarLocation destination,
    required Set<RadarRouteMode> modes,
    required RadarRouteUnits units,
  }) {
    return _request('getDistance', {
      'origin': origin?.toMap(),
      'destination': destination.toMap(),
      'modes': [for (final mode in modes) mode.wireValue],
      'units': units.wireValue,
    }, (map) => _require(readObject(map['routes'], RadarRoutes.fromMap)));
  }

  static Future<RadarEvent> logConversion({
    required String name,
    double? revenue,
    Map<String, dynamic>? metadata,
  }) {
    return _request('logConversion', {
      'name': name,
      'revenue': revenue,
      'metadata': metadata ?? const <String, dynamic>{},
    }, (map) => _require(readObject(map['event'], RadarEvent.fromMap)));
  }

  /// iOS only. Does nothing on other platforms.
  static Future<void> logTermination() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    await _invoke<void>('logTermination');
  }

  static Future<void> logBackgrounding() async {
    await _invoke<void>('logBackgrounding');
  }

  static Future<void> logResigningActive() async {
    await _invoke<void>('logResigningActive');
  }

  /// Android only. Does nothing on other platforms.
  static Future<void> setNotificationOptions(
    RadarNotificationOptions notificationOptions,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await _invoke<void>('setNotificationOptions', notificationOptions.toMap());
  }

  static Future<RadarRouteMatrix> getMatrix({
    required List<RadarLocation> origins,
    required List<RadarLocation> destinations,
    required RadarRouteMode mode,
    required RadarRouteUnits units,
  }) {
    return _request('getMatrix', {
      'origins': [for (final origin in origins) origin.toMap()],
      'destinations': [
        for (final destination in destinations) destination.toMap(),
      ],
      'mode': mode.wireValue,
      'units': units.wireValue,
    }, (map) => _require(RadarRouteMatrix.fromWire(map['matrix'])));
  }

  /// Android only. Does nothing on other platforms.
  static Future<void> setForegroundServiceOptions(
    RadarForegroundServiceOptions foregroundServiceOptions,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await _invoke<void>(
      'setForegroundServiceOptions',
      foregroundServiceOptions.toMap(),
    );
  }

  static Future<RadarVerifiedLocationToken> trackVerified({
    bool? beacons,
    RadarTrackingOptionsDesiredAccuracy? desiredAccuracy,
    String? reason,
    String? transactionId,
  }) {
    return _request('trackVerified', {
      'beacons': beacons ?? false,
      'desiredAccuracy': desiredAccuracy?.wireValue,
      'reason': reason,
      'transactionId': transactionId,
    }, _token);
  }

  static Future<RadarVerifiedLocationToken> getVerifiedLocationToken() {
    return _request('getVerifiedLocationToken', null, _token);
  }

  static Future<bool?> isSharing() async {
    return await _invoke('isSharing');
  }

  static Future<void> clearSharing() async {
    await _invoke<void>('clearSharing');
  }

  static Future<void> setProduct(String? product) async {
    await _invoke<void>('setProduct', {'product': product});
  }

  static Future<void> setExpectedJurisdiction({
    String? countryCode,
    String? stateCode,
  }) async {
    await _invoke<void>('setExpectedJurisdiction', {
      'countryCode': countryCode,
      'stateCode': stateCode,
    });
  }

  /// Sets the user's expected address for address checks. Pass `null` to clear
  /// it. The result is returned on [RadarUser.expectedAddress].
  static Future<void> setExpectedAddress(String? address) async {
    await _invoke<void>('setExpectedAddress', {'address': address});
  }

  static Future<bool?> isUsingRemoteTrackingOptions() async {
    return await _invoke('isUsingRemoteTrackingOptions');
  }

  /// Validates an address from its [street] and [number], and returns its
  /// verification status, property type, and plus4.
  ///
  /// Every field except [unit] is required.
  static Future<RadarValidateAddressResult> validateStreetAddress({
    required String street,
    required String number,
    String? unit,
    required String city,
    required String stateCode,
    required String postalCode,
    required String countryCode,
  }) {
    return _request('validateStreetAddress', {
      'street': street,
      'number': number,
      'unit': unit,
      'city': city,
      'stateCode': stateCode,
      'postalCode': postalCode,
      'countryCode': countryCode,
    }, RadarValidateAddressResult.fromMap);
  }

  /// Validates an address from a single-line [addressLabel], such as
  /// `"20 Jay St"`, and returns its verification status, property type, and
  /// plus4.
  ///
  /// Every field except [unit] is required.
  static Future<RadarValidateAddressResult> validateAddressLabel({
    required String addressLabel,
    String? unit,
    required String city,
    required String stateCode,
    required String postalCode,
    required String countryCode,
  }) {
    return _request('validateAddressLabel', {
      'addressLabel': addressLabel,
      'unit': unit,
      'city': city,
      'stateCode': stateCode,
      'postalCode': postalCode,
      'countryCode': countryCode,
    }, RadarValidateAddressResult.fromMap);
  }

  static Future<String?> getProduct() async {
    return await _invoke('getProduct');
  }

  static Future<List<String>?> getTags() async {
    // The channel decodes lists as List<Object?>, so ask for that and convert;
    // asking for List<String> would fail the cast.
    final tags = await _invoke<List<Object?>>('getTags');
    return tags == null ? null : readStringList(tags);
  }

  static Future<void> addTags(List<String> tags) async {
    await _invoke<void>('addTags', {'tags': tags});
  }

  static Future<void> removeTags(List<String> tags) async {
    await _invoke<void>('removeTags', {'tags': tags});
  }

  static Future<bool?> isInitialized() async {
    return await _invoke('isInitialized');
  }

  static Future<String?> sdkVersion() async {
    return await _invoke('sdkVersion');
  }

  static Future<void> setUserLanguage(String? userLanguage) async {
    await _invoke<void>('setUserLanguage', {'userLanguage': userLanguage});
  }

  static Future<String?> getUserLanguage() async {
    return await _invoke('getUserLanguage');
  }

  static Future<void> setTags(List<String> tags) async {
    await _invoke<void>('setTags', {'tags': tags});
  }

  static Future<void> acceptEvent(
    String eventId, {
    String? verifiedPlaceId,
  }) async {
    await _invoke<void>('acceptEvent', {
      'eventId': eventId,
      'verifiedPlaceId': verifiedPlaceId,
    });
  }

  static Future<void> rejectEvent(String eventId) async {
    await _invoke<void>('rejectEvent', {'eventId': eventId});
  }

  static Future<void> setPushNotificationToken(String? token) async {
    await _invoke<void>('setPushNotificationToken', {'token': token});
  }

  static Future<bool?> isTrackingVerified() async {
    return await _invoke('isTrackingVerified');
  }

  static Future<void> clearVerifiedLocationToken() async {
    await _invoke<void>('clearVerifiedLocationToken');
  }

  static Future<void> showInAppMessage(RadarInAppMessage inAppMessage) async {
    await _invoke<void>('showInAppMessage', {
      'inAppMessage': inAppMessage.toMap(),
    });
  }

  static void onLocation(void Function(RadarLocationUpdate update) callback) {
    if (_onLocation != null) {
      throw RadarExistingCallbackException();
    }
    _onLocation = callback;
  }

  static void offLocation() {
    _onLocation = null;
  }

  static void onClientLocation(
    void Function(RadarClientLocationUpdate update) callback,
  ) {
    if (_onClientLocation != null) {
      throw RadarExistingCallbackException();
    }
    _onClientLocation = callback;
  }

  static void offClientLocation() {
    _onClientLocation = null;
  }

  static void onError(void Function(RadarErrorUpdate update) callback) {
    if (_onError != null) {
      throw RadarExistingCallbackException();
    }
    _onError = callback;
  }

  static void offError() {
    _onError = null;
  }

  static void onLog(void Function(RadarLogUpdate update) callback) {
    if (_onLog != null) {
      throw RadarExistingCallbackException();
    }
    _onLog = callback;
  }

  static void offLog() {
    _onLog = null;
  }

  static void onEvents(void Function(RadarEventsUpdate update) callback) {
    if (_onEvents != null) {
      throw RadarExistingCallbackException();
    }
    _onEvents = callback;
  }

  static void offEvents() {
    _onEvents = null;
  }

  static void onIpChanged(void Function(RadarIpChangedUpdate update) callback) {
    if (_onIpChanged != null) {
      throw RadarExistingCallbackException();
    }
    _onIpChanged = callback;
  }

  static void offIpChanged() {
    _onIpChanged = null;
  }

  static void onSharingChanged(
    void Function(RadarSharingChangedUpdate update) callback,
  ) {
    if (_onSharingChanged != null) {
      throw RadarExistingCallbackException();
    }
    _onSharingChanged = callback;
  }

  static void offSharingChanged() {
    _onSharingChanged = null;
  }

  static void onToken(void Function(RadarTokenUpdate update) callback) {
    if (_onToken != null) {
      throw RadarExistingCallbackException();
    }
    _onToken = callback;
  }

  static void offToken() {
    _onToken = null;
  }

  /// Registers [handler] as the durable event sink across foreground,
  /// background, and headless delivery.
  ///
  /// Existing `onX` listeners remain independent engine-scoped observers.
  /// When both are registered, both may receive the same event.
  ///
  /// Replaces any previously registered handler. [handler] must be a top-level
  /// or static function annotated with `@pragma('vm:entry-point')`.
  static Future<void> registerBackgroundHandler(
    RadarBackgroundHandler handler,
  ) async {
    final dispatcherHandle = PluginUtilities.getCallbackHandle(
      radarBackgroundCallbackDispatcher,
    );

    if (dispatcherHandle == null) {
      throw StateError(
        'Could not resolve the Radar background callback dispatcher.',
      );
    }

    final callbackHandle = PluginUtilities.getCallbackHandle(handler);

    if (callbackHandle == null) {
      throw ArgumentError.value(
        handler,
        'handler',
        'Background handler must be a top-level or static function annotated '
            'with @pragma(\'vm:entry-point\').',
      );
    }

    installRadarBackgroundMethodCallHandler();

    await _invoke<void>('registerBackgroundHandler', {
      'dispatcherHandle': dispatcherHandle.toRawHandle(),
      'callbackHandle': callbackHandle.toRawHandle(),
    });
  }

  /// Removes the persisted handler and stops durable event delivery.
  static Future<void> unregisterBackgroundHandler() async {
    await _invoke<void>('unregisterBackgroundHandler');
    removeRadarBackgroundMethodCallHandler();
  }
}

class RadarInitializeOptions {
  /// Android only. Enables fraud detection signals on tracking calls, and
  /// requires the `io.radar:sdk-fraud` dependency. On iOS, fraud activates
  /// automatically when `RadarSDKFraud.xcframework` is linked, so this is
  /// ignored there.
  final bool? fraud;

  final bool? silentPush;
  final bool? trackVerifiedAutoFailover;

  /// Request timeout for standard API calls. Clamped natively to 1...300
  /// seconds; omit to use the SDK default of 10 seconds.
  final Duration? networkTimeout;

  /// Minimum interval between IP-change callbacks. [Duration.zero] delivers
  /// every detected change; omit to use the SDK default of 10 seconds.
  final Duration? ipChangeDebounceInterval;

  /// iOS only.
  final bool? autoLogNotificationConversions;

  /// iOS only.
  final bool? autoHandleNotificationDeepLinks;

  const RadarInitializeOptions({
    this.fraud,
    this.silentPush,
    this.trackVerifiedAutoFailover,
    this.networkTimeout,
    this.ipChangeDebounceInterval,
    this.autoLogNotificationConversions,
    this.autoHandleNotificationDeepLinks,
  });

  Map<String, dynamic> toMap() => {
    if (fraud != null) 'fraud': fraud,
    if (silentPush != null) 'silentPush': silentPush,
    if (trackVerifiedAutoFailover != null)
      'trackVerifiedAutoFailover': trackVerifiedAutoFailover,
    if (networkTimeout != null)
      'networkTimeout': networkTimeout!.inMilliseconds / 1000.0,
    if (ipChangeDebounceInterval != null)
      'ipChangeDebounceInterval':
          ipChangeDebounceInterval!.inMilliseconds / 1000.0,
    if (autoLogNotificationConversions != null)
      'autoLogNotificationConversions': autoLogNotificationConversions,
    if (autoHandleNotificationDeepLinks != null)
      'autoHandleNotificationDeepLinks': autoHandleNotificationDeepLinks,
  };
}

class RadarExistingCallbackException implements Exception {
  @override
  String toString() {
    return 'Existing callback already exists for this event. Please call the corresponding `off` method first.';
  }
}
