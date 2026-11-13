# Sift — project context

**Status:** 1.1.0 shipped. Open source, MIT. iPhone 12 simulator verified. Physical-device install blocked only by Xcode Apple ID signing.

## Links

- Repo: https://github.com/ModernAmusements/sift
- Release: https://github.com/ModernAmusements/sift/releases/tag/v1.1.0
- Site: https://modernamusements.github.io/sift/
- QA evidence: `docs/QA.md`, `docs/screenshots/`, `docs/qa/`

## Product truth

Sift is an on-device iPhone cleaner: screenshots, duplicates, similar photos, blurry photos, large files (photos/videos ≥ 25 MB), duplicate contacts, user-picked Files, Sift's own cache. It has no networking code, no analytics, no ads, no account and no third-party dependencies.

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

## UI rules

Native Apple UI only: SwiftUI, SF Symbols, system controls. Monochrome, one green reclaim accent, SF Pro, 20 pt margins, 26 pt cards, 54 pt primary buttons. Respect Reduce Motion, Dynamic Type and VoiceOver. No gradient decoration, no emoji, no subscriptions.

## Commands

```bash
xcodegen generate
xcodebuild -project Sift.xcodeproj -scheme Sift \
  -destination 'platform=iOS Simulator,name=Sift iPhone 12' build
xcodebuild -project Sift.xcodeproj -scheme Sift \
  -destination 'platform=iOS Simulator,name=Sift iPhone 12' test
./scripts/seed-simulator.sh "Sift iPhone 12"
```

Deterministic UI runs need `build-for-testing`, install, `simctl privacy grant photos/contacts`, then `test-without-building`; xcodebuild's test install resets TCC.

## Known constraints

- CodeDrift's indexer currently has no Swift parser; CodeDrift memory/context works, but the structural index covers only `docs/index.html`. Use `grep`/`glob` for Swift source. **Known improvement:** add a Swift language adapter to CodeDrift so `.swift` symbols, calls and imports are indexed; until then, do not claim Swift symbol indexing.
- Vision feature prints return nil in the iOS 18.4 Simulator; fallback is intentional.
- Imported simulator images are not marked as screenshots; UI tests use the DEBUG-only `-uiFixtures` dimension check. Release uses `.photoScreenshot` only.
- Device install requires signing in Xcode as `s.tawfik@outlook.de` and selecting team `U75G5FCH98`.
