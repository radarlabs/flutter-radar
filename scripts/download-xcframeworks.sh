#!/bin/bash
set -e

# The vendored versions and the sha256 of each release zip;
# scripts/native-sdk-sync.mjs updates these lines.
SDK_VERSION="4.0.0"
SDK_SHA256="979e70c1253ad2da8743074215fd1639e939d57297a8a1e53e570dfb3c28480d"
MOTION_SHA256="ff40c2344c787c0edf08a1d8201e682fa89f19113170ab976f0069d4e0fca298"
FRAUD_VERSION="1.6.0"
FRAUD_SHA256="44346d9a8e67b473c7042750a122f29b55b0d03c0f5291948239d833c36e7bf4"

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