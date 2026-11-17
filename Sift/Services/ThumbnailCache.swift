import Photos
import UIKit

final class ThumbnailCache {
    static let shared = ThumbnailCache()

    private let cache = NSCache<NSString, UIImage>()
    private var assets: [String: PHAsset] = [:]
    private let lock = NSLock()

    private init() {
        cache.countLimit = 600
        cache.totalCostLimit = 120 * 1024 * 1024
    }

    func register(_ values: [PHAsset]) {
        lock.lock()
        for asset in values where assets[asset.localIdentifier] == nil {
            assets[asset.localIdentifier] = asset
        }
        lock.unlock()
    }

    func image(
        id: String,
        size: CGSize,
        quality: ThumbnailQuality = .fast
    ) async -> UIImage? {
        let pixelWidth = Int(size.width)
        // Fast grid thumbnails and high-resolution cards must not share a slot.
        let key = "\(id)-\(pixelWidth)-\(quality.rawValue)" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let asset = await resolve(id: id)
        guard let asset else { return nil }
        guard let image = await PhotoLibraryService.thumbnail(
            for: asset,
            size: size,
            quality: quality
        ) else {
            return nil
        }

        // Decoding happens on the main thread at draw time otherwise, which makes
        // fast scrolling stutter. Prepare the bitmap here, then cache it.
        let prepared = await Task.detached(priority: .utility) {
            image.preparingForDisplay() ?? image
        }.value

        let scale = prepared.scale
        let cost = Int(prepared.size.width * prepared.size.height * scale * scale * 4)
        cache.setObject(prepared, forKey: key, cost: max(cost, 1))
        return prepared
    }

    private func resolve(id: String) async -> PHAsset? {
        if let cached = lock.withLock({ assets[id] }) { return cached }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        let asset = result.firstObject
        if let asset {
            lock.withLock { assets[id] = asset }
        }
        return asset
    }
}
