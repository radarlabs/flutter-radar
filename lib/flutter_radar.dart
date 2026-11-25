import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/models/parsing.dart';
import 'src/models/radar_address.dart';
import 'src/models/radar_enums.dart';
import 'src/models/radar_event.dart';
import 'src/models/radar_exception.dart';
import 'src/models/radar_foreground_service_options.dart';
import 'src/models/radar_in_app_message.dart';
import 'src/models/radar_location.dart';
import 'src/models/radar_notification_options.dart';
import 'src/models/radar_results.dart';
import 'src/models/radar_reveal_risk_token.dart';
import 'src/models/radar_routes.dart';
import 'src/models/radar_status.dart';
import 'src/models/radar_tracking_options.dart';
import 'src/models/radar_trip.dart';
import 'src/models/radar_update.dart';
import 'src/models/radar_verified_location_token.dart';
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
  static const MethodChannel _channel = MethodChannel('flutter_radar');

  static final _locationController =
      StreamController<RadarLocationUpdate>.broadcast();
  static final _clientLocationController =
      StreamController<RadarClientLocationUpdate>.broadcast();
  static final _errorController =
      StreamController<RadarErrorUpdate>.broadcast();
  static final _logController = StreamController<RadarLogUpdate>.broadcast();
  static final _eventsController =
      StreamController<RadarEventsUpdate>.broadcast();
  static final _tokenController =
      StreamController<RadarTokenUpdate>.broadcast();
  static final _ipChangedController =
      StreamController<RadarIpChangedUpdate>.broadcast();
  static final _sharingChangedController =
      StreamController<RadarSharingChangedUpdate>.broadcast();

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

  /// Initializes the Radar SDK with your [publishableKey].
  ///
  /// Call this before calling any other Radar methods. Pass [options] to
  /// configure optional features. See the
  /// [SDK docs](https://radar.com/documentation/sdk/flutter).
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
        _locationController.add(update);
      case RadarClientLocationUpdate():
        _clientLocationController.add(update);
      case RadarErrorUpdate():
        _errorController.add(update);
      case RadarLogUpdate():
        _logController.add(update);
      case RadarEventsUpdate():
        _eventsController.add(update);
      case RadarTokenUpdate():
        _tokenController.add(update);
      case RadarIpChangedUpdate():
        _ipChangedController.add(update);
      case RadarSharingChangedUpdate():
        _sharingChangedController.add(update);
      case null:
        break;
    }
  }

  /// Sets the log level for debug logs.
  ///
  /// The remote SDK configuration set in the dashboard can override this.
  static Future<void> setLogLevel(RadarLogLevel logLevel) async {
    await _invoke<void>('setLogLevel', {'logLevel': logLevel.wireValue});
  }

  /// Returns the app's current location permissions status.
  static Future<RadarPermissionsStatus> getPermissionsStatus() async {
    return RadarPermissionsStatus.fromWire(
      await _invoke<String>('getPermissionsStatus'),
    );
  }

  /// Requests location permissions.
  ///
  /// If [background] is true, requests background permissions: on iOS, this
  /// asks for "always" authorization once "when in use" is granted; on Android
  /// 10 and later, it requests background location along with foreground
  /// location. Otherwise, requests foreground permissions.
  static Future<void> requestPermissions(bool background) async {
    await _invoke<void>('requestPermissions', {'background': background});
  }

  /// Identifies the user with [userId], a stable unique ID for the user.
  ///
  /// Until you identify the user, Radar identifies the user by device ID. See the
  /// [SDK docs](https://radar.com/documentation/sdk/flutter).
  static Future<void> setUserId(String userId) async {
    await _invoke<void>('setUserId', {'userId': userId});
  }

  /// Returns the current user ID, or null if none is set.
  static Future<String?> getUserId() async {
    return await _invoke('getUserId');
  }

  /// Sets an optional [description] for the user, displayed in the dashboard.
  static Future<void> setDescription(String description) async {
    await _invoke<void>('setDescription', {'description': description});
  }

  /// Returns the current user description, or null if none is set.
  static Future<String?> getDescription() async {
    return await _invoke('getDescription');
  }

  /// Sets an optional set of custom key-value pairs for the user.
  ///
  /// [metadata] must have 16 or fewer keys, and its values must be strings,
  /// booleans, or numbers.
  static Future<void> setMetadata(Map<String, dynamic> metadata) async {
    await _channel.invokeMethod('setMetadata', metadata);
  }

  /// Returns the current user metadata, or null if none is set.
  static Future<Map<String, Object?>?> getMetadata() async {
    return readJson(await _invoke('getMetadata'));
  }

  /// Enables or disables anonymous tracking for privacy reasons.
  ///
  /// When [enabled], [trackOnce] and [startTracking] don't create user records on
  /// the server and don't send stable device IDs, user IDs, or user metadata.
  /// Disabled by default.
  static Future<void> setAnonymousTrackingEnabled(bool enabled) async {
    await _invoke<void>('setAnonymousTrackingEnabled', {'enabled': enabled});
  }

  /// Gets the device's current location, with the [desiredAccuracy] if
  /// given.
  ///
  /// Throws a [RadarException] if the request fails.
  static Future<RadarLocationResult> getLocation({
    RadarTrackingOptionsDesiredAccuracy? desiredAccuracy,
  }) {
    return _request('getLocation', {
      'desiredAccuracy': desiredAccuracy?.wireValue,
    }, RadarLocationResult.fromMap);
  }

  /// Tracks the user's location once in the foreground.
  ///
  /// Pass [location] to track it as a manual location instead of getting one
  /// from the device. Otherwise, the SDK gets the device's location with
  /// [desiredAccuracy], and ranges beacons if [beacons] is true. These calls are
  /// subject to rate limits.
  ///
  /// Throws a [RadarException] if the request fails.
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

  /// Starts tracking the user's location in the background with [options],
  /// such as [RadarTrackingOptions.responsive] or a preset adjusted with
  /// [RadarTrackingOptions.copyWith].
  ///
  /// See the [background tracking docs](https://radar.com/documentation/sdk/tracking).
  static Future<void> startTracking(RadarTrackingOptions options) async {
    await _invoke<void>('startTracking', options.toMap());
  }

  /// Starts tracking the user's location with device integrity information
  /// for location verification use cases.
  ///
  /// [interval] is the default time between location updates, sent in whole
  /// seconds. If [beacons] is true, ranges beacons. You must configure SSL
  /// pinning before calling this method. See the
  /// [fraud docs](https://radar.com/documentation/fraud).
  static Future<void> startTrackingVerified(
    Duration interval,
    bool beacons,
  ) async {
    await _invoke<void>('startTrackingVerified', {
      'interval': wholeSeconds(interval, 'interval'),
      'beacons': beacons,
    });
  }

  /// Stops tracking the user's location in the background.
  static Future<void> stopTracking() async {
    await _invoke<void>('stopTracking');
  }

  /// Stops tracking the user's location with device integrity information.
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

  /// Returns whether background tracking has been started.
  static Future<bool?> isTracking() async {
    return await _invoke('isTracking');
  }

  /// Returns the current tracking options.
  static Future<RadarTrackingOptions?> getTrackingOptions() async {
    return readObject(
      await _invoke<Object?>('getTrackingOptions'),
      RadarTrackingOptions.fromMap,
    );
  }

  /// Simulates a trip from [origin] to [destination] for testing, tracking
  /// [steps] locations along the route, [interval] apart. [interval] is sent
  /// in whole seconds, from 1 to 60.
  ///
  /// [mode] is the travel mode. See the
  /// [SDK docs](https://radar.com/documentation/sdk/flutter).
  ///
  /// Returns once the simulation starts. Each step is delivered to the
  /// listeners, such as [onLocation] and [onEvents], and to the background
  /// handler, like any other location update.
  static Future<void> mockTracking({
    required RadarLocation origin,
    required RadarLocation destination,
    RadarRouteMode? mode,
    int? steps,
    Duration? interval,
  }) async {
    await _invoke<void>('mockTracking', {
      'origin': origin.toMap(),
      'destination': destination.toMap(),
      'mode': mode?.wireValue,
      'steps': steps,
      'interval': switch (interval) {
        final value? => wholeSeconds(value, 'interval'),
        null => null,
      },
    });
  }

  /// Starts a trip with [tripOptions].
  ///
  /// Pass [trackingOptions] to use them during the trip. See the
  /// [trip tracking docs](https://radar.com/documentation/trip-tracking).
  ///
  /// Throws a [RadarException] if the request fails.
  static Future<RadarTripResult> startTrip({
    required RadarTripOptions tripOptions,
    RadarTrackingOptions? trackingOptions,
  }) {
    return _request('startTrip', {
      'tripOptions': tripOptions.toMap(),
      'trackingOptions': trackingOptions?.toMap(),
    }, RadarTripResult.fromMap);
  }

  /// Manually updates the current trip with [options] and [status].
  ///
  /// To leave the status unchanged, pass [RadarTripStatus.unknown].
  ///
  /// Throws a [RadarException] if the request fails.
  static Future<RadarTripResult> updateTrip({
    required RadarTripOptions options,
    required RadarTripStatus status,
  }) {
    return _request('updateTrip', {
      'tripOptions': options.toMap(),
      'status': status.wireValue,
    }, RadarTripResult.fromMap);
  }

  /// Returns the current trip options, or null if no trip is active.
  static Future<RadarTripOptions?> getTripOptions() async {
    return readObject(
      await _invoke<Object?>('getTripOptions'),
      RadarTripOptions.fromMap,
    );
  }

  /// Completes the current trip.
  ///
  /// Throws a [RadarException] if the request fails.
  static Future<RadarTripResult> completeTrip() {
    return _request('completeTrip', null, RadarTripResult.fromMap);
  }

  /// Cancels the current trip.
  ///
  /// Throws a [RadarException] if the request fails.
  static Future<RadarTripResult> cancelTrip() {
    return _request('cancelTrip', null, RadarTripResult.fromMap);
  }

  /// Returns the current trip, including legs for multi-destination trips, or
  /// null if no trip is active.
  ///
  /// Use the legs' IDs when calling [updateTripLeg].
  static Future<RadarTrip?> getTrip() async {
    return readObject(await _invoke('getTrip'), RadarTrip.fromMap);
  }

  /// Updates the status of the leg with [legId] on a multi-destination trip.
  ///
  /// Omit [tripId] to target the current trip. Leg IDs come from
  /// [RadarTrip.legs].
  ///
  /// Throws a [RadarException] if the request fails.
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

  /// Updates the status of the current leg on the current multi-destination
  /// trip.
  ///
  /// Throws a [RadarException] if the request fails.
  static Future<RadarTripResult> updateCurrentTripLeg({
    required RadarTripLegStatus status,
  }) {
    return _request('updateCurrentTripLeg', {
      'status': status.wireValue,
    }, RadarTripResult.fromMap);
  }

  /// Reorders the legs of a multi-destination trip to match [legIds].
  ///
  /// Omit [tripId] to target the current trip.
  ///
  /// Throws a [RadarException] if the request fails.
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
  /// if omitted, without sending device or user identifiers to the server.
  ///
  /// See the [context docs](https://radar.com/documentation/api#context).
  ///
  /// Throws a [RadarException] if the request fails.
  static Future<RadarContextResult> getContext([RadarLocation? location]) {
    return _request('getContext', {
      'location': location?.toMap(),
    }, RadarContextResult.fromMap);
  }

  /// Searches for geofences near a location, sorted by distance.
  ///
  /// Searches near [near], or near the device's current location if omitted.
  /// [radius] is in meters, from 100 to 10000; -1 searches with an unlimited
  /// radius. [tags] and [metadata] filter the results. [limit] is the max number
  /// of geofences to return, from 1 to 1000. [includeGeometry] includes geofence
  /// geometries in the response; leave it false unless you need them, and to
  /// get more than 100 results it must be false. See the
  /// [search geofences docs](https://radar.com/documentation/api#search-geofences).
  ///
  /// Throws a [RadarException] if the request fails.
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

  /// Searches for places near a location, sorted by distance.
  ///
  /// Searches near [near], or near the device's current location if omitted.
  /// [radius] is in meters, from 100 to 10000. [limit] is the max number of
  /// places to return, from 1 to 100. Specify only one of [chains],
  /// [categories], or [groups]. With [chains], you can also pass
  /// [chainMetadata] filters. [countryCodes] filters by country. See the
  /// [search places docs](https://radar.com/documentation/api#search-places).
  ///
  /// Throws a [RadarException] if the request fails.
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

  /// Autocompletes partial addresses and place names, sorted by relevance.
  ///
  /// [query] is the partial address or place name. [near] is an optional
  /// location for the search. [limit] is the max number of addresses to
  /// return, from 1 to 100. [country] is an optional 2-letter country code
  /// filter, and [layers] optionally filters by layer. If [mailable] is true,
  /// returns only mailable addresses. See the
  /// [autocomplete docs](https://radar.com/documentation/api#autocomplete).
  ///
  /// Throws a [RadarException] if the request fails.
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

  /// Geocodes an address [query], converting it to coordinates.
  ///
  /// See the [forward geocode docs](https://radar.com/documentation/api#forward-geocode).
  ///
  /// Throws a [RadarException] if the request fails.
  static Future<List<RadarAddress>> geocode(String query) {
    return _request('forwardGeocode', {'query': query}, _addresses);
  }

  /// Reverse geocodes a location, converting coordinates to addresses.
  ///
  /// Reverse geocodes [location], or the device's current location if omitted.
  /// [layers] optionally filters by layer. See the
  /// [reverse geocode docs](https://radar.com/documentation/api#reverse-geocode).
  ///
  /// Throws a [RadarException] if the request fails.
  static Future<List<RadarAddress>> reverseGeocode({
    RadarLocation? location,
    List<String>? layers,
  }) {
    return _request('reverseGeocode', {
      'location': location?.toMap(),
      'layers': layers,
    }, _addresses);
  }

  /// Geocodes the device's current IP address, converting it to a partial
  /// address.
  ///
  /// See the [IP geocode docs](https://radar.com/documentation/api#ip-geocode).
  ///
  /// Throws a [RadarException] if the request fails.
  static Future<RadarIpGeocodeResult> ipGeocode() {
    return _request('ipGeocode', null, RadarIpGeocodeResult.fromMap);
  }

  /// Reveals device and network risk signals for this device.
  ///
  /// You must configure SSL pinning before calling this method. See the
  /// [fraud docs](https://radar.com/documentation/fraud).
  ///
  /// Throws a [RadarException] if the request fails.
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
  ///
  /// [modes] are the travel modes, and [units] are the distance units. See
  /// the [distance docs](https://radar.com/documentation/api#distance).
  ///
  /// Throws a [RadarException] if the request fails.
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

  /// Logs a conversion event named [name], and returns it.
  ///
  /// [revenue] is the revenue generated by the conversion, and [metadata] is
  /// custom data for the conversion. See the
  /// [custom events docs](https://radar.com/documentation/api#send-a-custom-event).
  ///
  /// Throws a [RadarException] if the request fails.
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

  /// Logs the app terminating.
  ///
  /// Call this when the app is about to terminate. iOS only. Does nothing on
  /// other platforms.
  static Future<void> logTermination() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    await _invoke<void>('logTermination');
  }

  /// Logs the app entering the background.
  ///
  /// Call this when the app enters the background. On Android, this also flushes
  /// buffered logs to persistent storage.
  static Future<void> logBackgrounding() async {
    await _invoke<void>('logBackgrounding');
  }

  /// Logs the app resigning active.
  ///
  /// Call this when the app is about to become inactive.
  static Future<void> logResigningActive() async {
    await _invoke<void>('logResigningActive');
  }

  /// Sets options for the notifications the SDK shows.
  ///
  /// Android only. Does nothing on other platforms.
  static Future<void> setNotificationOptions(
    RadarNotificationOptions notificationOptions,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await _invoke<void>('setNotificationOptions', notificationOptions.toMap());
  }

  /// Calculates the travel distances and durations between multiple
  /// [origins] and [destinations], for up to 25 routes.
  ///
  /// [mode] is the travel mode, and [units] are the distance units. See the
  /// [matrix docs](https://radar.com/documentation/api#matrix).
  ///
  /// Throws a [RadarException] if the request fails.
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

  /// Sets options for the foreground service notification, used when
  /// [RadarTrackingOptions.foregroundServiceEnabled] is true.
  ///
  /// Android only. Does nothing on other platforms. See the
  /// [tracking docs](https://radar.com/documentation/sdk/tracking).
  static Future<void> setForegroundServiceOptions(
    RadarForegroundServiceOptions foregroundServiceOptions,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await _invoke<void>(
      'setForegroundServiceOptions',
      foregroundServiceOptions.toMap(),
    );
  }

  /// Tracks the user's location with device integrity information for
  /// location verification use cases, and returns a verified location token.
  ///
  /// If [beacons] is true, ranges beacons. [desiredAccuracy] is the desired
  /// location accuracy. [reason] and [transactionId] are optional and displayed
  /// in the dashboard and reports. You must configure SSL pinning before calling
  /// this method. See the [fraud docs](https://radar.com/documentation/fraud).
  ///
  /// Throws a [RadarException] if the request fails.
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

  /// Returns the user's last verified location token if it's still valid, or
  /// requests a fresh one if not.
  ///
  /// You must configure SSL pinning before calling this method. See the
  /// [fraud docs](https://radar.com/documentation/fraud).
  ///
  /// Throws a [RadarException] if the request fails.
  static Future<RadarVerifiedLocationToken> getVerifiedLocationToken() {
    return _request('getVerifiedLocationToken', null, _token);
  }

  /// Returns the current screen sharing state.
  static Future<bool?> isSharing() async {
    return await _invoke('isSharing');
  }

  /// Clears the last screen sharing state.
  static Future<void> clearSharing() async {
    await _invoke<void>('clearSharing');
  }

  /// Sets an optional [product] name, displayed in the dashboard and reports.
  ///
  /// Pass null to clear it.
  static Future<void> setProduct(String? product) async {
    await _invoke<void>('setProduct', {'product': product});
  }

  /// Sets the user's expected country and state for jurisdiction checks.
  ///
  /// [countryCode] and [stateCode] are two-letter codes.
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

  /// Returns whether remote tracking options are overriding the local
  /// tracking options.
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

  /// Returns the current product name, or null if none is set.
  static Future<String?> getProduct() async {
    return await _invoke('getProduct');
  }

  /// Returns the user's current tags, or null if none are set.
  static Future<List<String>?> getTags() async {
    // The channel decodes lists as List<Object?>, so ask for that and convert;
    // asking for List<String> would fail the cast.
    final tags = await _invoke<List<Object?>>('getTags');
    return tags == null ? null : readStringList(tags);
  }

  /// Adds [tags] to the user's existing tags.
  static Future<void> addTags(List<String> tags) async {
    await _invoke<void>('addTags', {'tags': tags});
  }

  /// Removes [tags] from the user's existing tags.
  static Future<void> removeTags(List<String> tags) async {
    await _invoke<void>('removeTags', {'tags': tags});
  }

  /// Returns whether the SDK has been initialized.
  static Future<bool?> isInitialized() async {
    return await _invoke('isInitialized');
  }

  /// Returns the version of the native Radar SDK, such as "4.0.0".
  static Future<String?> sdkVersion() async {
    return await _invoke('sdkVersion');
  }

  /// Sets the user's preferred language as a BCP-47 language tag, such as
  /// `"en"` or `"es-PR"`.
  ///
  /// Pass null to clear it.
  static Future<void> setUserLanguage(String? userLanguage) async {
    await _invoke<void>('setUserLanguage', {'userLanguage': userLanguage});
  }

  /// Returns the user's preferred language, or null if none is set.
  static Future<String?> getUserLanguage() async {
    return await _invoke('getUserLanguage');
  }

  /// Sets the user's tags, replacing any existing tags.
  static Future<void> setTags(List<String> tags) async {
    await _invoke<void>('setTags', {'tags': tags});
  }

  /// Accepts the event with [eventId].
  ///
  /// Accept events after user check-ins or other forms of verification. Radar
  /// uses event verifications to improve the accuracy and confidence of future
  /// events. For place entry events, pass the ID of the verified place as
  /// [verifiedPlaceId]. See the
  /// [verify events docs](https://radar.com/documentation/places#verify-events).
  static Future<void> acceptEvent(
    String eventId, {
    String? verifiedPlaceId,
  }) async {
    await _invoke<void>('acceptEvent', {
      'eventId': eventId,
      'verifiedPlaceId': verifiedPlaceId,
    });
  }

  /// Rejects the event with [eventId].
  ///
  /// Radar uses event verifications to improve the accuracy and confidence of
  /// future events. See the
  /// [verify events docs](https://radar.com/documentation/places#verify-events).
  static Future<void> rejectEvent(String eventId) async {
    await _invoke<void>('rejectEvent', {'eventId': eventId});
  }

  /// Sets the device's push notification [token], or clears it if null.
  static Future<void> setPushNotificationToken(String? token) async {
    await _invoke<void>('setPushNotificationToken', {'token': token});
  }

  /// Returns whether verified tracking has been started.
  static Future<bool?> isTrackingVerified() async {
    return await _invoke('isTrackingVerified');
  }

  /// Clears the user's last verified location token.
  static Future<void> clearVerifiedLocationToken() async {
    await _invoke<void>('clearVerifiedLocationToken');
  }

  /// Shows [inAppMessage] in the app.
  static Future<void> showInAppMessage(RadarInAppMessage inAppMessage) async {
    await _invoke<void>('showInAppMessage', {
      'inAppMessage': inAppMessage.toMap(),
    });
  }

  /// Location updates.
  ///
  /// Emits when the user's location is updated and synced to the server, with
  /// the location and the user.
  static Stream<RadarLocationUpdate> get onLocation =>
      _locationController.stream;

  /// Client location updates.
  ///
  /// Emits when the device's location is updated, but not necessarily synced
  /// to the server, with the location, whether the device is stopped, and the
  /// location source. To receive server-synced locations and user state, use
  /// [onLocation].
  static Stream<RadarClientLocationUpdate> get onClientLocation =>
      _clientLocationController.stream;

  /// Errors.
  ///
  /// Emits when a request fails, with its status.
  static Stream<RadarErrorUpdate> get onError => _errorController.stream;

  /// Debug log messages.
  static Stream<RadarLogUpdate> get onLog => _logController.stream;

  /// Events.
  ///
  /// Emits when events are received, with the events and the user, if any.
  static Stream<RadarEventsUpdate> get onEvents => _eventsController.stream;

  /// Changes to the device's IP address.
  ///
  /// Emits while IP change monitoring is active, at most once per
  /// [RadarInitializeOptions.ipChangeDebounceInterval].
  static Stream<RadarIpChangedUpdate> get onIpChanged =>
      _ipChangedController.stream;

  /// Changes to the device's screen sharing state.
  static Stream<RadarSharingChangedUpdate> get onSharingChanged =>
      _sharingChangedController.stream;

  /// Verified location tokens.
  ///
  /// Emits when the user's verified location is updated. Verify the token
  /// server-side using your secret key.
  static Stream<RadarTokenUpdate> get onToken => _tokenController.stream;

  /// Registers [handler] as the durable event sink across foreground,
  /// background, and headless delivery.
  ///
  /// The listener streams, such as [onLocation], are independent of it and
  /// scoped to the current Flutter engine. An update can reach both.
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

/// Options for [Radar.initialize].
class RadarInitializeOptions {
  /// Android only. Enables fraud detection signals on tracking calls, and
  /// requires the `io.radar:sdk-fraud` dependency. On iOS, fraud activates
  /// automatically when `RadarSDKFraud.xcframework` is linked, so this is
  /// ignored there.
  final bool? fraud;

  /// Whether to configure silent push notifications.
  ///
  /// On Android, see `RadarFirebaseMessagingService` in the native SDK for
  /// setup. On iOS, this registers for remote notifications.
  final bool? silentPush;

  /// Whether [Radar.trackVerified] retries against a secondary verified host
  /// when the primary host returns a non-Radar response.
  ///
  /// Omit to use the SDK default of true.
  final bool? trackVerifiedAutoFailover;

  /// Request timeout for standard API calls. Clamped natively to 1...300
  /// seconds; omit to use the SDK default of 10 seconds.
  final Duration? networkTimeout;

  /// Minimum interval between IP-change callbacks. [Duration.zero] delivers
  /// every detected change; omit to use the SDK default of 10 seconds.
  final Duration? ipChangeDebounceInterval;

  /// Whether to log a conversion automatically when the user opens a
  /// notification.
  ///
  /// iOS only.
  final bool? autoLogNotificationConversions;

  /// Whether to open the URL in a notification automatically when the user
  /// opens it.
  ///
  /// iOS only.
  final bool? autoHandleNotificationDeepLinks;

  /// Creates a [RadarInitializeOptions].
  const RadarInitializeOptions({
    this.fraud,
    this.silentPush,
    this.trackVerifiedAutoFailover,
    this.networkTimeout,
    this.ipChangeDebounceInterval,
    this.autoLogNotificationConversions,
    this.autoHandleNotificationDeepLinks,
  });

  /// Converts this to the map the native SDK reads.
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
