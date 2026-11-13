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
        lock.withLock {
            for asset in values where assets[asset.localIdentifier] == nil {
                assets[asset.localIdentifier] = asset
            }
        }
    }

    func image(id: String, size: CGSize) async -> UIImage? {
        let pixelWidth = Int(size.width)
        let key = "\(id)-\(pixelWidth)" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let asset = await resolve(id: id)
        guard let asset else { return nil }
        guard let image = await PhotoLibraryService.thumbnail(for: asset, size: size) else {
            return nil
        }
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        cache.setObject(image, forKey: key, cost: max(cost, 1))
        return image
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
