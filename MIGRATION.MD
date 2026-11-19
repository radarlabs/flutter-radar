# Migration guides

## 4.0.0-beta.3 to 4.0.0-beta.4

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
