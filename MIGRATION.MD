# Migration guides

## 3.1.x to 3.2.0
- The `Radar.setAdIdEnabled()` method has been removed.
- Custom events have been renamed to conversions.
    - `Radar.sendEvent(customType, location, metadata)` is now `Radar.logConversion(name, revenue, metadata)`.
    - The method response does not include `location` and `user` props anymore.
- `Radar.autocomplete()` method has another optional param `expandUnits`
- Fruad detection has been introduced
    - `Radar.trackVerified()` has been added, but need to follow this instruction for both android and ios setup. See the [Fraud documentation](https://radar.com/documentation/fraud)
- The SDK depends on Google Play Services Location version 21.0.1. See the [Android setup documentation](https://radar.com/documentation/sdk/android)
