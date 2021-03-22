# 3.0.3

- Correctly parses the `background` flag in `requestPermissions(background)` on iOS.

# 3.0.2

- Adds `s.static_framework = true` to the plugin podfile.

# 3.0.1

- Supports `startForegroundService({'clickable': true})` to make the foreground service notification clickable, or `startForegroundService({'clickable': false})` to make it not clickable. Default is `false`.

# 3.0.0

- Updates `requestPermissions(background)` to complete only when the permissions request completes.
- Updates `startForegroundService(foregroundServiceOptions)` to use `BigTextStyle` on Android.