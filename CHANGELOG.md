# 4.0.0-beta.4

- Updates the Radar iOS SDK from `3.38.0` to `4.0.0`.
- Updates the Radar Android SDK from `3.36.1` to `5.0.0`.
- Raises the minimum Android API level from `21` to `23`, which the Radar Android SDK `5.0.0` requires.
- Adds `Radar.validateAddressWithStreet()` and `Radar.validateAddressWithAddressLabel()`. `Radar.validateAddress()` still works, and is deprecated in both native SDKs.
- Adds `Radar.startRangingBeacons()` and `Radar.stopRangingBeacons()`.
- Adds `Radar.setExpectedAddress()`, returned as `user.expectedAddress` on track responses.
- Returns `format` on `trackVerified()`, `getVerifiedLocationToken()`, and `revealRisk()` responses, and `locationInsights` on `user` on iOS.
- Adds the `user.entered_home`, `user.exited_home`, `user.entered_work`, `user.exited_work`, `user.started_traveling`, `user.stopped_traveling`, `user.started_commuting`, and `user.stopped_commuting` events on iOS.
- Updates `Radar.autocomplete()` and `Radar.ipGeocode()` on Android for the APIs the Radar Android SDK `4.0.0` removed.
- Returns a response without a `token` instead of an error when the Radar Android SDK cannot parse a verified location token.
- Declares `io.radar.sdk.RadarForegroundService` in the Example app manifest, which the Radar Android SDK `4.0.0` no longer declares.

# 4.0.0-beta.3

- Updates optional `near` location handling for `Radar.autocomplete()`, `Radar.searchPlaces()`, and `Radar.searchGeofences()` on Android and iOS.
- Updates `Radar.trackOnce()` on iOS to keep beacon ranging disabled when `beacons` is `false` or omitted.

# 4.0.0-beta.2

- Updates Android compilation to allow applications to call Radar SDK APIs from native code.

# 4.0.0-beta.1

- Raises the minimum supported versions to Flutter 3.29.0 and Dart 3.7.0.
- Adds durable Radar event delivery across foreground, background, and headless execution on Android and iOS.
- Adds `Radar.registerBackgroundHandler()` and `Radar.unregisterBackgroundHandler()`.
- Keeps existing `Radar.onX` listeners as independent engine-scoped observers.
- Removes the need for custom Radar initialization in the Android `Application` or iOS `AppDelegate`; applications continue to call `Radar.initialize()` from Dart.
- Exposes additional Radar SDK methods and initialization options.
- Updates the Android build toolchain to Gradle 8.14, Android Gradle Plugin 8.11.1, and Kotlin 2.2.20.

# 3.23.4
- Updates iOS and Android sdk to 3.23.4 and 3.23.5, respectively

# 3.12.4
- Fixes breaking change on Flutter 3.29.0 by removing v1 embedding

# 3.12.3
- Improves edge-case handling of replayed locations.
- Expands functionality of notification analytics.
- Returns the full token payload in `RadarVerifiedLocationToken`
- Bump iOS version from 3.18.3 to 3.19.5
- Bump Android version from 3.18.1 to 3.18.10

# 3.12.2
- Patch `getLocation` method for iOS

# 3.12.1

- Bump iOS version from 3.18.2 to 3.18.3

# 3.12.0

- Bump iOS version from 3.17.0 to 3.18.2
- Bump Android version from 3.17.0 to 3.18.1
- Add `getVerifiedLocationToken`

# 3.11.0

- Bump iOS version from 3.15.0 to 3.17.0
- Bump Android version from 3.15.0 to 3.17.0

# 3.10.0

- Bump iOS version from 3.9.14 to 3.15.0
- Bump Android version from 3.9.8 to 3.15.0

# 3.9.1

- Bump iOS version from 3.9.7 to 3.9.14
- Bump Android version from 3.9.4 to 3.9.8

# 3.9.0

- Bump iOS version from 3.8.9 to 3.9.6
- Bump Android version from 3.8.12 to 3.9.4
- Add `beacons` param to `trackVerified` and `trackVerifiedToken`
- Add `startTrackingVerified`
- Add `token` listener
- Add lifecycle methods `logTermination`, `logBackgrounding`, and `logResigningActive`
- Add `setNotificationOptions` for Android

# 3.8.1

- Update github release action

# 3.8.0

- Bump iOS version from 3.5.9 to 3.8.9
- Bump android version from 3.5.9 to 3.8.12
- remove `setAdIdEnabled`
- rename `sendEvent` to `logConversion` and add `revenue` param
- add `trackVerified`
- add `trackVerifiedToken`
- add `isUsingRemoteTrackingOptions`
- update `autocompleteQuery` with param add `expandUnits`
- add `validateAddress`
- add `App Attest` to ios example
- add `Play Integrity API` to android example
- update example project

# 3.1.7

- Update ios event channel
- Updates an example project

# 3.1.6

- Fixes event listeners
- Updates an example project
  
# 3.1.5

- Exposes `Radar.setForegroundServiceOptions()`. `Radar.startForegroundService()` and `Radar.stopForegroundService()` are no longer available.

```dart
Radar.setForegroundServiceOptions({
  'title': 'Tracking',
  'text': 'Trip tracking started',
  'icon': 2131165271,
  'importance': 2,
  'updatesOnly': false,
  'activity': 'io.radar.example.MainActivity'
});
```

# 3.1.4

- Exposes `Radar.setForegroundServiceOptions()`.

# 3.1.3

- Upgrades `radar-sdk-android` to `3.5.9` and `radar-sdk-ios` to `3.5.9`. Exposes all remaining SDK functions.

# 3.1.2

- Fixes a typo in a constant.

# 3.1.1

- Upgrades the Radar iOS SDK to `3.1.5`.

# 3.1.0

- Upgrades the Radar SDK to `3.1.x`.

# 3.0.3

- Correctly parses the `background` flag in `requestPermissions(background)` on iOS.

# 3.0.2

- Adds `s.static_framework = true` to the plugin podfile.

# 3.0.1

- Supports `startForegroundService({'clickable': true})` to make the foreground service notification clickable, or `startForegroundService({'clickable': false})` to make it not clickable. Default is `false`.

# 3.0.0

- Updates `requestPermissions(background)` to complete only when the permissions request completes.
- Updates `startForegroundService(foregroundServiceOptions)` to use `BigTextStyle` on Android.
