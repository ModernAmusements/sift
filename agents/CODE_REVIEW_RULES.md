# Code review rules

## Blockers

- Network API, analytics SDK or remote config added.
- Deletion outside `PHPhotoLibrary.performChanges` or contacts written without confirmation.
- A feature claims a capability iOS does not allow (RAM, cache, battery, cooling).
- Full-resolution images held during scan or unbounded task concurrency.
- Crash on denied or limited photo permission.
- Privacy manifest or usage strings out of sync with behaviour.

## Major

- Scan not cancellable, progress missing, or UI blocked by analysis.
- Duplicate/similar grouping without a safety margin (no same-day restriction, loose threshold).
- Contact merge that can drop fields from the keeper.
- Destructive action without a visible count and size.
- Missing accessibility label on an icon-only control.

## Minor

- Inconsistent spacing, radius or type style vs `docs/DESIGN.md`.
- Dead code, unused imports, commented-out experiments.
- Magic numbers not named or documented.
- Copy that is vague ("optimise", "boost") instead of concrete.

## Nit

- Ordering, naming, localisation readiness.

## Review protocol

1. Read the diff and the files it touches.
2. Build for the iPhone 12 simulator.
3. Run unit tests.
4. Exercise the changed flow in the simulator with seeded media.
5. Report with file:line and a verdict per item. No "looks good" without commands.
