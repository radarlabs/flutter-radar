# Migration guides

## 3.1.x to 3.2.0
- `Radar.setAdIdEnabled()` has been removed.
- Custom events have been renamed to conversions.
    - `Radar.sendEvent(customType, location, metadata)` is now `Radar.logConversion(name, revenue, metadata)`.
    - The method response does not include `location` and `user` props anymore.

