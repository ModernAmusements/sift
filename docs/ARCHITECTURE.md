# Architecture

## Shape

```
SiftApp
 └─ RootView
     ├─ OnboardingView          (first launch)
     └─ HomeView                (NavigationStack)
         ├─ ReviewView          screenshots · videos · blurry
         ├─ SimilarView         duplicate / similar groups
         ├─ SwipeView           keep-or-delete deck
         ├─ ContactsView        duplicate contact groups
         └─ SettingsView        privacy, sensitivity, links
```

`ScanEngine` is the only stateful coordinator. Views never touch PhotoKit directly except thumbnail rendering; all mutations go through services.

## Layers

```
Features/   SwiftUI views, local view state only
Models/     value types: ScannedAsset, DuplicateGroup, ContactGroup, ScanReport
Services/   PhotoLibraryService, ImageAnalyzer, SimilarityEngine, ContactService,
            StorageService, ThumbnailCache, ScanEngine
```

### ScanEngine (`@MainActor`, ObservableObject)

Published state: `stage`, `progress`, `report`, `isScanning`, `errorMessage`.

Pipeline:

1. `preparing` — authorization, storage snapshot.
2. `library` — fetch assets, read metadata and sizes.
3. `images` — bounded TaskGroup (4 concurrent): thumbnail → dHash → sharpness → feature print.
4. `grouping` — exact duplicates (hash buckets + union-find), similar shots (per-day feature-print distance + union-find), blurry selection.
5. `contacts` — enumerate and group by shared phone/email.
6. `done` — publish `ScanReport`, persist last scan date.

The engine never holds full-resolution images. Signatures for 10k assets are ~10k × (feature print 2048 B + hash 8 B + scores) ≈ 25 MB, acceptable. Thumbnails are cached at ≤ 320 px in a 120 MB `NSCache`.

### Scan rules

- **dHash**: 9×8 grayscale, bit = left pixel > right pixel. 64 bits. Compare within pixel-dimension buckets, Hamming ≤ 2, and require a Vision feature-print distance ≤ 0.03. Two signals together: the hash catches re-encoded copies, the feature print rejects different photos with a similar composition.
- **Feature print**: `VNGenerateImageFeaturePrintRequest` on a 320 px thumbnail. `computeDistance` is L2. Compare only assets captured on the same calendar day — similar shots are almost always burst-adjacent. Threshold default 0.15, adjustable 0.08–0.30 (lower = stricter). When Vision is unavailable, an 8×8 center-cropped RGB mosaic is compared with `0.66 ×` the feature threshold. Calibrated on seeded media: unrelated photos ≥ 0.56 on feature prints, variants 0.05–0.13.
- **Blur**: variance of Laplacian on 160×160 grayscale. Threshold 28 (calibrated on seeded assets). Exclude screenshots and videos.
- **Best shot**: max sharpness, tie-break pixel count, then file size. Screenshots never win over photos.
- **Sizes**: `PHAssetResource` file size via the documented resource metadata when available (KVC `fileSize`); if absent, size is `0` and the UI says "Size unavailable" instead of guessing.

### Deletion

```swift
try await PHPhotoLibrary.shared().performChanges {
    PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
}
```

- System confirmation is shown by iOS.
- Assets move to Recently Deleted for 30 days.
- On success, `ScanEngine.removeAssets(ids:)` prunes every list and group; the dashboard updates without a rescan.
- On failure, the review screen stays open with a retry.

### Contacts

- Fetch unified contacts with the minimum keys: names, organization, phones, emails, image.
- Normalize phone to digits; compare the last 8 digits (minimum 7). Normalize email to lowercase.
- Union-find groups contacts that share any handle. Name-only matches are **not** merged.
- Keeper = richest record (field count, then image). Merge missing phones/emails into the keeper; save keeper update + duplicate deletions in one `CNSaveRequest`.
- The UI previews group members and requires explicit confirmation. No automatic merge on scan.

### Storage

`URL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])` on the home directory. This is the honest number iOS gives third-party apps. Library size is the sum of asset file sizes; it is shown separately from device storage because Recently Deleted and iCloud optimisations make the two differ.

### Permissions

- Photos: `.readWrite`. Handle `.notDetermined`, `.denied`, `.restricted`, `.limited`.
- Limited access: banner with "Select more photos" (`PHPhotoLibrary.shared().presentLimitedLibraryPicker`) and "Open Settings".
- Contacts: requested only when the user opens Contacts cleanup, never at launch.

## Concurrency

- Swift 5 language mode, async/await throughout.
- Engine on `@MainActor`; analysis in `TaskGroup` with a concurrency cap of 4.
- `Task.isCancelled` checked per asset and before publishing.
- PhotoKit and Vision are thread-safe; PHAsset references stay behind the service boundary in v1.

## Dependencies

None. System frameworks only: SwiftUI, PhotosUI, Photos, Vision, Contacts, CoreImage, Accelerate, UIKit (haptics, settings URL).

## Testing

- Unit: dHash determinism, Hamming distance, union-find clustering, phone/email normalization, keeper selection, byte formatting.
- Simulator: seeded PNG/JPEG/MOV set via `simctl addmedia`; scan → review → delete → count update; screenshots light/dark.

## Risks

| Risk | Mitigation |
| --- | --- |
| Private `fileSize` KVC changes | Fallback to size unavailable; never crash. Keep access isolated in `PhotoLibraryService`. |
| Vision slow on old devices | Thumbnail-only, 4-way concurrency, cancellable, progress. |
| False-positive similar groups | Same-day restriction, strict threshold, user reviews every deletion. |
| Contact merge data loss | Keeper merge only, preview, one save request, no name-only merges. |
| App Review rejects "cleaner" claims | Copy is limited to media/contacts; no cache/RAM/battery claims. |
