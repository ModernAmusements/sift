# Sift

**Keep the moments. Lose the clutter.**

Sift is a free, open-source iPhone cleaner. It finds screenshots, duplicates, near-duplicate shots, blurry photos, large files and duplicate contacts — entirely on your iPhone.

[![License: MIT](https://img.shields.io/badge/license-MIT-black.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/iOS-17%2B-black.svg)](#requirements)
[![No network](https://img.shields.io/badge/network-none-black.svg)](docs/PRIVACY.md)

**Website:** [modernamusements.github.io/sift](https://modernamusements.github.io/sift)

## Download

**Sift 1.3.0** ships as a source project and an unsigned iPhone build. The recommended free install is **AltStore**: it signs Sift with your own Apple ID — no App Store and no paid developer account. The same IPA works with SideStore or Xcode.

1. **[Get AltStore](https://altstore.io)** and run AltServer on a Mac or PC on the same Wi-Fi.
2. Install Sift: [one tap with AltStore](altstore://install?url=https://modernamusements.github.io/sift/Sift-1.3.0-unsigned.ipa) · [download the IPA](https://modernamusements.github.io/sift/Sift-1.3.0-unsigned.ipa) (3.4 MB, build 5).
3. Refresh every 7 days with a free Apple ID. AltStore does it through AltServer.

- **AltStore source:** `https://modernamusements.github.io/sift/source.json` — automatic update checks
- **[Full install guide](docs/INSTALL.md)** — AltStore, Xcode, SideStore and the honest EU distribution answer
- SHA-256: `ed0e00b789e14d3150b8aa0a9f9a79ed12d23ce21e16bb205b15c57555d82de8`

<img src="docs/screenshots/01-home.png" width="240" alt="Sift home"> <img src="docs/screenshots/02-results.png" width="240" alt="Sift scan results"> <img src="docs/screenshots/05-similar.png" width="240" alt="Sift similar photos">

## Why another cleaner?

Commercial cleaners charge a subscription for a scan, gate the useful part, and sometimes ship analytics SDKs that see your library metadata. Sift is the opposite:

- **Free and open source.** MIT, no account, no ads, no subscription.
- **On-device only.** No networking code exists in the app. Your photos and contacts never leave the iPhone.
- **No fake features.** Sift cannot clear other apps' caches, "boost RAM", cool the CPU or extend battery life. iOS does not allow it, so we do not pretend.
- **Apple's safety net.** Every photo removal goes through PhotoKit and lands in **Recently Deleted** for 30 days.

## What it does

| Cleanup | How it works |
| --- | --- |
| **Screenshots** | Finds `PHAsset` screenshots, sorted by size, review and remove |
| **Duplicates** | 64-bit dHash + Vision feature print, grouped by exact dimensions |
| **Similar photos** | Feature-print distance within the same day; falls back to an on-device color mosaic when Vision is unavailable |
| **Blurry photos** | Variance-of-Laplacian ranking; conservative threshold |
| **Large files** | Photos and videos over 25 MB, sorted by size |
| **Duplicate contacts** | Shared phone/email handles, merge into the richest card |
| **Files & documents** | Pick downloads, archives and exports from On My iPhone or iCloud Drive and delete them after confirmation |
| **Sift cache** | Clear Sift's own temporary files from Settings |

Plus a fast **swipe review** deck, a live storage dashboard, a Files picker, a System data guide, and settings for scan sensitivity.

## Design

Black and white, one orange highlight (`#FF6600`), no box shadows. **Neo Grotesque-P5M5** is the single typeface across the app and the site. On iOS 26 the buttons, scan panel and selection bar use Apple's Liquid Glass; iOS 17–25 keeps the same layout with flat fills. The Sift lockup comes from the owner's `sift-logo-pack` and is leading-aligned; the app icon is the owner's Apple Icon Composer "Default" export. The app footer/Settings credit uses the owner's landscape wordmark artwork, with a website link before Impressum — no typeset name or claim.

## Honest limits

- iOS does not let third-party apps delete another app's cache or system "other" storage. Sift does not claim to.
- Free space is only truly reclaimed after **Recently Deleted** is emptied in Photos (or after 30 days).
- Contacts have no Recently Deleted. Sift previews every merge and requires confirmation.
- Contact merging deletes the redundant cards from Contacts. If Contacts syncs to iCloud, that deletion syncs too.
- Files are only visible after you pick them. Deleting removes them from their folder; iCloud Drive may keep a Recently Deleted copy, local files do not.
- Vision feature prints are unavailable in some Simulator runtimes; the app automatically uses a local color-mosaic fallback. Physical devices use the stronger Vision path.
- The app is English-only in v1. Localisation contributions are welcome.

## Big files and system data

- **Large files in Photos:** every photo or video over 25 MB is listed with its size.
- **Files & documents:** the native Files picker lets you clean downloads, archives and exports from iCloud Drive or On My iPhone. Sift never scans your whole file provider.
- **Sift cache:** Settings shows the temporary bytes Sift uses and can clear them.
- **System data guide:** honest steps for storage iOS will not let any third-party app touch.

## Requirements

- Xcode 26 (tested) or newer
- iOS 17.0+ / an iPhone 12 or newer for the intended layout
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Build

```bash
git clone https://github.com/ModernAmusements/sift.git
cd sift
xcodegen generate
open Sift.xcodeproj
```

Select the **Sift** scheme and an iPhone 12 simulator (or your device). For a physical device, choose your development team in Signing & Capabilities. There are no package dependencies.

Command line:

```bash
xcodebuild -project Sift.xcodeproj -scheme Sift \
  -destination 'platform=iOS Simulator,name=iPhone 12' build
```

## Test

```bash
xcodebuild -project Sift.xcodeproj -scheme Sift \
  -destination 'platform=iOS Simulator,name=iPhone 12' test
```

The UI suite expects Photos/Contacts permission and the simulator fixtures:

```bash
./scripts/seed-simulator.sh "iPhone 12"
xcrun simctl privacy booted grant photos dev.modernamusement.sift
xcrun simctl privacy booted grant contacts dev.modernamusement.sift
```

The screenshot category uses a **DEBUG-only** fixture (`-uiFixtures`) because PhotoKit gives imported images no screenshot subtype. Production code reads `PHAsset.mediaSubtypes.contains(.photoScreenshot)`.

See [`docs/QA.md`](docs/QA.md) for the verified flow and evidence.

## Architecture

```
Sift/
  App/          entry point, onboarding gate
  Design/       theme, components, haptics
  Models/       ScannedAsset, ScanReport, storage snapshot
  Services/     PhotoKit, Vision, hashing, contacts, scan engine
  Features/     Home, Review, Similar, Swipe, Contacts, Settings
Tests/          unit + UI tests
docs/           product, design, architecture, research, privacy, QA
```

- SwiftUI, Swift 5 language mode, iOS 17; one bundled typeface (Neo Grotesque-P5M5), no package dependencies.
- `ScanEngine` runs a bounded analysis pipeline (4 thumbnails at a time) and is cancellable.
- PhotoKit metadata and file sizes load off the main thread in three bounded workers; `AssetSizeCache` makes rescans fast. High-frequency progress lives in `ScanLiveState`, so the home screen does not redraw per batch.
- Thumbnails use opportunistic delivery, cancellable PhotoKit requests and off-main bitmap preparation.
- All mutations go through PhotoKit or Contacts; files are never touched by path.

Read [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the algorithm thresholds and data flow.

## Privacy

Sift has no networking code, no analytics, no ads and no account system. The privacy manifest declares no tracking and no collected data. Read [`docs/PRIVACY.md`](docs/PRIVACY.md).

Verify it yourself:

```bash
grep -rnE "URLSession|URLRequest|NWConnection|WKWebView|Analytics|Firebase|Sentry" Sift
# no matches
```

## Contributing

Bug reports, design polish and localisation are welcome. Start with [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`docs/DESIGN.md`](docs/DESIGN.md).

The agent harness used to build this repo lives in `opencode.json` and `.opencode/agents/`. Use `sift-ag` to continue the project with full context from `agents/PROJECT_CONTEXT.md` and CodeDrift memory. It is optional for contributors.

## License

MIT — see [`LICENSE`](LICENSE).

The bundled **Neo Grotesque** typeface is the owner's brand font and is excluded from the MIT grant; see [`docs/FONT.md`](docs/FONT.md). All application code remains MIT.

Sift is not affiliated with Apple, CleanMyiPhone or any commercial cleaner. PhotoKit, Vision and Contacts are Apple frameworks.

---

<p align="center">
  <img src="docs/ma-mark.svg" width="42" alt="ModernAmusement mark">
  <br>
  <strong>ModernAmusement</strong> · Shady Nathan Tawfik · Bielefeld, DE
  <br>
  <sub>Foundational software of tomorrow. Delivered today.™</sub>
  <br>
  <a href="https://modern-amusement.dev">modern-amusement.dev</a> · <a href="https://modern-amusement.dev/en/impressum">Impressum</a>
</p>
