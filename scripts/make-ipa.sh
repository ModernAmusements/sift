#!/usr/bin/env bash
# Build an unsigned Release IPA and publish it into docs/ (the GitHub Pages site).
# Signing is deliberately disabled: the IPA is re-signed by the user in AltStore,
# SideStore or Xcode with their own Apple ID.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="$(awk '/MARKETING_VERSION:/ {print $2}' project.yml | tr -d '"')"
BUILD="$(awk '/CURRENT_PROJECT_VERSION:/ {print $2}' project.yml | tr -d '"')"
IPA="docs/Sift-${VERSION}-unsigned.ipa"
DERIVED="build/ipa-derived"
STAGE="build/ipa"

echo "Building Sift ${VERSION} (${BUILD}) unsigned…"
rm -rf "$DERIVED" "$STAGE"
xcodebuild -project Sift.xcodeproj -scheme Sift -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build

APP="$DERIVED/Build/Products/Release-iphoneos/Sift.app"
if [ ! -d "$APP" ]; then
  echo "No app bundle at $APP" >&2
  exit 1
fi

mkdir -p "$STAGE/Payload"
cp -R "$APP" "$STAGE/Payload/Sift.app"

echo "Packaging ${IPA} ..."
rm -f "$IPA"
(cd "$STAGE" && zip -qry "$ROOT/$IPA" Payload)
shasum -a 256 "$IPA" | tee "${IPA}.sha256"

echo
echo "IPA:     $IPA ($(wc -c < "$IPA" | tr -d ' ') bytes)"
echo "SHA-256: $(cut -d' ' -f1 "$IPA.sha256")"
echo
echo "Next: update docs/source.json (versions[0].size, downloadURL) and the"
echo "release links in README.md / docs/INSTALL.md / docs/index.html."
