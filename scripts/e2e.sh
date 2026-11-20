#!/usr/bin/env bash
# Runs the e2e suite in example/integration_test on a booted iOS simulator or
# Android emulator, against the project in example/.env.e2e.
#
#   scripts/e2e.sh ios <simulator-udid>
#   scripts/e2e.sh android <emulator-serial>     # e.g. emulator-5554
#
# Extra arguments are passed to `flutter test` (e.g. --plain-name trackOnce).
# Set FLUTTER to use a specific Flutter binary (e.g. an fvm version), and ADB
# if adb isn't on PATH or in $ANDROID_HOME/platform-tools.
#
# Before running the tests this grants the example app location permission
# and sets the simulated location, so the tests that need device location run.
# Granting needs the app installed, so the first run builds and installs it.
set -euo pipefail

usage() {
  echo "usage: $0 <ios|android> <device-id> [flutter test args...]" >&2
  exit 64
}

[[ $# -ge 2 ]] || usage
platform=$1
device=$2
shift 2

repo_root=$(cd "$(dirname "$0")/.." && pwd)
example_dir="$repo_root/example"
env_file="$example_dir/.env.e2e"
flutter=${FLUTTER:-flutter}
adb=${ADB:-$(command -v adb || echo "${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb")}
bundle_id=io.radar.example
latitude=40.7342
longitude=-73.9911

if [[ ! -f $env_file ]]; then
  echo "Missing $env_file. Copy example/.env.e2e.example and fill it in." >&2
  exit 1
fi
if ! grep -Eq '^RADAR_PUBLISHABLE_KEY=.+' "$env_file"; then
  echo "RADAR_PUBLISHABLE_KEY is empty in $env_file." >&2
  exit 1
fi

cd "$example_dir"

case $platform in
  ios)
    if ! xcrun simctl get_app_container "$device" "$bundle_id" >/dev/null 2>&1; then
      echo "Installing the example app so location permission can be granted..."
      "$flutter" build ios --simulator --debug
      xcrun simctl install "$device" build/ios/iphonesimulator/Runner.app
    fi
    xcrun simctl privacy "$device" grant location-always "$bundle_id"
    xcrun simctl location "$device" set "$latitude,$longitude"
    ;;
  android)
    adb_cmd=("$adb" -s "$device")
    if ! "${adb_cmd[@]}" shell pm path "$bundle_id" >/dev/null 2>&1; then
      echo "Installing the example app so location permission can be granted..."
      "$flutter" build apk --debug
      "${adb_cmd[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk
    fi
    for permission in ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION ACCESS_BACKGROUND_LOCATION; do
      # ACCESS_BACKGROUND_LOCATION doesn't exist before API 29; ignore that.
      "${adb_cmd[@]}" shell pm grant "$bundle_id" "android.permission.$permission" || true
    done
    "${adb_cmd[@]}" emu geo fix "$longitude" "$latitude"
    ;;
  *)
    usage
    ;;
esac

# flutter test uninstalls the app afterwards by default, which wipes the keys
# and environment saved in the app's Settings. Keep it installed where the
# flag exists (it's missing from older Flutter versions such as 3.29).
keep_installed=()
if "$flutter" test -h 2>/dev/null | grep -q -- '--\[no-\]uninstall'; then
  keep_installed=(--no-uninstall)
fi

exec "$flutter" test integration_test/radar_e2e_test.dart \
  -d "$device" \
  --dart-define-from-file=.env.e2e \
  ${keep_installed[@]+"${keep_installed[@]}"} \
  "$@"
