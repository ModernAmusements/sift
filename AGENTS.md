# Sift — agent handbook

**Sift** is a free, open-source iPhone cleaner. Keep the moments. Lose the clutter.

- Bundle: `dev.modernamusement.sift` · App name: **Sift** · License: **MIT**
- Stack: SwiftUI, iOS 17+, PhotoKit, Vision, Contacts, Accelerate — **zero third-party dependencies**
- Deploy target: iPhone 12 / iOS 17 and newer

## Non-negotiables

1. **No network.** No URLSession, no analytics, no ads, no accounts, no remote config. The only data flow is on-device.
2. **Honest features.** We never claim to clear other apps' caches, "boost RAM", cool the CPU, or extend battery. iOS does not permit it. We only surface and remove media and contacts the user owns.
3. **Deletion through PhotoKit only.** `PHPhotoLibrary.performChanges` → Recently Deleted. Never touch files by path.
4. **No dark patterns.** No fake urgency, no pre-selected destructive actions on first run, no paywall, no subscription.
5. **Apple-minimal UI.** See `docs/DESIGN.md`. Monochrome, SF Pro, generous space, one green accent.
6. **Accessibility is part of done.** VoiceOver labels, Dynamic Type, Reduce Motion, 44pt targets.

## Harness

- Agent specs live in `.opencode/agents/`. Shared protocols live in `agents/`.
- Use `sift-ag` for continuing the project with full context; `sift-lead` for planning, `photo-engine-ag` for scan/delete work, `ui-ag` for views, `qa-ag` for verification, `release-ag` before publishing.
- Context first: `codedrift_memory` → `agents/PROJECT_CONTEXT.md` → `docs/PRODUCT.md` → `docs/ARCHITECTURE.md` → `docs/DESIGN.md` → relevant source.
- CodeDrift indexes only the HTML landing page in this repo (its indexer has no Swift parser). Use `grep`/`glob` for Swift source; CodeDrift memory and `agents/PROJECT_CONTEXT.md` carry the project state. Known improvement: add a Swift adapter so `.swift` symbols are indexed.
- Work by trial and error, not reasoning loops. Small change → build → observe → next.

## Commands

```bash
# Project generation (project.yml is the source of truth; .xcodeproj is generated)
xcodegen generate

# Build for simulator
xcodebuild -project Sift.xcodeproj -scheme Sift \
  -destination 'platform=iOS Simulator,name=iPhone 12' build

# Unit tests
xcodebuild -project Sift.xcodeproj -scheme Sift \
  -destination 'platform=iOS Simulator,name=iPhone 12' test

# Simulator run
xcrun simctl boot "iPhone 12"
open -a Simulator
xcrun simctl install booted "$(find ~/Library/Developer/Xcode/DerivedData -path '*Build/Products/Debug-iphonesimulator/Sift.app' | head -1)"
xcrun simctl launch booted dev.modernamusement.sift

# Screenshot
xcrun simctl io booted screenshot docs/screenshots/home.png
```

## Layout

```
project.yml                 XcodeGen spec (source of truth)
Sift/
  App/                      entry point, root navigation
  Design/                   theme, reusable components
  Models/                   ScanReport and value types
  Services/                 Photos, Vision, Contacts, storage, thumbnails
  Features/                 Onboarding, Home, Scan, Review, Similar, Swipe, Contacts, Settings
  Resources/                assets, privacy manifest, Info.plist
Tests/SiftTests/            pure algorithm and normalization tests
docs/                       product, architecture, design, research, privacy
agents/                     shared protocols and ledgers
```

## Definition of done

- `xcodegen generate` and a clean Debug build pass.
- Unit tests pass (`xcodebuild test`).
- The touched flow was exercised in the iPhone 12 simulator with seeded media, light + dark.
- No new warnings that matter; no network APIs; privacy manifest still accurate.
- README / docs updated when behaviour or permissions change.

## Answer format (chat only)

- **Action:** one sentence.
- **Files:** changed paths.
- **Verified:** exact command/result.
- **Next:** one recommendation.
