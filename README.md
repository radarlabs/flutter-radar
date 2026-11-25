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
Future<void> radarBackgroundHandler(RadarUpdate update) async {
  switch (update) {
    case RadarEventsUpdate(:final events, :final user):
      for (final event in events) {
        print('Radar event: ${event.type} for ${user?.userId}');
      }
    case RadarLocationUpdate(:final location):
      print('Radar location: $location');
    case RadarErrorUpdate(:final status):
      print('Radar error: $status');
    case RadarClientLocationUpdate() ||
        RadarLogUpdate() ||
        RadarTokenUpdate() ||
        RadarIpChangedUpdate() ||
        RadarSharingChangedUpdate():
      break;
  }
}

Future<void> initializeRadar() async {
  await Radar.initialize('prj_live_pk_...');
  await Radar.registerBackgroundHandler(radarBackgroundHandler);
}
```

Call `Radar.registerBackgroundHandler()` during normal Dart application initialization. No custom Android `Application` or iOS `AppDelegate` setup is required.

To react to updates while the app is running, listen to a `Radar.onX` stream, such as `Radar.onLocation` or `Radar.onEvents`. Each is a broadcast stream, so any number of listeners can subscribe, and updates that arrive with no listener are dropped.

```dart
final subscription = Radar.onEvents.listen((update) {
  for (final event in update.events) {
    print(event.type);
  }
});

// Later, to stop listening:
await subscription.cancel();
```

Cancel a subscription when whatever owns it goes away, such as in a `State`'s `dispose`. To show the latest update in the UI, pass the stream to a `StreamBuilder`, which subscribes and cancels for you:

```dart
StreamBuilder<RadarLocationUpdate>(
  stream: Radar.onLocation,
  builder: (context, snapshot) {
    final location = snapshot.data?.location;
    return Text(location == null
        ? 'Waiting for a location'
        : '${location.latitude}, ${location.longitude}');
  },
)
```

The durable background handler and the `Radar.onX` streams are independent subscriptions:

- The registered background handler is the durable event sink and can run in the primary Flutter engine or a headless engine.
- `Radar.onX` streams are engine-scoped observers intended for active application or UI behavior.
- When both are registered on a running engine, both may receive the same underlying event.
- Durable events are delivered serially and queued until the appropriate Dart handler is ready.

Call `Radar.unregisterBackgroundHandler()` to remove the persisted handler and stop durable event delivery.

## Examples

See an example app in `example/`.

## Support

Have questions? We're here to help! Email us at [support@radar.com](mailto:support@radar.com).
