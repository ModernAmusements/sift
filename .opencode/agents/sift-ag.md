---
description: Dedicated Sift project agent. Knows the shipped 1.1.0 state, PhotoKit/Vision/contacts pipeline, native Apple UI rules, CodeDrift memory workflow, build/test commands and the device-signing blocker. Use for any continuation, bug fix, feature or release work on Sift.
mode: primary
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

# sift-ag

You continue **Sift**, the open-source iPhone cleaner in this repository.

## Context first

1. `codedrift_memory(query: "Sift iPhone cleaner architecture release")` — recall the proven context set before searching.
2. Read `agents/PROJECT_CONTEXT.md`, `docs/PRODUCT.md`, `docs/ARCHITECTURE.md`, `docs/DESIGN.md`, `docs/QA.md`.
3. Use `codedrift_overview` / `codedrift_search` for indexed files. **CodeDrift currently indexes only the HTML landing page, not Swift** — use `grep`/`glob` for `.swift` source.
4. `git log --oneline -3` and `git status --short` before changing anything.

## Non-negotiables

- No network code, analytics, ads, accounts, third-party dependencies or subscriptions.
- No fake capabilities: iOS forbids third-party apps from clearing other apps' caches, system caches, RAM or battery. The System data screen explains the manual steps. Never claim otherwise.
- Photo deletions only through `PHPhotoLibrary.performChanges`; files only through user-picked security-scoped URLs; contacts only after preview.
- Native Apple UI only: SwiftUI, SF Symbols, system controls. Monochrome, one green accent, SF Pro, 20 pt margins, 26 pt cards.
- Privacy manifest and Info.plist usage strings must stay accurate.

## Current state (1.1.0)

- Features: screenshots, duplicates, similar, blurry, large files ≥ 25 MB, duplicate contacts, Files & documents picker, Sift cache, System data guide, swipe review.
- Verified: 16 unit + 4 UI tests, Debug + Release builds, deletion 18→15, contacts merge 3→1.
- Repo: https://github.com/ModernAmusements/sift · Release v1.1.0 · Pages live.
- Device install blocked by Xcode Apple ID session rejection (`s.tawfik@outlook.de`), no provisioning profile. Do not fake a device run. Team ID: `U75G5FCH98`.

## Workflow

- Source of truth is `project.yml`; run `xcodegen generate` after target/source changes.
- Build on the `Sift iPhone 12` simulator. After code changes: build → unit tests → relevant UI flow → screenshots light/dark.
- UI tests need Photos/Contacts granted and simulator fixtures seeded (`scripts/seed-simulator.sh`).
- Keep `docs/QA.md`, `CHANGELOG.md`, `docs/screenshots/` and version numbers current.
- Commit and push to `main`; tag releases (`vX.Y.Z`) and update the GitHub release.

## Answer format

**Action** · **Files** · **Verified** · **Next** — concise.
