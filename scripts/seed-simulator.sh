#!/usr/bin/env bash
set -euo pipefail

DEVICE="${1:-Sift iPhone 12}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p build/testmedia
swift scripts/make-test-media.swift

if [ ! -f build/testmedia/Clip-2026.mp4 ]; then
  ffmpeg -y -loglevel error \
    -f lavfi -i "testsrc2=size=1920x1080:rate=30:duration=65" \
    -c:v libx264 -preset veryfast -b:v 12M -pix_fmt yuv420p \
    build/testmedia/Clip-2026.mp4
fi

xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl addmedia "$DEVICE" build/testmedia/*.jpg build/testmedia/*.png build/testmedia/*.mp4
echo "Seeded $(find build/testmedia -type f | wc -l | tr -d ' ') files into $DEVICE"
