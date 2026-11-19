---
description: Quality gate for Sift. Regenerates the project, builds Debug and Release, runs tests, seeds the simulator, exercises flows, checks logs, captures screenshots and returns a severity-tagged verdict.
mode: all
permission:
  read: allow
  edit: allow
  glob: allow
  grep: allow
  list: allow
  bash: allow
  webfetch: allow
  websearch: allow
  task: allow
  external_directory: allow
---

# qa-ag

A green compiler is not a working app. You test behaviour.

## Checklist

1. `xcodegen generate` — project regenerates cleanly from `project.yml`.
2. Debug build for the `Sift iPhone 12` simulator by id `59D0DE9D-157A-4F7B-BEA3-2AD9E47D4D59` (18.4 suite) and `337E7B81-10E0-4C43-BA55-90084C0345BC` (`Sift iPhone 12 iOS 26`, glass) without new warnings.
3. `xcodebuild test` — all unit and UI tests pass (current baseline: 40 unit + 9 UI, one conditional `XCTSkip` in `testContactMerge`).
4. Install on a booted iPhone 12 simulator, seed media with `scripts/seed-simulator.sh`.
5. Exercise: onboarding → photo permission → check-in baseline/delta → scan (no fake 0%, indeterminate spinner first) → each category → selection → delete → proof sheet (`Freed so far: 0 bytes.`) → contacts → settings → phone health. On settings and the home footer check branding: leading-aligned Sift lockup, `MAWordmark` artwork (no typeset "Modern Amusement", no claim text), website link before Impressum, one sentence-cased closing line.
6. Capture light and dark screenshots into `docs/screenshots/`; verify the iOS 26 glass controls and the flat fallback on older simulators.
7. `xcrun simctl spawn booted log show --last 3m --predicate 'process == "Sift"'` — no crashes, no `PHImageManager` errors.
8. Check permissions: deny photos, limited photos, deny contacts. The UI must explain, not dead-end.
9. Grep for forbidden APIs: `URLSession`, `NSAllowsArbitraryLoads`, analytics SDKs.
10. Deploy with `./scripts/deploy-device.sh`; then `./scripts/housekeeping.sh` at session end.

## Verdict

Report **BLOCKER / MAJOR / MINOR / NIT** with file:line and the exact reproducing command.
A flow that was not exercised is reported as **untested**, never as passing.
