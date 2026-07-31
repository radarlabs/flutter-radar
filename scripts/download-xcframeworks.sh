#!/bin/bash
set -e

SDK_VERSION="${1:-3.38.0}"
FRAUD_VERSION="${2:-1.3.0}"

SDK_SHA256="8ee64edcd7b4391e90a0302bfcf158d717a5b337834bfded8f9b7097c5612b75"
MOTION_SHA256="c5c2f5f007d0ae03f7eeefa277839fde826d6eb168834911228d12e0294ab35e"
FRAUD_SHA256="cc344d59d4bd1127748dcbc52bd864844596d38e35234d3ca4829c9493708483"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST="$PROJECT_ROOT/ios/Frameworks"

rm -rf "$DEST" && mkdir -p "$DEST"

fetch () { # name url expected_sha
  local name="$1" url="$2" sha="$3" zip="/tmp/$1.zip"
  echo "Downloading $name ..."
  curl -fsSL -o "$zip" "$url"
  local actual; actual=$(shasum -a 256 "$zip" | awk '{print $1}')
  [ "$actual" = "$sha" ] || { echo "ERROR: $name sha256 mismatch (expected $sha, got $actual)"; exit 1; }
  unzip -q "$zip" -d "$DEST/"
  rm -f "$zip"
}

fetch "RadarSDK" \
  "https://github.com/radarlabs/radar-sdk-ios/releases/download/${SDK_VERSION}/RadarSDK.xcframework.zip" \
  "$SDK_SHA256"
fetch "RadarSDKMotion" \
  "https://github.com/radarlabs/radar-sdk-ios/releases/download/${SDK_VERSION}/RadarSDKMotion.xcframework.zip" \
  "$MOTION_SHA256"
fetch "RadarSDKFraud" \
  "https://github.com/radarlabs/radar-sdk-ios-fraud-spm/releases/download/${FRAUD_VERSION}/RadarSDKFraud.xcframework.zip" \
  "$FRAUD_SHA256"

echo "Done: RadarSDK@${SDK_VERSION}, RadarSDKMotion@${SDK_VERSION}, RadarSDKFraud@${FRAUD_VERSION} in ${DEST}/"