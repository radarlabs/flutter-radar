# Migration guides

## Map-based API to typed models (4.0.0)

Every method that took or returned a `Map` now uses typed models, and enum-like `String` arguments are now Dart enums.

**Errors.** Methods that make a request return a typed result on success and throw a `RadarException` when the request fails. They used to return a `Map` with a `status` string. Read the failure reason from `RadarException.status`. A `PlatformException`, which used to come back as `{'error': code}` or was only printed, now propagates. It means the plugin itself failed, not the Radar request. Any location the SDK obtained before a request failed is still delivered to `onClientLocation` and the background handler.

```dart
// Before
final res = await Radar.trackOnce();
if (res?['status'] == 'SUCCESS') {
  final events = res?['events'] as List?;
} else {
  print(res?['status']);
}

// After
try {
  final result = await Radar.trackOnce();
  for (final event in result.events) {
    print(event.type); // RadarEventType.userEnteredGeofence, ...
  }
} on RadarException catch (e) {
  print(e.status); // RadarStatus.errorPermissions, ...
}
```

Check calls you don't `await`, such as a `Radar.trackOnce()` in an app lifecycle callback. Their failures used to come back as a status nobody read. Now each one is an uncaught async error, which crash reporters such as Crashlytics or Sentry record. Wrap these calls in `try`/`catch` or attach `.catchError`. To find them, enable the `unawaited_futures` lint, which flags calls in `async` functions, and `discarded_futures`, which flags calls in synchronous ones. Neither is on by default. Marking a call with `unawaited()` silences the lints but doesn't catch the error.

`cancelTrip`, `completeTrip` and `updateTrip` throw `RadarException(RadarStatus.errorBadRequest)` when there's no active trip. Check `await Radar.getTripOptions()` first if you call them defensively. `errorNotFound` means the trip had already ended on the server; the SDK clears it either way.

**Return values.**

- A method that returns a single value returns it directly:
  - `autocomplete`, `geocode` and `reverseGeocode` return `List<RadarAddress>`.
  - `getDistance` returns `RadarRoutes` and `getMatrix` returns `RadarRouteMatrix`.
  - `logConversion` returns `RadarEvent`, and `revealRisk` returns `RadarRevealRiskToken`.
  - `trackVerified` and `getVerifiedLocationToken` return `RadarVerifiedLocationToken`.
- Methods that return several values return a result class, such as `RadarTrackResult` or `RadarTripResult`.
- `updateTripLeg` and `updateCurrentTripLeg` return a `RadarTripResult`. The server never returned the leg on its own; find it in `result.trip.legs`.
- `mockTracking` returns once the simulation starts. Each step is delivered to the listeners. It used to return a `Future` that never completed.

Methods that don't return a value, such as `setUserId` or `startTracking`, now return `Future<void>` and let a `PlatformException` propagate instead of printing it.

**Locations.** Pass a `RadarLocation` wherever a `{'latitude': ..., 'longitude': ...}` map was accepted (`trackOnce`, `getContext`, `searchGeofences`, `searchPlaces`, `autocomplete`, `reverseGeocode`, `getDistance`, `getMatrix`, `mockTracking`).

**Required arguments.** Some arguments that were optional are now required: `tripOptions` on `startTrip`, `query` on `autocomplete`, `destination`, `modes` and `units` on `getDistance`, and `origin` and `destination` on `mockTracking`.

**Options.**

| Before | After |
|---|---|
| `startTracking('responsive')` | `startTracking(RadarTrackingPreset.responsive)` |
| `startTrackingCustom({...})` | `startTrackingCustom(RadarTrackingOptions(...))`, or `RadarTrackingOptions.responsive.copyWith(...)` |
| `Radar.presetResponsive` (and the other preset maps) | `RadarTrackingOptions.responsive`, `.continuous`, `.efficient` |
| `startTrip(tripOptions: {...})` | `startTrip(tripOptions: RadarTripOptions(...))`. Build legs with `RadarTripLeg.geofence(...)`, `.geofenceId(...)`, `.address(...)` or `.coordinates(...)`. |
| `updateTrip(status: 'arrived', ...)` | `updateTrip(status: RadarTripStatus.arrived, ...)` |
| `updateTripLeg(status: 'arrived', ...)` | `updateTripLeg(status: RadarTripLegStatus.arrived, ...)` |
| `setNotificationOptions({...})` | `setNotificationOptions(RadarNotificationOptions(...))` |
| `setForegroundServiceOptions({...})` | `setForegroundServiceOptions(RadarForegroundServiceOptions(...))` |
| `showInAppMessage({...})` | `showInAppMessage(RadarInAppMessage(...))` |
| `setLogLevel('debug')` | `setLogLevel(RadarLogLevel.debug)` |
| `getPermissionsStatus()` returns a `String?` | returns a `RadarPermissionsStatus` |
| `desiredAccuracy: 'high'` | `desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.high` |
| `getLocation('high')` | `getLocation(desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.high)`. The argument is now named. |
| `mode: 'car'`, `modes: ['car']`, `units: 'imperial'` | `RadarRouteMode.car`, `{RadarRouteMode.car}`, `RadarRouteUnits.imperial` |
| Durations as numbers of seconds or minutes, such as `startTrackingVerified(30, false)`, `mockTracking(interval: 1)`, or `'desiredSyncInterval': 20` | `Duration`s: `startTrackingVerified(Duration(seconds: 30), false)`, `mockTracking(interval: Duration(seconds: 1))`, `desiredSyncInterval: Duration(seconds: 20)`. ETAs and other durations Radar returns are `Duration`s too. |
| `getTrackingOptions()`, `getTripOptions()`, `getTrip()` return a `Map?` | return `RadarTrackingOptions?`, `RadarTripOptions?`, `RadarTrip?` |

**Address validation.** `validateStreetAddress` and `validateAddressLabel` return a `RadarValidateAddressResult` with the address and its verification status.

**Listeners.** Each `Radar.onX` callback receives a typed update: `RadarLocationUpdate`, `RadarClientLocationUpdate`, `RadarEventsUpdate`, `RadarErrorUpdate`, `RadarLogUpdate`, `RadarTokenUpdate`, `RadarIpChangedUpdate`, and `RadarSharingChangedUpdate`. Most callbacks used to receive a `Map`. The `onIpChanged` callback used to take no arguments, and `onSharingChanged` took a `bool`; read it from `update.sharing` now. The `foregroundXCallback` static fields are no longer public, and the callback typedefs (`LocationCallback`, `ClientLocationCallback`, `ErrorCallback`, `LogCallback`, `EventsCallback`, `TokenCallback`, `IpChangedCallback`, `SharingChangedCallback`) are removed. Use the function types in the `onX` signatures instead.

```dart
// Before
Radar.onEvents((result) {
  final events = result['events'];
});

// After
Radar.onEvents((update) {
  for (final event in update.events) { ... }
});
```

**Background handler.** `RadarBackgroundEvent` and `RadarBackgroundEventType` are removed. The handler receives the same sealed `RadarUpdate` as the listeners, so it can `switch` over every update type. See the README.

## 4.0.0-beta.3 to 4.0.0-beta.4

`Radar.validateAddress()` has been removed, because both native SDKs deprecated it. Call `Radar.validateStreetAddress()` when you have a street and number, or `Radar.validateAddressLabel()` when you have a single-line address. Every argument except `unit` is required. Both return the same response as before.

```dart
// 4.0.0-beta.4
var resp = await Radar.validateStreetAddress(
    street: 'BROADWAY',
    number: '841',
    city: 'NEW YORK',
    stateCode: 'NY',
    postalCode: '10003',
    countryCode: 'US');
```

```dart
// 4.0.0-beta.3
var resp = await Radar.validateAddress({
    'street': 'BROADWAY',
    'number': '841',
    'city': 'NEW YORK',
    'stateCode': 'NY',
    'postalCode': '10003',
    'countryCode': 'US'});
```

The Radar Android SDK moves to `5.0.0`, which brings these changes from its `4.0.0` release:

- The SDK no longer declares `RadarForegroundService` in its manifest, so apps that only use geofencing don't ship a location foreground service. If you call `Radar.startTracking('continuous')`, set `foregroundServiceEnabled: true` in `Radar.startTrackingCustom()`, or enable the foreground service in remote tracking options, declare the service and the `FOREGROUND_SERVICE_LOCATION` permission in `android/app/src/main/AndroidManifest.xml`. If the service is not declared, the SDK logs an error and tracks without a foreground service, and Android may throttle background location.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
    <application>
        <service
            android:name="io.radar.sdk.RadarForegroundService"
            android:foregroundServiceType="location"
            tools:targetApi="26" />
    </application>
</manifest>
```

- The minimum Android API level is now 23. Apps with a lower `minSdkVersion` must raise it to 23.

On both platforms, event maps now omit `location` and `actualCreatedAt` when those values are absent. Conversion events can have no location. Check these fields for null before accessing nested values, for example `event['location']?['latitude']`, and handle a missing `actualCreatedAt` instead of assuming it is always present.

## 3.1.x to 3.2.0
- `Radar.setAdIdEnabled()` has been removed.
- Custom events have been renamed to conversions.
    - `Radar.sendEvent(customType, location, metadata)` is now `Radar.logConversion(name, revenue, metadata)`.
    - The method response does not include `location` and `user` props anymore.


```dart
// 3.2.0 - logging conversions
var resp = await Radar.logConversion(
    name: "in_app_purchase",
    revenue: 0.2,
    metadata: {"price": "150USD"});
```

```dart
// 3.1.x - sending events
var resp = await Radar.sendEvent(
    customType: "in_app_purchase",
    location: {
        "latitude": 35.0,
        "longitude": -75.0
    },
    metadata: {"price": "150USD"});
```
