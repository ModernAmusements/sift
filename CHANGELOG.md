# Changelog

All notable changes to Sift are documented here. The format follows Keep a Changelog; versions use semantic versioning.

## [Unreleased]

### Changed

- App icon replaced with the owner's Apple Icon Composer "Default" iOS export.
- Sift lockup is leading-aligned in the home footer and Settings About.
- The ModernAmusement credit uses the owner's landscape wordmark artwork instead of the typeset name; the "Foundational software of tomorrow. Delivered today.™" claim was removed from the app footer.
- Settings About now links to modern-amusement.dev before Impressum; the closing line is one sentence-cased line with no divider.
- Build 5: the unsigned IPA on the site is rebuilt from current sources (new icon/footer included). App Store/TestFlight/notarisation remain unavailable without the paid Apple Developer Program.

### Added

- Free install flow on the site: three-step guide, `altstore://install` and `altstore://source` deep links, copy-IPA button and an honest "why no App Store" note.
- `docs/source.json` AltStore Classic source with the current build, checksum, icon and screenshots for automatic update checks.
- `scripts/make-ipa.sh` builds an unsigned Release IPA and refreshes its SHA-256.

## [1.3.0] — 2026-11-17

### Added

- Black-and-white design with orange as the single highlight, no box shadows.
- **Neo Grotesque-P5M5** as the only app and web typeface, supplied by ModernAmusement.
- The owner's Sift lockup in the app icon, onboarding header, home navigation and footer, and the site header.
- ModernAmusement credit with name, title, claim, services and Impressum in the app footer/About and on the site.
- iOS 26 Liquid Glass on primary/secondary buttons, the scan panel and the selection bar, with a flat iOS 17–25 fallback.
- Unsigned 1.3.0 IPA and an EU-friendly install guide (Xcode, AltStore, SideStore).
- Background metadata loading with a persistent asset-size cache, so opening a scan no longer blocks the main thread.
- Split scan progress state: only the scan overlay redraws, not the home screen.
- Cancellable PhotoKit thumbnail requests and off-main bitmap preparation.

### Changed

- The minimal Sift layouts are restored; only colour, type and branding changed.
- Scan thumbnails load with opportunistic delivery; landscape photos no longer widen the review grid.
- Disabled primary buttons use a neutral grey tint instead of washed-out orange.
- Swipe metadata is a compact black capsule rather than a gradient over the photo.
- Version 1.3.0 (build 4), 40 unit tests and 9 UI tests green on an iOS 26 iPhone 12 simulator.

### Fixed

- Long delay between tapping Scan and seeing a response when PhotoKit metadata was read on the main thread.
- Blank grid thumbnails on the first delivery of an opportunistic image request.
- Stale `SiftNeo-Regular.ttf` project reference after the P5M5 switch.
- UI tests expecting the old all-caps "FOUND" label; the restored minimal screen says "Found".

## [1.2.0] — 2026-11-16

### Added

- Check-in → Diagnose → Clean → Prove: launch-time free-space snapshots, honest deltas since the last visit, a Phone health screen and a proof screen that only claims space after Recently Deleted is emptied.
- Space ledger with cumulative verified reclaimed bytes and a 45-day pending window.

## [1.1.0] — 2026-11-13

### Added

- Large files category for photos and videos over 25 MB.
- Files & documents picker: choose files from iCloud Drive or On My iPhone, review sizes, delete after confirmation.
- Sift cache section in Settings with size and clear action.
- System data guide explaining which storage iOS does not expose to third-party apps and what the user can do.
- Disk-space required-reason API declaration in the privacy manifest.
- Screenshot fixtures and UI coverage for Files and System data.

### Changed

- "Large videos" became "Large files" and now includes photos.
- Thumbnail rendering uses an explicit geometry frame, preventing overflow.

## [1.0.0] — 2026-11-13

### Added

- On-device storage dashboard with free/used space and library totals.
- Cancellable scan for screenshots, exact duplicates, similar photos, blurry photos and large videos.
- Exact duplicates: 64-bit dHash (Hamming ≤ 2) cross-checked with Vision feature prints (distance ≤ 0.03), bucketed by pixel dimensions.
- Similar photos: same-day feature-print clustering (default 0.15) with a color-mosaic fallback when Vision is unavailable.
- Best-shot recommendation using sharpness, resolution and file size, with screenshots penalised.
- Review grid with multi-select, size totals and PhotoKit deletion into Recently Deleted.
- Swipe review deck with keep/delete, undo and a single commit step.
- Duplicate contacts: shared phone/email grouping, richest-card merge, per-group preview and merge-all.
- Limited/denied photo access states, contacts permission explained at the point of use.
- Apple-minimal design: monochrome surfaces, one green reclaim accent, haptics, Reduce Motion and accessibility labels.
- Privacy manifest: no tracking, no collected data, UserDefaults required-reason declaration.
- Debug fixtures and simulator seeding scripts for QA.
- MIT license, contributor and security documentation.

### Known limitations

- English-only.
- Cannot clean other apps' caches or system data (iOS restriction; the in-app guide explains what users can do).
- Files cleanup only covers files the user explicitly picks.
- Vision feature prints return nil in some Simulator runtimes; the color-mosaic fallback is used there.
- Physical-device testing is still recommended before an App Store release.
