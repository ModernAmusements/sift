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

## 6. References

- Apple: PhotoKit, `PHAssetResource`, `PHPhotoLibrary.performChanges`, Vision feature prints, Contacts, `URLResourceValues`.
- DB Labs (2026): photo cleaner pipelines and Recently Deleted behaviour.
- Cleanor reference: PhotoKit access levels, Limited Library, change observer.
- App Store Review Guidelines §2.3 (accurate metadata), §5.1.1 (data collection and storage), §4.2 (minimum functionality).
