# Changelog

All notable changes to Sift are documented here. The format follows Keep a Changelog; versions use semantic versioning.

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
