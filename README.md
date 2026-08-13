![Radar](https://raw.githubusercontent.com/radarlabs/flutter-radar/master/logo.png)

[![npm](https://img.shields.io/pub/v/flutter_radar)](https://pub.dev/packages/flutter_radar)

[Radar](https://radar.com) is the leading geofencing and location tracking platform.

The Radar SDK abstracts away cross-platform differences between location services, allowing you to add geofencing, location tracking, trip tracking, geocoding, and search to your apps with just a few lines of code.

## Documentation

See the Radar overview documentation [here](https://radar.com/documentation).

Then, see the Flutter package documentation [here](https://radar.com/documentation/sdk/flutter).

## Background event delivery

Use `Radar.registerBackgroundHandler()` to receive Radar events through a durable handler across foreground, background, and headless execution.

The handler must be a top-level or static function annotated with `@pragma('vm:entry-point')` so Flutter can invoke it after the primary Flutter engine has been terminated.

```dart
@pragma('vm:entry-point')
Future<void> radarBackgroundHandler(RadarBackgroundEvent event) async {
  switch (event.type) {
    case RadarBackgroundEventType.location:
    case RadarBackgroundEventType.clientLocation:
    case RadarBackgroundEventType.events:
    case RadarBackgroundEventType.error:
    case RadarBackgroundEventType.log:
    case RadarBackgroundEventType.token:
    case RadarBackgroundEventType.ipChanged:
    case RadarBackgroundEventType.sharingChanged:
      print('Radar background event: ${event.type.name} ${event.payload}');
  }
}

Future<void> initializeRadar() async {
  await Radar.initialize('prj_live_pk_...');
  await Radar.registerBackgroundHandler(radarBackgroundHandler);
}
```

Call `Radar.registerBackgroundHandler()` during normal Dart application initialization. No custom Android `Application` or iOS `AppDelegate` setup is required.

The durable background handler and existing `Radar.onX` listeners are independent subscriptions:

- The registered background handler is the durable event sink and can run in the primary Flutter engine or a headless engine.
- `Radar.onX` listeners are engine-scoped observers intended for active application or UI behavior.
- When both are registered on a running engine, both may receive the same underlying event.
- Durable events are delivered serially and queued until the appropriate Dart handler is ready.

Call `Radar.unregisterBackgroundHandler()` to remove the persisted handler and stop durable event delivery.

## Examples

See an example app in `example/`.

## Support

Have questions? We're here to help! Email us at [support@radar.com](mailto:support@radar.com).
