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

enum PhotoLibraryService {
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
    static func byteSize(of asset: PHAsset) -> Int64 {
        guard let resource = PHAssetResource.assetResources(for: asset).first else { return 0 }
        if let number = resource.value(forKey: "fileSize") as? NSNumber {
            return number.int64Value
        }
        return 0
    }

    static func thumbnail(for asset: PHAsset, size: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = false
            options.isSynchronous = false

            var resumed = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let hasError = info?[PHImageErrorKey] != nil
                guard !resumed else { return }
                if isDegraded && !isCancelled && !hasError { return }
                resumed = true
                continuation.resume(returning: image)
            }
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

private extension UIWindowScene {
    var keyWindow: UIWindow? {
        windows.first(where: \.isKeyWindow) ?? windows.first
    }
}
