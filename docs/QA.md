# QA — Sift 1.3.0

Verified 2026-11-17 on macOS 26 with Xcode 26.0 (17A324), `Sift iPhone 12 iOS 26` simulator (`337E7B81-10E0-4C43-BA55-90084C0345BC`, iOS 26.0) and the iOS 18.4 fallback device.

## Automated

| Suite | Tests | Result |
| --- | --- | --- |
| `SiftTests` (unit) | 40 | Passed |
| `SiftUITests/testOnboarding` | 1 | Passed |
| `SiftUITests/testOnboardingBottom` | 1 | Passed |
| `SiftUITests/testScanAndBrowse` | 1 | Passed |
| `SiftUITests/testContactMerge` | 1 | Passed |
| `SiftUITests/testDeleteScreenshots` | 1 | Passed (incl. proof sheet) |
| `SiftUITests/testCheckInBaselineOnFirstRun` | 1 | Passed |
| `SiftUITests/testCheckInReportsMeasuredDeltaWithoutClaimingCredit` | 1 | Passed |
| `SiftUITests/testPhoneHealthOnlyClaimsWhatIOSExposes` | 1 | Passed |
| `SiftUITests/testHomeFooterCreditsModernAmusement` | 1 | Passed |

Full iOS 26 run: **40 unit + 9 UI, 0 failures** (2026-11-17, `build/full-test-ios26.log`). `testDeleteScreenshots` exercised the real PhotoKit confirmation and proof sheet. `testScanAndBrowse` then exercised every results screen, the swipe deck and Settings. The scan-only rerun generated the 1.3 screenshots.

Branding refresh rerun (2026-11-19): `xcodegen generate` → Debug build → `xcodebuild test` → **40 unit + 9 UI, 0 failures (1 conditional `XCTSkip` in `testContactMerge`)** → Release device build → iOS 26 build, all green. `testHomeFooterCreditsModernAmusement` first failed because `MAByline`'s accessibility label changed with the artwork; restoring `ModernAmusement. …` made the focused rerun pass (8.7 s).

### Free install (2026-11-19)

- `scripts/make-ipa.sh` produced build 5: **3,553,469 bytes**, SHA-256 `ed0e00b789e14d3150b8aa0a9f9a79ed12d23ce21e16bb205b15c57555d82de8`, verified unsigned (no `_CodeSignature` or embedded profile).
- Pushed `0144c27` to `main`; GitHub Pages live at `https://modernamusements.github.io/sift/`.
- Live checks: `source.json` reports `"buildVersion": "5"`; the live IPA downloads at the same size/checksum; the page contains the three-step flow, `altstore://install`, `altstore://source` and the copy-link control.
- Playwright full-page screenshots of the live page measure **320 / 360 / 390 px exactly** — no horizontal overflow.
- Owner device pass (2026-11-19): after tapping through the live install flow, the owner reports **Sift is running on the iPhone**. `devicectl` lists `Sift 1.3.0 (5)`; it does not list AltStore, so the installer's presence was not independently verified from the Mac — the owner's report is the evidence for the end-to-end run.

## 1.3 design pass

- Black/white background and cards, orange `#FF6600` for the primary action, storage ring, selection and success. No shadows.
- Neo Grotesque-P5M5 only; `Sift.app` contains exactly `SiftNeo-P5M5.ttf` and `Info.plist` lists it.
- Sift lockup in onboarding header, home navigation, home footer and Settings About, always leading-aligned; app icon is the owner's Apple Icon Composer "Default" export. The credit footer uses the owner's landscape wordmark artwork (no typeset name, no claim) in the home footer and Settings About; the site footer keeps its own credit. Settings About links to modern-amusement.dev before Impressum.
- iOS 26 Liquid Glass verified on the iOS 26 simulator: glass gear/back-button capsules, tinted primary/secondary buttons, scan panel and selection bar. iOS 18.4 shows the flat fallback, as designed.
- Minimal layouts restored: the home still uses the large storage card (`ViewThatFits`), the original scan overlay, the full-width selection bar and the original swipe card.

The three 1.2 UI tests were also run with dark appearance and accessibility XXXL text: 3/3 passed (before the navigation/glass pass).

Commands:

```bash
xcodegen generate
xcodebuild -project Sift.xcodeproj -scheme Sift \
  -destination 'platform=iOS Simulator,id=337E7B81-10E0-4C43-BA55-90084C0345BC' build
xcodebuild -project Sift.xcodeproj -scheme Sift \
  -destination 'platform=iOS Simulator,id=337E7B81-10E0-4C43-BA55-90084C0345BC' test
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
20. **Design pass** — inline Sift lockup in the navigation bar, system glass gear, Liquid Glass primary/secondary buttons, scan panel and selection bar on iOS 26 (flat fallback on iOS 17–25), indeterminate spinner instead of a fake 0% while photos are fetched, numeric-text transitions on measurements, and an adaptive storage card (`ViewThatFits`) for narrow widths and large type.
21. **1.3 performance** — opening the scan no longer blocks the main thread; PhotoKit metadata and file sizes load on three background workers with a persistent size cache; the scan overlay owns the high-frequency progress state; thumbnails are opportunistic, cancellable and pre-decoded.
22. **1.3 branding** — P5M5-only type, leading-aligned Sift lockup on every brand surface, Apple Icon Composer app icon, credit footer with the owner's landscape wordmark artwork (no typeset name or claim), website link before Impressum, one sentence-cased closing line, and the unsigned IPA + EU install guide.
23. **1.3 fallback** — the same build on the iOS 18.4 simulator renders flat buttons/bars without `glassEffect`; no layout or copy difference.

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

First install on real hardware: 2026-11-16. 1.3.0 installed 2026-11-17.

- Device: `Shadys iPhone`, iPhone 12 (`iPhone13,2`), iOS 26.6.2, Developer Mode on.
- Signed with the free **Personal Team** (`QG32S7GZ56`); provisioning profile expires **2026-11-23**, so the build needs re-signing weekly until a paid team is used.
- Build + install path: `xcodebuild -destination 'generic/platform=iOS' -allowProvisioningUpdates build` (team comes from `Config/Local.xcconfig`), then `xcrun devicectl device install app`. `devicectl` enables the developer disk image services itself.
- Trust: tap the Sift icon, choose **Einstellungen** in the alert, then **Vertrauen**. `devicectl process launch` cannot show the prompt. One certificate only (`9C705C81…`); duplicates caused repeated trust prompts and were removed.
- Installed identity: `dev.modernamusement.sift` **1.3.0 (build 5)**, installed on the device on 2026-11-19. Earlier build 4 was installed on 2026-11-17; `devicectl install` succeeded on the second attempt and `devicectl process launch` timed out, so the first tap and trust prompt still need the owner.
- Owner visual check on hardware (2026-11-19): the refreshed icon, leading-aligned lockup and wordmark footer "looks good" on `Shadys iPhone`. This is a visual confirmation, not a full on-device flow run.
- Outcome: owner ran a first user test on 1.1.0 and reported the app working well; the 1.2.0 design pass was called “much better”. The 1.3.0 build is installed and ready for the owner pass: tap Sift, trust the developer if prompted, then check the Sift lockup, P5M5 type and iOS 26 glass on hardware.
- 2026-11-19 branding refresh + build 5: first `./scripts/deploy-device.sh` run built but hit **"The device is locked"** (`0xe80000e2`, DDI mount). After unlocking the phone, reruns returned `BUILD SUCCEEDED` + `Installed.` (exit 0). `devicectl device info apps` confirms `Sift  dev.modernamusement.sift  1.3.0  5`. The site IPA was rebuilt with `scripts/make-ipa.sh` (3,553,469 bytes, SHA-256 `ed0e00b7…`, verified unsigned: no `_CodeSignature`/profile).

## Known gaps

- Physical-device coverage is a first-launch smoke test so far. The device is the only place the real Vision path runs, because the iOS 18.4 simulator falls back to the color mosaic, so the device pass still needs to cover duplicates, similar photos, blur scoring, PhotoKit deletion into Recently Deleted and the Contacts merge, with screenshots in `docs/qa/`.
- Vision feature prints return nil in the iOS 18.4 Simulator; the color-mosaic fallback was exercised. Real devices use the Vision path. The fallback is deliberately conservative (threshold 0.66 × the slider value).
- PhotoKit gives imported simulator images no screenshot subtype. UI tests use the DEBUG-only `-uiFixtures` dimension check; Release builds use only `PHAssetMediaSubtype.photoScreenshot`.
- Denied photo permission was verified manually (`docs/qa/photos-denied.png`); limited access was code-reviewed but not automated.
- The Files picker itself uses Apple's document browser and is not automated; the deletion model is unit-tested.
- Cache clearing is a small synchronous directory cleanup and was not part of the screenshot suite.
- Contacts merging was verified locally in the simulator. iCloud sync of the deletion was not tested.
- Dark mode is black/white/orange. Onboarding and home were recaptured on iOS 26 in `docs/screenshots/dark/00-onboarding.png` and `01-home.png`; the light iOS 26 screenshots (`00-onboarding.png`, `01-home.png`, `02`–`12`) show the shipping design and glass. The 1.2 check-in/health dark captures were superseded.
- Pending: a VoiceOver pass on Check-in → Diagnose → Clean → Prove, and the 1.3 owner pass on the physical device (trust prompt + unlock).
- 1.2 pending: the proof **verification** branch (space actually returned) is unit-tested only — emptying Recently Deleted needs the Photos app, which UI tests do not drive. Check-in baseline/delta and the unverified proof state are UI-tested.
- Resolved 2026-11-16: the reported “horizontal overflow to left and right” was the **landing page**, not the iOS app. `docs/index.html` measured a 368 px full-page width at 320/360 px viewports; header/nav wrapping, `min-width: 0` on grid items, `img { max-width: 100% }`, `code { overflow-wrap: anywhere }` and `overflow-x: clip` fixed it. Verified with Playwright at 320/360/390/768/1024/1280 and on the live Pages URL (cache-busted).
- 1.2 UI-test seams are DEBUG-only: `-resetLedger` and `-seedLedgerBackGB N` (plus the existing `-uiFixtures`), handled in `Sift/Demo/DemoSeed.swift`.
