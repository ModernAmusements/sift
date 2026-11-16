# QA — Sift 1.2.0

Verified 2026-11-16 on macOS 26 with Xcode 26.0 (17A324), `Sift iPhone 12` simulator (iOS 18.4).

## Automated

| Suite | Tests | Result |
| --- | --- | --- |
| `SiftTests` (unit) | 40 | Passed |
| `SiftUITests/testOnboarding` | 1 | Passed |
| `SiftUITests/testScanAndBrowse` | 1 | Passed |
| `SiftUITests/testContactMerge` | 1 | Passed |
| `SiftUITests/testDeleteScreenshots` | 1 | Passed (incl. proof sheet) |
| `SiftUITests/testCheckInBaselineOnFirstRun` | 1 | Passed |
| `SiftUITests/testCheckInReportsMeasuredDeltaWithoutClaimingCredit` | 1 | Passed |
| `SiftUITests/testPhoneHealthOnlyClaimsWhatIOSExposes` | 1 | Passed |

The three 1.2 UI tests were also run with dark appearance and accessibility XXXL text: 3/3 passed (before the navigation/glass pass).

The final design pass (native navigation, Liquid Glass, scan-start spinner, adaptive storage card) rebuilt and reran the full suite: 40 unit + 7 UI, 0 failures. `01-home.png` and `10-settings.png` were recaptured from that run.

Commands:

```bash
xcodegen generate
xcodebuild -project Sift.xcodeproj -scheme Sift \
  -destination 'platform=iOS Simulator,id=59D0DE9D-157A-4F7B-BEA3-2AD9E47D4D59' build
xcodebuild -project Sift.xcodeproj -scheme Sift \
  -destination 'platform=iOS Simulator,id=59D0DE9D-157A-4F7B-BEA3-2AD9E47D4D59' test
./scripts/deploy-device.sh     # build + install on the iPhone
./scripts/housekeeping.sh      # session end: simulators, relays, temp files
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
5. **Similar photos** — same-day clustering found one landscape group; screenshots are excluded from similarity by subtype.
6. **Blurry photos** — both seeded blurred images found; sharp images excluded.
7. **Large files** — the 65 s / 97.5 MB clip found in the combined photo/video list.
8. **Swipe review** — deck layout, keep/delete controls, progress, undo state.
9. **Contacts** — 2 duplicate groups found from cleaned seeded cards; Ada Lovelace merged from 3 cards into 1; list dropped to 1 group.
10. **Settings** — sensitivity, last scan, permission statuses, privacy links, version.
11. **Deletion refresh** — library went 18 → 15 after deleting 3 screenshots; the home screen updated without a rescan; `0 screenshots`.
12. **Files & documents** — empty state rendered; the picker itself was not UI-automated; the file model was unit-tested with real temporary files (2 KB + 4 KB), deleted one and kept the other.
13. **System data** — guide renders the sandbox explanation and the eight user steps.
14. **Cache** — Settings shows Sift's temporary bytes and a clear action; clearing never touches photos or contacts.
15. **Check-in baseline** — first run (`-resetLedger`) shows `Baseline saved. Sift shows the real change next time.`; no number is invented.
16. **Check-in delta** — a seeded earlier reading (`-seedLedgerBackGB 3`) yields `3.0 GB came back since <day>` plus `iOS returned space. Sift moved nothing this time.`; Sift never takes credit for space it did not move.
17. **Phone health** — free space (with Critical/Tight word), Low Power Mode, thermal state, library size and the battery-health explanation. The only mentions of boost/RAM are the sentence that denies them; no "junk"/"optimize" copy.
18. **Proof after a delete session** — the proof sheet opens with `Moved <size>. Freed so far: 0 bytes.`, the Recently Deleted steps, `Check again`, and the manual fallback. Verified copy appears only after a later measurement proves a gain.
19. **Reclaimed in Settings** — reads `Nothing verified yet` until a measured gain exists; footer states that moving to Recently Deleted is not freeing.
20. **Design pass** — native large navigation title and toolbar on Home, Liquid Glass primary/secondary buttons and scan panel on iOS 26 (flat fallback on iOS 17–25), indeterminate spinner instead of a fake 0% while photos are fetched, numeric-text transitions on measurements, and an adaptive storage card (`ViewThatFits`) for narrow widths and large type.

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

## Device pass

First install on real hardware: 2026-11-16.

- Device: `Shadys iPhone`, iPhone 12 (`iPhone13,2`), iOS 26.6.2, Developer Mode on.
- Signed with the free **Personal Team** (`QG32S7GZ56`); provisioning profile expires **2026-11-23**, so the build needs re-signing weekly until a paid team is used.
- Build + install path: `xcodebuild -destination 'generic/platform=iOS' -allowProvisioningUpdates build` (team comes from `Config/Local.xcconfig`), then `xcrun devicectl device install app`. `devicectl` enables the developer disk image services itself.
- Trust: tap the Sift icon, choose **Einstellungen** in the alert, then **Vertrauen**. `devicectl process launch` cannot show the prompt. One certificate only (`9C705C81…`); duplicates caused repeated trust prompts and were removed.
- Installed identity: `dev.modernamusement.sift` 1.2.0 (build 3), launched on the device on 2026-11-16, including the design pass.
- Outcome: owner ran a first user test on 1.1.0 and reported the app working well; the 1.2.0 design pass was called “much better”. Flows were not individually logged, and no device screenshots were captured yet. A horizontal-overflow report is still open (see Known gaps).

## Known gaps

- Physical-device coverage is a first-launch smoke test so far. The device is the only place the real Vision path runs, because the iOS 18.4 simulator falls back to the color mosaic, so the device pass still needs to cover duplicates, similar photos, blur scoring, PhotoKit deletion into Recently Deleted and the Contacts merge, with screenshots in `docs/qa/`.
- Vision feature prints return nil in the iOS 18.4 Simulator; the color-mosaic fallback was exercised. Real devices use the Vision path. The fallback is deliberately conservative (threshold 0.66 × the slider value).
- PhotoKit gives imported simulator images no screenshot subtype. UI tests use the DEBUG-only `-uiFixtures` dimension check; Release builds use only `PHAssetMediaSubtype.photoScreenshot`.
- Denied photo permission was verified manually (`docs/qa/photos-denied.png`); limited access was code-reviewed but not automated.
- The Files picker itself uses Apple's document browser and is not automated; the deletion model is unit-tested.
- Cache clearing is a small synchronous directory cleanup and was not part of the screenshot suite.
- Contacts merging was verified locally in the simulator. iCloud sync of the deletion was not tested.
- Dark mode was implemented and spot-checked. 1.2 check-in, delta and phone-health screens were captured in light mode and in dark mode at accessibility XXXL (`docs/screenshots/17`–`19`, `docs/screenshots/dark/17`–`19`); the dark captures predate the navigation/glass pass and need recapturing before release. The rest of the committed screenshots are light mode at default text size.
- 1.2 pending: a VoiceOver pass on Check-in → Diagnose → Clean → Prove.
- 1.2 pending: the proof **verification** branch (space actually returned) is unit-tested only — emptying Recently Deleted needs the Photos app, which UI tests do not drive. Check-in baseline/delta and the unverified proof state are UI-tested.
- 1.2 open report: the owner saw horizontal overflow “to left and right” on hardware. It was not reproducible in the simulator at default or accessibility XXXL text, and no screenshot arrived. The adaptive storage card (`ViewThatFits`), accessibility-sized health rows and scaled onboarding title were added as defensive fixes; the screen and Display Zoom state are still needed to close it.
- 1.2 UI-test seams are DEBUG-only: `-resetLedger` and `-seedLedgerBackGB N` (plus the existing `-uiFixtures`), handled in `Sift/Demo/DemoSeed.swift`.
