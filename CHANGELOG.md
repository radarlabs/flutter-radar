# 3.9.1

- Bump iOS version from 3.9.7 to 3.9.12
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
