#!/usr/bin/env bash
#
# Rebuild Blink, sign it with a free Apple Developer "Personal Team", and
# install it on a USB-connected iOS device.
#
# A Personal Team's provisioning profile lasts 7 days. Re-run this script when
# the app stops launching; that is the only maintenance it needs.
#
# Prerequisites:
#   - Xcode, signed in under Xcode > Settings > Accounts
#   - ./get_frameworks.sh && ./get_resources.sh run once
#   - developer_setup.xcconfig present (copy template_setup.xcconfig)
#   - brew install libimobiledevice
#   - Developer Mode enabled on the device

set -euo pipefail

cd "$(dirname "$0")/.."

TEAM_ID="${TEAM_ID:-$(sed -n 's/^TEAM_ID = //p' developer_setup.xcconfig | tr -d ' ')}"
BUNDLE_ID="${BUNDLE_ID:-$(sed -n 's/^BUNDLE_ID = //p' developer_setup.xcconfig | tr -d ' ')}"
DEVICE="${DEVICE:-$(idevice_id -l | head -1)}"
DERIVED_DATA="${DERIVED_DATA:-build-signed}"

if [ -z "$TEAM_ID" ]; then
  echo "TEAM_ID not set and not found in developer_setup.xcconfig" >&2
  exit 1
fi
if [ -z "$DEVICE" ]; then
  echo "No device found. Connect one over USB and trust this computer." >&2
  exit 1
fi

echo "==> Building for device $DEVICE (team $TEAM_ID)"
xcodebuild \
  -project Blink.xcodeproj \
  -scheme Blink \
  -configuration Release \
  -destination "platform=iOS,id=$DEVICE" \
  -derivedDataPath "$DERIVED_DATA" \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  build

APP="$DERIVED_DATA/Build/Products/Release-iphoneos/Blink.app"

echo "==> Profile expires: $(
  security cms -D -i "$APP/embedded.mobileprovision" 2>/dev/null \
    | plutil -extract ExpirationDate raw -o - -
)"

echo "==> Installing"
xcrun devicectl device install app --device "$DEVICE" "$APP"

echo "==> Launching"
xcrun devicectl device process launch --device "$DEVICE" "$BUNDLE_ID"

echo "==> Done. If the app refuses to launch, trust the certificate on the device:"
echo "    Settings > General > VPN & Device Management"
