#!/usr/bin/env bash
# Build the latest Debug app and install it on the physical iPhone 12.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEVICE="CB38B173-19F9-500D-94AE-B5267C99489E"

xcodebuild -project Sift.xcodeproj -scheme Sift -configuration Debug \
  -destination 'generic/platform=iOS' -allowProvisioningUpdates build

APP="$(ls -td "$HOME"/Library/Developer/Xcode/DerivedData/Sift-*/Build/Products/Debug-iphoneos/Sift.app 2>/dev/null | head -1)"
if [ -z "$APP" ]; then
  echo "No device build found." >&2
  exit 1
fi

xcrun devicectl device install app --device "$DEVICE" "$APP"

cat <<'EOF'
Installed.
If iOS asks for developer trust: tap Sift on the Home Screen, choose "Einstellungen"
in the alert (not "Abbrechen"), then "Vertrauen". devicectl cannot show that prompt.
EOF
