# flutter_radar_example

## End-to-end tests

`integration_test/radar_e2e_test.dart` runs the real plugin, native SDKs and
Radar API on a simulator or emulator. It covers most of the API that works
with a publishable key:

- local state, such as the user fields, product and language
- tracking with an explicit or a device location, including starting and
  stopping tracking with preset and custom options
- the `onLocation`, `onClientLocation` and `onLog` callbacks
- geocoding, search, context, routing, conversions and address validation
- trips
- the platform-specific methods, such as the app lifecycle logs, which only
  check that each call completes
- with geofences in the project: geofence entry and exit events and
  `onEvents`, accepting and rejecting events, and trips to geofence
  destinations, including multi-leg trips

The `trackVerified` tests also run when verified tracking is enabled, and the
geofence tests when the project has geofences tagged `e2e-test` (see Setup).
Methods that need extra hardware or project setup, such as beacons, aren't
covered.

### Setup

1. Copy `.env.e2e.example` to `.env.e2e` (gitignored) and set
   `RADAR_PUBLISHABLE_KEY`. A test key for a fairly standard project is
   enough. To test against staging or a local server, set `RADAR_HOST` and
   `RADAR_VERIFIED_HOST` too.
2. To run the `trackVerified` tests, set `RADAR_E2E_VERIFIED=true`. The
   project needs verified tracking enabled, and the hosts must be production:
   the bundled fraud SDK can't yet override its payload encryption key for
   other servers.
3. To run the geofence tests, create two circle geofences tagged `e2e-test`,
   with distinct `externalId`s, whose centers are within 10 km of the test
   location (40.7342, -73.9911). Keep them a few hundred meters from that
   location and from each other, so the tests can track outside and inside
   each one. To use a different tag, set `RADAR_E2E_GEOFENCE_TAG`. Without the
   geofences, these tests are skipped. The multi-leg trip test also needs
   multi-destination trips enabled for the project; without that, the API
   ignores the legs and the test is skipped.
4. Boot an iOS simulator or Android emulator.

### Running

From the repo root:

```sh
scripts/e2e.sh ios <simulator-udid>       # xcrun simctl list devices booted
scripts/e2e.sh android <emulator-serial>  # adb devices, e.g. emulator-5554
```

The script grants the example app location permission and sets the simulated
location (installing the app first if needed), then runs `flutter test` with
`--dart-define-from-file=.env.e2e`. Extra arguments go to `flutter test`, e.g.
`--plain-name trackVerified`.

Without a publishable key, every test is skipped. Without location permission,
only the tests that need device location are skipped.

Each run uses a new user ID, `flutter-e2e-<platform>-<epoch ms>`, printed at the
start of the run. Search for it in the dashboard to see the run's tracks, trips
and conversions.

On a simulator or emulator, `trackVerified` returns a token, but `passed` is
usually `false` because attestation fails there. The tests check only that the
field is present.

The suite sets the API host with `setRadarHosts` from `lib/environment.dart`,
the same code the app's Settings page uses. It writes the storage keys the
native SDKs read the host from; there is no public SDK API for it. A run
overwrites the host the app last saved; the app rewrites it on its next launch.
