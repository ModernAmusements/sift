# Sift — project context

**Status:** 1.2.0 implemented, UI-polished and green in the simulator, not yet released. Open source, MIT. Sift 1.2.0 (build 3) is installed on the physical iPhone 12 (iOS 26.6.2), signed with the free Personal Team `QG32S7GZ56` — profile expires 2026-11-23 — and launches with a stable trust record. The design pass (native navigation, Liquid Glass on iOS 26, scan-start feedback, adaptive layouts) is installed and the owner called it “much better”. Pending: a final owner pass on hardware, VoiceOver pass, and one reported horizontal-overflow issue that could not be reproduced without a screenshot. The paid team `U75G5FCH98` is not visible to the signed-in Xcode account, so it is not used yet.

## Links

- Repo: https://github.com/ModernAmusements/sift
- Release: https://github.com/ModernAmusements/sift/releases/tag/v1.1.0
- Site: https://modernamusements.github.io/sift/
- QA evidence: `docs/QA.md`, `docs/screenshots/`, `docs/qa/`
- 1.2 spec: `docs/SPEC-V1.2.md` (implemented)

## Product truth

Sift is an on-device iPhone cleaner: screenshots, duplicates, similar photos, blurry photos, large files (photos/videos ≥ 25 MB), duplicate contacts, user-picked Files, Sift's own cache. It has no networking code, no analytics, no ads, no account and no third-party dependencies.

One pain point governs scope: **the user cannot tell what is safe to lose, at the moment the phone fails** (shutter blocked, apps hanging, update refused). Features are commodities in this category — the job is removing the gamble under time pressure, then proving what was actually freed. Slowness is diagnosed from what iOS exposes (free space, Low Power Mode, thermal state), never "fixed".

iOS does **not** allow any third-party app to delete another app's cache, system caches or "Other" storage. The System data screen explains this and gives the user real manual steps. Never add fake cache/RAM/battery claims.

## Architecture

- SwiftUI, iOS 17+, Swift 5 language mode, XcodeGen (`project.yml` is the source of truth).
- `ScanEngine` (@MainActor) runs the photo pipeline: PhotoKit metadata → 4-way thumbnail analysis → dHash/Laplacian/Vision → grouping → report.
- Exact duplicates: 64-bit dHash Hamming ≤ 2 + feature-print distance ≤ 0.03, bucketed by pixel dimensions.
- Similar: same-day Vision feature prints (default 0.15); 8×8 RGB color-mosaic fallback when Vision is nil (Simulator).
- Deletion: PhotoKit only, system confirmation, Recently Deleted.
- Contacts: shared phone/email handles, richest keeper, preview, `CNSaveRequest`.
- Files: native `fileImporter` security-scoped URLs, explicit confirmation, no directory walking.
- Cache: only Sift's `Caches/` and `tmp/`.

## v1.2 Check-in (implemented)

Flow: **Check-in → Diagnose → Clean → Prove.**

- `SpaceCheckIn` / `SpaceLedger` (`Sift/Models/SpaceLedger.swift`): pure delta rules. Capacity changes (>5%) reset the baseline; movement under 100 MB is `About the same as last time`; a delete session is attributed for 45 days; `verifiedFreed` is cumulative and never expires, `pendingFreed` expires with the window.
- `SpaceLedgerStore` (`Sift/Services/SpaceLedgerStore.swift`): UserDefaults key `spaceCheckIns`, keeps 30 check-ins but never prunes a verified one (`Reclaimed` is cumulative), `recordLaunch`, `recordSession`, `confirmVerified`, `movedSince`, `verifiedSince`. Store tests must use dates near `Date()`, never a fixed epoch.
- Home: check-in card with the measured delta and honest attribution (`X of that was freed by Sift.`); `Phone health` row → `HealthView`.
- `HealthView` / `HealthReading`: free space + Critical/Tight/Fine word, Low Power Mode, `thermalState`, library size, battery-health explanation. Diagnosis only.
- Prove: `ProofView` shows `Moved X. Freed so far: 0 bytes.` until a later `confirmVerified` measurement proves a gain, then `Verified: X freed.` `PhotosDeepLink` holds the only undocumented scheme (`photos-redirect://`); the manual Photos path is always visible.
- Settings: `Reclaimed` row (`X verified since <day>`, else `Nothing verified yet`).
- `Format.floorBytes` rounds down so a size is never overstated; `Format.shortDay` is `en_US_POSIX`.
- `ScanEngine.delete(ids:)` records the moved bytes from `report.bytes(for:)` and sets `proof`; Home presents the sheet.

## UI rules

Native Apple UI only: SwiftUI, SF Symbols, system controls. Monochrome, one green reclaim accent, SF Pro, 20 pt margins, 26 pt cards, 54 pt primary buttons. On iOS 26 the primary/secondary buttons, settings gear and scan panel use Liquid Glass (`glassEffect`, availability-gated) per the HIG; iOS 17–25 keep the flat fallback. Content cards stay opaque. Respect Reduce Motion, Dynamic Type and VoiceOver. No gradient decoration, no emoji, no subscriptions. Design reference: Apple HIG and `docs/DESIGN.md`.

### Design pass (2026-11-16)

- Home uses a native large navigation title (`Sift`) and a system toolbar gear. No custom header; the tagline moved into content.
- Liquid Glass lives in `PrimaryButtonStyle`, `SecondaryButtonStyle`, the scan panel and (on iOS 26) the toolbar gear. `glassEffect` is declared in **SwiftUICore**, not SwiftUI; use `if #available(iOS 26.0, *)`.
- Scan start is indeterminate: `ScanProgressView` shows `ProgressView` while `stage == .preparing || progress < 0.01`, so a fake 0% is never displayed. Percent uses `.contentTransition(.numericText(value:))`.
- Motion: numeric-text transitions on measurements, `.symbolEffect(.bounce)` on the proof seal, `sensoryFeedback(.impact)` on button press, `.snappy` overlay entrance. Reduce Motion keeps opacity only.
- Scrolling: `.scrollBounceBehavior(.basedOnSize)` on every custom `ScrollView`; indicators hidden on Home/Health/Proof.
- Adaptive layout: storage card uses `ViewThatFits` with `minWidth: 140` on the details column; health rows stack title/value at accessibility sizes; onboarding hero uses `@ScaledMetric(relativeTo: .largeTitle)`.
- Open report: owner saw horizontal overflow "to left and right" on hardware; not reproducible in the simulator at default or accessibility XXXL, and no screenshot arrived. Treat as unresolved until a screenshot identifies the screen/Display Zoom state.


## Commands

```bash
xcodegen generate
xcodebuild -project Sift.xcodeproj -scheme Sift \
  -destination 'platform=iOS Simulator,id=59D0DE9D-157A-4F7B-BEA3-2AD9E47D4D59' build
xcodebuild -project Sift.xcodeproj -scheme Sift \
  -destination 'platform=iOS Simulator,id=59D0DE9D-157A-4F7B-BEA3-2AD9E47D4D59' test
./scripts/seed-simulator.sh "Sift iPhone 12"
./scripts/deploy-device.sh    # build + install on Shadys iPhone
./scripts/housekeeping.sh     # session end: relays, simulator, temp files
```

Deterministic UI runs need `build-for-testing`, install, `simctl privacy grant photos/contacts`, then `test-without-building`; xcodebuild's test install resets TCC.

## Tooling / workspace

- `.vscode/settings.json` (committed, not ignored) sets a red status bar: `statusBar.background` `#C62828`, white text, `#B71C1C` while debugging, `#D84343` hover. Purpose: tell the Sift window apart from other VS Code windows at a glance. It is editor chrome only and has no effect on the app, the build or CI.
- Swift work still happens in Xcode; VS Code is for reading, docs and landing-page edits.

## Known constraints

- CodeDrift's indexer currently has no Swift parser; CodeDrift memory/context works, but the structural index covers only `docs/index.html`. Use `grep`/`glob` for Swift source. **Known improvement:** add a Swift language adapter to CodeDrift so `.swift` symbols, calls and imports are indexed; until then, do not claim Swift symbol indexing.
- Vision feature prints return nil in the iOS 18.4 Simulator; fallback is intentional.
- Imported simulator images are not marked as screenshots; UI tests use the DEBUG-only `-uiFixtures` dimension check. Release uses `.photoScreenshot` only.
- **Device install, resolved 2026-11-16.** Sift is installed on `Shadys iPhone` (iPhone 12, `iPhone13,2`, iOS 26.6.2, paired, Developer Mode on; xcodebuild `id 00008101-000348D00E51001E`, devicectl `CB38B173-19F9-500D-94AE-B5267C99489E`). Signing runs on the **free Personal Team `QG32S7GZ56`**, which auto-registered the device UDID and issued "iOS Team Provisioning Profile: dev.modernamusement.sift" expiring **2026-11-23** (7-day free-team limit; re-run the build after that).
  1. The paid team `U75G5FCH98` is still unusable: `DEVELOPMENT_TEAM=U75G5FCH98` now fails with "No Account for Team", and the signed-in Xcode account only lists the Personal Team. Sign in with the Apple ID that actually owns that team to use it. Valid `Apple Development: s.tawfik@outlook.de (U75G5FCH98)` certs exist in the keychain, so the certs are not the problem.
  2. First launch is blocked until the developer is trusted on the phone. Tap the Sift icon, then **Einstellungen** in the alert (not Abbrechen) → Apple Development: s.tawfik@outlook.de → **Vertrauen**. `devicectl process launch` can never show that prompt; it only returns "profile has not been explicitly trusted by the user".
  3. DDI is no longer a blocker: `devicectl install app` enables the developer disk image services itself.
- Working device pipeline (no simulator, no DDI fuss):
  ```bash
  xcodebuild -project Sift.xcodeproj -scheme Sift -configuration Debug \
    -destination 'generic/platform=iOS' -allowProvisioningUpdates build
  xcrun devicectl device install app --device CB38B173-19F9-500D-94AE-B5267C99489E \
    ~/Library/Developer/Xcode/DerivedData/Sift-*/Build/Products/Debug-iphoneos/Sift.app
  ```
  Signing lives in `Config/Local.xcconfig` (gitignored), pulled in by `Config/Shared.xcconfig`, so `xcodegen generate` no longer drops the team and no CLI `DEVELOPMENT_TEAM` is needed. `project.yml` maps `CODE_SIGN_IDENTITY = $(SIFT_SIGNING_IDENTITY)`; the fallback is defined **before** `#include?` in Shared.xcconfig so Local can override it.
  - **Do not pin a certificate hash.** Automatic signing rejects it with "Sift is automatically signed, but code signing identity … has been manually specified". Keep `SIFT_SIGNING_IDENTITY = Apple Development` and exactly one Apple Development identity in the keychain. Current identity: `9C705C81…` (valid to 2027-11-16). Check with `security find-identity -v -p codesigning`.
  - XcodeGen inserts `CODE_SIGN_IDENTITY = "iPhone Developer"` at target level; without the mapping above it overrides the xcconfig and Xcode may pick a different certificate.
- Signing pitfall, fixed 2026-11-16: when the keychain had **zero** Apple Development certificates, Xcode auto-created **two** with the same name, four seconds apart. With duplicates, iOS asks for developer trust again and again because each build can be signed by a different certificate. Keep exactly one identity; delete extras with `security delete-identity -Z <sha1>`. Do not delete the last certificate before a device build — Xcode will mint duplicates again.
- Deleting Sift from the phone also removes its trust record. Reinstalling the same certificate then requires one more trust; after that, overwriting via Xcode/`devicectl` keeps it. With the free Personal Team, the 7-day profile expiry (currently **2026-11-23**) still forces a reinstall after that date.

- Device compile is verified: `-destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` → BUILD SUCCEEDED (arm64).
- Debug-console noise on first launch, "Failed to send CA Event for app launch measurements", is CoreAnalytics from the simulator/debug launch. Not a Sift error, no fix needed, never add networking for it (Sift has 0 `URLSession`/`CFNetwork` references).
