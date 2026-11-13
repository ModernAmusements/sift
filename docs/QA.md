# QA — Sift 1.0.0

Verified 2026-11-13 on macOS 26 with Xcode 26.0 (17A324), iPhone 12 simulator (iOS 18.4).

## Automated

| Suite | Tests | Result |
| --- | --- | --- |
| `SiftTests` (unit) | 15 | Passed |
| `SiftUITests/testOnboarding` | 1 | Passed |
| `SiftUITests/testScanAndBrowse` | 1 | Passed |
| `SiftUITests/testContactMerge` | 1 | Passed |
| `SiftUITests/testDeleteScreenshots` | 1 | Passed |

Commands:

```bash
xcodegen generate
xcodebuild -project Sift.xcodeproj -scheme Sift \
  -destination 'id=<iPhone 12 simulator>' build
xcodebuild -project Sift.xcodeproj -scheme Sift \
  -destination 'id=<iPhone 12 simulator>' test
```

For the deterministic UI run, build once, grant permissions, then `test-without-building` (Xcode's test install resets TCC):

```bash
xcodebuild ... build-for-testing
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/Sift.app
xcrun simctl privacy booted grant photos dev.modernamusement.sift
xcrun simctl privacy booted grant contacts dev.modernamusement.sift
xcodebuild ... test-without-building
```

## Flows exercised

1. **Onboarding** — first launch, privacy copy, Get started → home.
2. **Scan** — 18 seeded items; progress, cancellation path available, results published in under ~5 s on the simulator.
3. **Screenshots** — 3 fixtures, select all, PhotoKit system confirmation, deletion.
4. **Duplicates** — one byte-identical pair grouped; five similar scene variants correctly *not* treated as exact duplicates after calibration.
5. **Similar photos** — feature-print clustering; two groups (landscape variants and the three screenshot fixtures before they were excluded by the fixture subtype).
6. **Blurry photos** — both seeded blurred images found; sharp images excluded.
7. **Large videos** — the 65 s / 97.5 MB clip found.
8. **Swipe review** — deck layout, keep/delete controls, progress, undo state.
9. **Contacts** — 3 duplicate groups found from seeded cards; Ada Lovelace merged from 3 cards into 1; list dropped to 2 groups.
10. **Settings** — sensitivity, last scan, permission statuses, privacy links, version.
11. **Deletion refresh** — library went 18 → 15 after deleting 3 screenshots; the home screen updated without a rescan; `0 screenshots`.

## Evidence

Screenshots are in [`docs/screenshots/`](screenshots/). Deletion and merge evidence is in [`docs/qa/`](qa/):

- `contacts-before-merge.png`
- `contact-merge-sheet.png`
- `contacts-after-merge.png`
- `screenshots-before-delete.png`
- `after-delete.png`

## Static checks

```bash
grep -rnE "URLSession|URLRequest|NWConnection|WKWebView|Analytics|Firebase|Sentry" Sift
# no matches

plutil -p build/Build/Products/Debug-iphonesimulator/Sift.app/Info.plist | \
  grep -E "NSPhotoLibrary|NSContacts"
# usage strings present

plutil -p build/Build/Products/Debug-iphonesimulator/Sift.app/PrivacyInfo.xcprivacy
# NSPrivacyTracking = false, no collected data
```

## Known gaps

- No physical-device run in this environment. Deletion, permissions and Vision can differ subtly from the simulator. Do one device pass before an App Store submission.
- Vision feature prints return nil in the iOS 18.4 Simulator; the color-mosaic fallback was exercised. Real devices use the Vision path. The fallback is deliberately conservative (threshold 0.66 × the slider value).
- PhotoKit gives imported simulator images no screenshot subtype. UI tests use the DEBUG-only `-uiFixtures` dimension check; Release builds use only `PHAssetMediaSubtype.photoScreenshot`.
- Denied and limited photo permission screens were implemented and code-reviewed but not part of the automated screenshot set.
- Contacts merging was verified locally in the simulator. iCloud sync of the deletion was not tested.
- Dark mode was implemented and spot-checked; the committed screenshots are light mode.
