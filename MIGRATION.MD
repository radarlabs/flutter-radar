# Migration guides

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
// 3.1.x - logging conversions
var resp = await Radar.sendEvent(
    customType: "in_app_purchase",
    location: {
        "latitude": 35.0,
        "longitude": -75.0
    },
    metadata: {"price": "150USD"});
```
