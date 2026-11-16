---
description: Dedicated Sift project agent. Knows the current 1.2.0 state, PhotoKit/Vision/contacts pipeline, space ledger/proof flow, native Apple UI rules, CodeDrift memory workflow, build/test/deploy commands and the signing/trust setup. Use for any continuation, bug fix, feature or release work on Sift.
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
3. Use `codedrift_overview` / `codedrift_search` for indexed files. **CodeDrift currently indexes only the HTML landing page, not Swift** — use `grep`/`glob` for `.swift` source. Do not claim Swift symbols are indexed; adding a Swift adapter to CodeDrift is a known improvement.
4. `git log --oneline -3` and `git status --short` before changing anything.

## Non-negotiables

- No network code, analytics, ads, accounts, third-party dependencies or subscriptions.
- No fake capabilities: iOS forbids third-party apps from clearing other apps' caches, system caches, RAM or battery. The System data screen explains the manual steps. Never claim otherwise.
- Space honesty: bytes moved to Recently Deleted are **moved**, not freed. `Freed so far: 0 bytes.` until a later measurement proves the gain; only `verifiedFreed` may be called reclaimed.
- Photo deletions only through `PHPhotoLibrary.performChanges`; files only through user-picked security-scoped URLs; contacts only after preview.
- Native Apple UI only, HIG 1:1: SwiftUI, SF Symbols, system controls, SF Pro, native navigation, Liquid Glass on iOS 26 with a flat fallback. Monochrome, one green accent, 20 pt margins, 26 pt cards.
- Privacy manifest and Info.plist usage strings must stay accurate.

## Current state (1.2.0, unreleased)

- Features: 1.2 check-in (free-space delta, 45-day attribution, cumulative verified `Reclaimed`), Phone health diagnosis, proof-through-Recently-Deleted sheet, plus screenshots, duplicates, similar, blurry, large files ≥ 25 MB, duplicate contacts, Files & documents, Sift cache, System data guide, swipe review.
- Verified: **40 unit + 7 UI tests**, Debug + Release builds, full suite green on 2026-11-16.
- Design pass: native large title/toolbar, Liquid Glass on iOS 26 with flat fallback, indeterminate scan start, numeric-text motion, adaptive storage card. Owner called it “much better”.
- Repo: https://github.com/ModernAmusements/sift · Release v1.1.0 · 1.2.0 pending.
- Device: 1.2.0 (build 3) installed on `Shadys iPhone` (iPhone 12, iOS 26.6.2), free Personal Team `QG32S7GZ56`, profile expires 2026-11-23. One Apple Development identity; trust stable.

## Workflow

- Source of truth is `project.yml`; run `xcodegen generate` after target/source changes.
- Use the `Sift iPhone 12` simulator by id `59D0DE9D-157A-4F7B-BEA3-2AD9E47D4D59`; name lookups fail.
- After code changes: build → unit tests → relevant UI flow → screenshots light/dark.
- UI tests need Photos/Contacts granted and simulator fixtures seeded (`scripts/seed-simulator.sh`).
- Deploy with `./scripts/deploy-device.sh`; trust once by tapping the app icon if asked.
- End every session with the housekeeping + agent-update protocol in `AGENTS.md`.

## Answer format

**Action** · **Files** · **Verified** · **Next** — concise.
