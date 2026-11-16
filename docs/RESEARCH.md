# Research — what a real iPhone cleaner can do

Researched 2026-11-13 against current iOS 18/26 behaviour and the App Store cleaner category.

## 1. Platform truth

| Capability | Possible? | API / constraint |
| --- | --- | --- |
| Read photo/video metadata | Yes | PhotoKit `PHAsset`, `PHAssetResource` |
| Delete photos/videos | Yes, with confirmation | `PHPhotoLibrary.performChanges`; items go to **Recently Deleted** for 30 days |
| Analyze photo content on-device | Yes | Vision, CoreImage, Accelerate |
| Read/write contacts | Yes, with permission | Contacts framework |
| Delete user-picked files | Yes, per file | `UIDocumentPicker` security-scoped URLs + `FileManager` |
| Clear Sift's own cache | Yes | `Caches/` and `tmp/` in the app container |
| Show device free/used space | Partly | `URLResourceValues.volumeAvailableCapacityForImportantUsage` + total capacity |
| Clear another app's cache | **No** | Apps are sandboxed; only the owning app or iOS manages its container |
| Clear system cache / "other" storage | **No** | No public API; reboot/offload apps only |
| Free RAM | **No honest way** | iOS manages memory; killing apps is not permitted and does not help |
| Cool the CPU / extend battery | **No** | Not a software-cleanable property |
| Permanently delete in one tap | **No** | System confirmation + Recently Deleted; user must empty Recently Deleted in Photos |

Sources: [PhotoKit reference](https://cleanor.app/reference/photokit), [How iPhone photo cleaner apps work (DB Labs, 2026)](https://dblabsapps.com/blog/how-iphone-photo-cleaner-works/), [What is a photo cleaner app (DB Labs, 2026)](https://dblabsapps.com/blog/what-is-a-photo-cleaner-app/).

## 2. Category teardown

| App type | Typical features | Business model | Weakness we exploit |
| --- | --- | --- | --- |
| CleanMyiPhone-style suite | Photos, videos, contacts, "smart clean", storage widget | Weekly/monthly subscription, hard paywall after scan | Scan is bait; deletion often paywalled; opaque "system junk" claims |
| Swipe cleaners (Swype, Cleanup) | Tinder-style swipe on photos/screenshots | Subscription + ads | Fun but shallow; duplicates rarely grouped; no contacts |
| "Booster" apps | Fake RAM/battery/cooling gauges | Ads/subscription | Misleading; not technically real |
| Free utility apps | Screenshot deletion only | Ads | Narrow, noisy, privacy unclear |

Differentiator for Sift: **no paywall, no ads, no network, no account, auditable source.** The entire value is in the scan quality and the review flow.

## 3. Scan techniques

- **Exact/near duplicates:** perceptual hashing. dHash (difference hash) is cheap, deterministic and robust to re-encoding/resizing. 64-bit hash, Hamming distance ≤ 2, cross-checked with a feature-print distance ≤ 0.03. Compare only within pixel-dimension buckets.
- **Similar photos:** Vision `VNGenerateImageFeaturePrintRequest`. Feature prints are compact embeddings; `computeDistance` yields L2 distance. Distances below ~0.15 mean the same scene in our calibration; unrelated photos measured ≥ 0.56. Vision feature prints return nil in the iOS 18.4 Simulator; Sift falls back to a center-cropped 8×8 RGB mosaic. Restricting comparison to the same calendar day removes most false positives and cuts O(n²) to O(sum(day²)).
- **Best shot:** sharpness (Laplacian variance), resolution, file size. Burst photos share a timestamp; the sharpest frame is usually the keeper.
- **Blur:** variance of the Laplacian on a small grayscale image. Fast, good enough to rank; absolute thresholds must be calibrated per pipeline. We use 160×160 and a conservative cutoff so the list is short and credible.
- **Screenshots:** `PHAsset.mediaSubtypes.contains(.photoScreenshot)` — exact, no ML needed.
- **Large files:** every photo or video whose resource size is at least 25 MB, or any video at least 60 seconds. Sorted by size; the user confirms each deletion.
- **Files:** the document picker grants per-file access; Sift can only see and remove what the user selects. iCloud deletion semantics depend on the provider.
- **Duplicate contacts:** normalize phone to digits and compare the last 8; lowercase emails; union-find. Merge only on shared handles, never name alone.

## 4. Storage accounting

Third-party apps cannot read the system's "iPhone Storage" breakdown. The honest approximation:

- Device total: `volumeTotalCapacity`.
- Free: `volumeAvailableCapacityForImportantUsage` (includes purgeable space, the number iOS uses for install decisions).
- Library: sum of `PHAssetResource` sizes.
- Reclaimed: sum of deleted assets' sizes; the OS frees it, sometimes only after Recently Deleted is emptied.

Copy must say "estimated" where appropriate. Never claim the device gained exactly the scanned bytes.

## 5. Privacy and review risks

- Photo library access is sensitive. Usage strings must name the benefit: "Sift reads your photo library on this iPhone to find screenshots, duplicates, blurry photos and large files."
- Apple requires a privacy manifest (`PrivacyInfo.xcprivacy`) and justified required-reason APIs. We use UserDefaults (onboarding flag, settings) → reason `CA92.1`.
- No tracking, no collected data, no third-party SDKs — the manifest says so.
- Cleaner apps are scrutinised for misleading claims. Our copy avoids cache/RAM/battery promises entirely.
- Deletion must remain user-initiated. Scan results are suggestions; nothing is selected for deletion by default except duplicate groups where the keeper is clear, and even then the user confirms.

## 6. Niche analysis — 2026-11-16

Question: hundreds of thousands of cleaners exist; what do all of them miss?

### Honesty is no longer a differentiator

Newer entrants (DustFox, FreeMemory, Swype Photo Cleaner, CleanX, Live Photo Cleaner 2.0) all claim on-device processing, no tracking, no network. "Free, honest, private" is now **table stakes**, not a position. Meanwhile the old grievance stands: a CleanX review sort (Oct 2026) of 4,036 reviews across five big cleaners found 1,456 one-to-two-star reviews, roughly **three in five about billing**, one in seven about ads.

### Every obvious sub-niche is already occupied

| Wedge | Who already owns it | Verdict |
| --- | --- | --- |
| Offload originals to Mac/external drive, verify, then delete | Offload (open source, iOS 18+), iMole (CLI), Photo Sentinel, FreeMemory | taken |
| Live Photo → still | CleanMyPhone, LiveConvert, DustFox, Live Photo Cleaner 2.0 | taken, commoditised |
| Duplicates / similar / blurry / screenshots / large video | Apple Photos' own Duplicates + Utilities, plus every cleaner | taken, and Apple is free |
| "Tell me how much you want to save" | Live Photo Cleaner 2.0 ("choose how much space you want to save") | claimed |
| Swipe review UI | Swype, Cleanup, dozens | taken |

So the answer cannot be a feature list. It has to be a job nobody finishes.

### What they all structurally miss

1. **The last mile.** PhotoKit deletions go to Recently Deleted, where **zero bytes are freed**. Every app stops there and calls it cleaned. Only DustFox even mentions the 30-day trap; nobody guides the user through emptying it, which is where 5–20 GB usually hides.
2. **Proof.** Numbers are forecasts ("will free 12.4 GB"), never a measured before/after read from the volume. This is exactly the gap that produced the category's fake-numbers reputation.
3. **The "why".** Lists show items and sizes. Nothing explains *why this one is safe* ("already stored at full resolution twice", "sharpness 12% of the keeper", "screenshot of a boarding pass from 2023").
4. **Shared libraries.** iCloud Shared Photo Library and family libraries create duplicates across two owners. Apple's Duplicates album ignores this. No cleaner handles it.
5. **Ongoing hygiene.** All one-shot manual runs. No App Intents/Shortcuts, no "review 3 minutes every Sunday".
6. **Auditability.** Sift is still the only cleaner whose claims can be inspected, built and reproduced.

### Recommendation: own the last mile, and prove it

Position: **the only cleaner that finishes the job and shows the real number.**

- Measure free space before (`StorageService` already reads `volumeAvailableCapacityForImportantUsage`).
- After deletion, a guided last-mile screen: deep link into Photos → Recently Deleted, then poll the volume and show the **verified** delta.
- A per-session receipt: bytes moved, bytes actually freed, date, and per-item reasons.
- Reuse existing evidence for the "why" line: dHash distance, blur score, dimensions, same-day Vision distance.

Why this wedge fits Sift: it is nearly free to build, it needs no network, it is testable in the simulator and on device, and **a subscription app cannot adopt it without admitting its earlier number was a guess**.

Explicitly not chasing: offload/export (market taken, wants a Mac companion), Live→still (commoditised), ML screenshot triage (accuracy risk on a trust-first app), caretaker multi-account mode (needs a server or awkward handoff).

### Sources
- DB Labs, "Are iPhone Cleaner Apps Safe?" (Mar 2026)
- Unstar, "5 Phone Cleaner Apps Ranked" (Jun 2026)
- FreeMemory, "iPhone Cleaner Apps and the Weekly Subscription Trap" (Oct 2026)
- CleanX review sort, 4,036 reviews (Oct 2026)
- DustFox Live Photos page; LiveConvert App Store listing; Live Photo Cleaner 2.0 listing; Offload/iMole/Photo Sentinel repos

## 7. References


- Apple: PhotoKit, `PHAssetResource`, `PHPhotoLibrary.performChanges`, Vision feature prints, Contacts, `URLResourceValues`.
- DB Labs (2026): photo cleaner pipelines and Recently Deleted behaviour.
- Cleanor reference: PhotoKit access levels, Limited Library, change observer.
- App Store Review Guidelines §2.3 (accurate metadata), §5.1.1 (data collection and storage), §4.2 (minimum functionality).
