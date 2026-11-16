# Sift 1.2 — Check-in

**Status:** specified, not implemented. 2026-11-16.
**Pain it fixes:** the user cannot tell what is safe to lose, at the moment the phone fails — and after acting, cannot tell whether anything happened. See `PRODUCT.md` → "The pain point", "Slowness", "Space accounting".

**One promise for this release:** Sift tells you the truth about your space, does the part it can do, and shows you the number at the end.

---

## The flow

Check-in → Diagnose → Clean → Prove. Four stages, one entry point (the Home screen), no new tabs.

```
Home (Check-in)      → card: real delta since last visit
  └ Diagnose         → five honest readings, one action
      └ Clean        → existing scan / review / swipe, plus a true subtotal
          └ Prove    → "moved" ≠ "freed", measured, with the last mile
```

## 1. Check-in — Home card

Replaces the storage card's static "1.2 GB free" with a before/now comparison.

| State | Copy |
| --- | --- |
| First run, no history | `1.2 GB free of 128 GB` + `Baseline saved. Sift shows the real change next time.` |
| Positive change | `3.2 GB came back since Tue 11 Nov` + `1.4 GB of that was freed by Sift.` (second line only when a session is attributed) |
| Negative change | `1.6 GB less free space since Tue 11 Nov` + `New photos, downloads or app updates.` |
| Under 100 MB | `About the same as last time` — never invent a movement |

Rules:

- Delta = `freeBytes(now) − freeBytes(last snapshot)`, same key and same device only.
- Show a delta only when `|delta| ≥ 100 MB`. Below that, say "about the same".
- Round **down** in the user's disfavour, always. 1 decimal under 10 GB (`3.2 GB`), whole GB above (`14 GB`). Never `≈`, never `up to`.
- Negative deltas are shown. An app that only reports good news is the category we are leaving.
- No cause is claimed unless Sift itself performed the deletion.

## 2. Diagnose — "What Sift can see"

Read-only. Every row is a measurement or a link; none is a score, gauge or needle.

| Row | Source | Copy when notable |
| --- | --- | --- |
| Free space | `StorageService.snapshot().freeBytes` | `Under 1 GB. iOS needs working room: the camera can refuse to save and updates stall below this.` |
| Low Power Mode | `ProcessInfo.processInfo.isLowPowerModeEnabled` | `On. iOS is holding back background work to save battery.` |
| Thermal pressure | `ProcessInfo.processInfo.thermalState` | `.serious/.critical`: `iOS is limiting performance while the phone is warm.` |
| Library weight | last `ScanReport` | `41 GB in Photos, much of it screenshots and repeat shots.` |
| Battery health | none — no public API | `Check Settings → Battery → Battery Health & Charging. Sift cannot read it.` |

Thresholds (`< 1 GB` critical, `< 5 GB` tight) are Sift's guidance, not an Apple figure, and the copy must never imply otherwise.

One primary action: **Find what is safe to remove** → existing scan.

Banned words on this screen: boost, speed up, optimize, junk, clean cache, cool down, RAM.

## 3. Clean — existing flows, one new number

Scan, review, similar, swipe and contacts stay as they are. Two additions:

- The selection bar shows `Selected 2.1 GB`, and beneath it `About 2.0 GB of this is already stored elsewhere` when the duplicate/similar engine can prove it.
- A single honest line above the confirm button: **`This frees space only once Recently Deleted is emptied.`**

## 4. Prove — the last mile

The screen no competing cleaner has.

1. After confirmation: `Moved 2.1 GB to Recently Deleted.` and, underneath, `Freed so far: 0 bytes. iOS holds deleted photos for 30 days before the space returns.`
2. Primary: **Open Recently Deleted** — attempts `photos-redirect://`, and on failure shows the manual path (Photos → Albums → Utilities → Recently Deleted → Select → Delete All). The scheme is undocumented: keep it in one file (`PhotosDeepLink.swift`) so it can be deleted in a day if review objects.
3. On return to the app (`scenePhase == .active`) measure again, and keep a **Check again** button for the impatient.
4. When the measured delta is ≥ 100 MB: `Verified: 2.0 GB freed` + `Sift moved 2.1 GB. iOS returned 2.0 GB.`
5. Each completed session writes one line to the check-in history: date, bytes moved, bytes verified. Settings gets a `Reclaimed` row reading `14.2 GB verified since 12 Nov`.

Never claim the moved number as freed. The gap between the two is the product's honesty made visible.

---

## Data

```swift
struct SpaceCheckIn: Codable, Identifiable {
    let id: UUID
    let date: Date
    let totalBytes: Int64
    let freeBytes: Int64
    var movedBytes: Int64?      // set when a Sift session completes
    var verifiedFreedBytes: Int64?  // set when a later measurement confirms it
}
```

- Store in `UserDefaults` under `spaceCheckIns`, JSON, cap the last 30 entries — but never prune a verified entry, because `Reclaimed` is cumulative and must not shrink. `UserDefaults` is already declared in the privacy manifest (`CA92.1`), so the manifest does not change.
- One snapshot per launch, plus one after any delete session and one per "Check again". Deduplicate snapshots closer than 10 minutes apart.
- Attribution window for `movedBytes` → `verifiedFreedBytes`: 45 days, after which the session is marked expired rather than fudged.

## Edge cases

- Snapshot unavailable (volume lookup fails) → hide the delta entirely; never render `0 bytes`.
- iCloud Optimize Storage on: free space can rise without any deletion (offload). Copy stays attribution-free, so this is already honest; do not claim "Sift freed".
- Photos permission denied → Check-in and Diagnose still work; Clean explains the permission.
- Device restored or replaced → totals differ; detect a total-capacity change of > 5% and start a fresh baseline instead of showing nonsense.
- Negative delta larger than the library size → cap the copy at "less free space" without a number.
- Limited-library access → deltas still valid; the library-weight row states `Limited access` and never extrapolates.

## Accessibility

- Every row is one VoiceOver element: label + value, e.g. "Free space, 1.2 gigabytes of 128, tight".
- Delta text at Dynamic Type XXXL wraps, never truncates to `3.2 G…`.
- No colour-only meaning: the critical headroom row uses a word ("Tight") plus the figure.
- Reduce Motion: no counting animation on the verified number; render final values.
- 44 pt targets for all actions, including "Check again".

## Tests

Unit (`Tests/SiftTests`):

- `SpaceLedger.delta` — positive, negative, sub-100 MB suppression, first-run baseline, capacity-change reset.
- Rounding — never rounds up; `3.2 GB`, `14 GB`, `999 MB`.
- Attribution window — 45-day expiry, moved-without-verified stays unattributed.
- `HealthReading` mapping for all four thermal states and Low Power on/off.

UI (`Tests/SiftUITests`):

- Launch with fixtures → baseline copy on first run, delta on second launch.
- Delete session → Prove screen shows `Freed so far: 0 bytes` before returning, `Verified` after.

## Definition of done

`xcodegen generate`, clean Debug + Release build, unit and UI tests green, exercised in the iPhone 12 simulator light and dark at XL text, VoiceOver pass on the four stages, no new permissions, no network symbols, privacy manifest unchanged, one device pass before tagging.

## Out of scope for 1.2

- Per-app storage attribution, iCloud Backup management, uninstall helpers (impossible, see `PRODUCT.md`).
- Live Photo → still, video transcode, offload/export.
- Screenshot OCR triage.
- History charts and widgets.

## Open questions for the owner — answered 2026-11-16

1. Accept the undocumented `photos-redirect://` deep link, isolated and fallback-protected? **Yes** — `PhotosDeepLink` is the only scheme, the manual path is always visible, and deleting the file breaks nothing.
2. Should Settings show the cumulative `Reclaimed` figure? **Yes** — implemented as `X verified since <day>`.
3. Show negative deltas on Home from day one? **Yes** — `X less free space since <day>`.
