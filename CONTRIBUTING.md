# Contributing to Sift

Thanks for helping make a quieter cleaner.

## Ground rules

1. **No network.** Sift must keep working with the radio off. PRs adding networking, analytics or remote config will be rejected.
2. **No fake features.** Do not claim cache clearing, RAM boosting, cooling or battery improvement. iOS does not permit it.
3. **Apple-minimal design.** Read `docs/DESIGN.md` before changing a view. Reuse components, keep monochrome surfaces, one green accent.
4. **PhotoKit-only deletion.** No file-path deletion, no private APIs for destructive work.
5. **No third-party dependencies.** System frameworks only.
6. **Accessibility is part of done.** VoiceOver labels, Dynamic Type, Reduce Motion, 44pt targets.

## Setup

```bash
brew install xcodegen
xcodegen generate
open Sift.xcodeproj
```

Test on the iPhone 12 simulator. Seed media and permissions:

```bash
./scripts/seed-simulator.sh "iPhone 12"
xcrun simctl privacy booted grant photos dev.modernamusement.sift
xcrun simctl privacy booted grant contacts dev.modernamusement.sift
```

## Before opening a PR

- [ ] `xcodegen generate` runs cleanly.
- [ ] Debug build succeeds without new warnings.
- [ ] `xcodebuild test` passes.
- [ ] The changed flow was exercised in the simulator, light and dark.
- [ ] No networking symbols (`grep -rnE "URLSession|NWConnection|Analytics" Sift`).
- [ ] Privacy manifest and Info.plist usage strings still accurate.
- [ ] Docs/screenshots updated when behaviour or permissions change.
- [ ] Keep the diff focused; no drive-by reformatting.

## Algorithms

If you touch duplicate, similarity or blur thresholds:

- Add or update a unit test.
- Calibrate against the seeded media and note the measured distances in the PR.
- Update `docs/ARCHITECTURE.md` and `agents/LEARNING_LEDGER.md`.
- Never trade user safety for a larger "found" number.

## Commit style

Short imperative subject, optional body explaining why. Examples:

```
Keep the sharpest frame in duplicate groups
Scan contacts only after explicit permission
```

## Design contributions

Include light and dark screenshots at iPhone 12 size (1170×2532) and note what changed in the interaction. Motion must respect Reduce Motion.

## Reporting bugs

Open an issue with iOS version, device/simulator, steps, expected behaviour and, if possible, a screen recording. Never attach personal photos or contacts. Use the security process in `SECURITY.md` for vulnerabilities.

## License

By contributing you agree your work is licensed under the MIT License.
