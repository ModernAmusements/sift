import Foundation
import Photos
import PhotosUI
import UIKit

enum PhotoLibraryError: LocalizedError {
    case deletionFailed
    case noAccess

    var errorDescription: String? {
        switch self {
        case .deletionFailed: return "Sift could not move those items. Nothing was changed."
        case .noAccess: return "Sift does not have access to your photos."
        }
    }
}

enum ThumbnailQuality: String {
    case fast
    case high

    var deliveryMode: PHImageRequestOptionsDeliveryMode {
        switch self {
        case .fast: return .opportunistic
        case .high: return .highQualityFormat
        }
    }
}

enum PhotoLibraryService {
    struct LoadResult {
        let assets: [PHAsset]
        let scanned: [ScannedAsset]
    }

    static var status: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    static func requestAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
    }

    static func fetchAll() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.includeHiddenAssets = false
        let result = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in assets.append(asset) }
        return assets
    }

    /// Reads the library and every file size off the main thread.
    /// PhotoKit metadata is stable, and the size lookup is the expensive part;
    /// it must never run inside a SwiftUI tap handler.
    static func loadLibrary(
        onProgress: @escaping @Sendable (Int, Int) async -> Void
    ) async -> LoadResult {
        let assets = fetchAll()
        guard !assets.isEmpty else {
            AssetSizeCache.shared.flush()
            return LoadResult(assets: [], scanned: [])
        }

        // File sizes are the slow part. Read chunks on a few background workers
        // so a 10,000-asset library does not take a minute on first run.
        let chunkSize = 200
        var chunks: [[PHAsset]] = []
        chunks.reserveCapacity((assets.count / chunkSize) + 1)
        var start = 0
        while start < assets.count {
            let end = min(start + chunkSize, assets.count)
            chunks.append(Array(assets[start..<end]))
            start = end
        }

        var results = [[ScannedAsset]?](repeating: nil, count: chunks.count)
        var completed = 0
        var nextChunk = 0
        let workerCount = min(3, chunks.count)

        await withTaskGroup(of: (Int, [ScannedAsset]).self) { group in
            for _ in 0..<workerCount {
                let index = nextChunk
                let chunk = chunks[index]
                nextChunk += 1
                group.addTask {
                    if Task.isCancelled { return (index, []) }
                    let scanned = chunk.map(PhotoLibraryService.scannedAsset(from:))
                    return (index, scanned)
                }
            }

            while let (index, scanned) = await group.next() {
                results[index] = scanned
                completed += scanned.count
                await onProgress(completed, assets.count)
                if Task.isCancelled {
                    group.cancelAll()
                    break
                }
                if nextChunk < chunks.count {
                    let next = nextChunk
                    let chunk = chunks[next]
                    nextChunk += 1
                    group.addTask {
                        if Task.isCancelled { return (next, []) }
                        return (next, chunk.map(PhotoLibraryService.scannedAsset(from:)))
                    }
                }
            }
        }

        var scanned: [ScannedAsset] = []
        scanned.reserveCapacity(assets.count)
        for result in results {
            if let result { scanned.append(contentsOf: result) }
        }

        var seen = Set<String>()
        seen.reserveCapacity(scanned.count)
        for asset in scanned { seen.insert(asset.id) }
        AssetSizeCache.shared.prune(keeping: seen)
        AssetSizeCache.shared.flush()
        await onProgress(scanned.count, assets.count)
        return LoadResult(assets: assets, scanned: scanned)
    }

    static func scannedAsset(from asset: PHAsset) -> ScannedAsset {
        ScannedAsset(
            id: asset.localIdentifier,
            creationDate: asset.creationDate,
            mediaType: asset.mediaType,
            isScreenshot: isScreenshot(asset),
            pixelWidth: asset.pixelWidth,
            pixelHeight: asset.pixelHeight,
            duration: asset.duration,
            sizeBytes: byteSize(of: asset),
            isFavorite: asset.isFavorite
        )
    }

    static func isScreenshot(_ asset: PHAsset) -> Bool {
        if asset.mediaSubtypes.contains(.photoScreenshot) { return true }
        #if DEBUG
        if DemoSeed.isFixtureScreenshot(asset) { return true }
        #endif
        return false
    }

    /// PhotoKit does not expose a public size property. `fileSize` is available on the
    /// resource metadata in practice; if it ever disappears we return 0 and the UI says
    /// "size unavailable" rather than inventing a number.
    /// The result is cached by asset identifier + modification date.
    static func byteSize(of asset: PHAsset) -> Int64 {
        let id = asset.localIdentifier
        let modified = asset.modificationDate
        if let cached = AssetSizeCache.shared.size(for: id, modified: modified) {
            return cached
        }
        let bytes = readByteSize(of: asset)
        if bytes > 0 {
            AssetSizeCache.shared.store(id: id, modified: modified, bytes: bytes)
        }
        return bytes
    }

    private static func readByteSize(of asset: PHAsset) -> Int64 {
        guard let resource = PHAssetResource.assetResources(for: asset).first else { return 0 }
        if let number = resource.value(forKey: "fileSize") as? NSNumber {
            return number.int64Value
        }
        return 0
    }

    static func thumbnail(
        for asset: PHAsset,
        size: CGSize,
        quality: ThumbnailQuality = .fast
    ) async -> UIImage? {
        let box = ImageRequestBox()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let options = PHImageRequestOptions()
                options.deliveryMode = quality.deliveryMode
                options.resizeMode = .fast
                options.isNetworkAccessAllowed = false
                options.isSynchronous = false

                var resumed = false
                let id = PHImageManager.default().requestImage(
                    for: asset,
                    targetSize: size,
                    contentMode: .aspectFill,
                    options: options
                ) { image, info in
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                    let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                    let hasError = info?[PHImageErrorKey] != nil
                    guard !resumed else { return }
                    // A degraded callback can arrive without pixels first. Never
                    // resume on that, or the grid stays blank until the next open.
                    if isDegraded && image == nil && !isCancelled && !hasError { return }
                    // For sharp cards, wait for the final delivery.
                    if isDegraded && quality == .high && !isCancelled && !hasError { return }
                    resumed = true
                    continuation.resume(returning: isCancelled ? nil : image)
                }
                box.set(id)
                if Task.isCancelled { box.cancel() }
            }
        } onCancel: {
            box.cancel()
        }
    }

    static func delete(ids: [String]) async throws {
        guard !ids.isEmpty else { return }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in assets.append(asset) }
        guard !assets.isEmpty else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoLibraryError.deletionFailed)
                }
            }
        }
    }

    @MainActor
    static func presentLimitedPicker() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
            let root = scene.keyWindow?.rootViewController else { return }
        var controller = root
        while let presented = controller.presentedViewController {
            controller = presented
        }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: controller)
    }

    static var authorizationCopy: String {
        switch status {
        case .authorized: return "Full access"
        case .limited: return "Limited access"
        case .denied: return "Not allowed"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not requested"
        @unknown default: return "Unknown"
        }
    }
}

/// Lets the task cancellation handler cancel the in-flight PhotoKit request.
private final class ImageRequestBox: @unchecked Sendable {
    private let lock = NSLock()
    private var requestID: PHImageRequestID = PHInvalidImageRequestID

    func set(_ id: PHImageRequestID) {
        lock.lock()
        requestID = id
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        let id = requestID
        lock.unlock()
        guard id != PHInvalidImageRequestID else { return }
        PHImageManager.default().cancelImageRequest(id)
    }
}

private extension UIWindowScene {
    var keyWindow: UIWindow? {
        windows.first(where: \.isKeyWindow) ?? windows.first
    }
}
