#!/usr/bin/env bash
# Session-end housekeeping: stop relays, reset the simulator, free disk space.
# Pass --quit-xcode to also quit Xcode (off by default so unsaved editor state survives).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Stopping log relays, stray Sift processes and project builds…"
pkill -f "idevicesyslog" 2>/dev/null || true
pkill -f "Sift.app/Sift" 2>/dev/null || true
pkill -f "xcodebuild.*Sift.xcodeproj" 2>/dev/null || true

SIFT_SIM="59D0DE9D-157A-4F7B-BEA3-2AD9E47D4D59"
echo "Resetting Sift simulator UI and shutting it down…"
xcrun simctl ui "$SIFT_SIM" appearance light 2>/dev/null || true
xcrun simctl ui "$SIFT_SIM" content_size large 2>/dev/null || true
xcrun simctl shutdown "$SIFT_SIM" 2>/dev/null || true

if [ "${1:-}" = "--quit-xcode" ]; then
  echo "Quitting Xcode…"
  osascript -e 'tell application "Xcode" to quit' 2>/dev/null || true
fi

echo "Quitting Simulator.app…"
osascript -e 'tell application "Simulator" to quit' 2>/dev/null || true

echo "Removing temporary diagnostics (build/ is gitignored)…"
rm -rf build/device-crashes build/xcattach build/xcattach-final build/xcattach-light
rm -f build/clipboard.png build/clipboard.swift build/device-syslog.log \
      build/idevicesyslog.out build/console.pid build/sift-syslog.pid \
      build/launch-attempt.log build/device-console.log

echo "Done. Project sources and docs are untouched."
