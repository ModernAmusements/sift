import Foundation
import Photos

struct ScannedAsset: Identifiable, Equatable {
    let id: String
    let creationDate: Date?
    let mediaType: PHAssetMediaType
    let isScreenshot: Bool
    let pixelWidth: Int
    let pixelHeight: Int
    let duration: TimeInterval
    let sizeBytes: Int64
    let isFavorite: Bool

    var isVideo: Bool { mediaType == .video }
    var pixelCount: Int { max(pixelWidth * pixelHeight, 0) }
    var sizeText: String { Format.bytes(sizeBytes) }
    var aspectRatio: CGFloat {
        guard pixelWidth > 0, pixelHeight > 0 else { return 1 }
        return CGFloat(pixelWidth) / CGFloat(pixelHeight)
    }
}

enum DuplicateKind: String, Hashable {
    case exact
    case similar
}

struct DuplicateGroup: Identifiable, Equatable {
    let id: String
    let kind: DuplicateKind
    let assets: [ScannedAsset]
    let bestID: String?

    var totalBytes: Int64 { assets.reduce(0) { $0 + $1.sizeBytes } }
    /// Everything except the recommended keeper.
    var redundantBytes: Int64 {
        assets.filter { $0.id != bestID }.reduce(0) { $0 + $1.sizeBytes }
    }
    var redundantIDs: [String] {
        assets.filter { $0.id != bestID }.map(\.id)
    }
}

struct ContactRecord: Identifiable, Equatable {
    let id: String
    let name: String
    let phoneNumbers: [String]
    let emails: [String]
    let imageData: Data?
    let fieldCount: Int

    var initials: String {
        let parts = name.split(separator: " ").prefix(2).compactMap(\.first)
        return parts.isEmpty ? "?" : String(parts).uppercased()
    }

    var subtitle: String {
        if let phone = phoneNumbers.first { return phone }
        if let email = emails.first { return email }
        return "No phone or email"
    }
}

struct ContactGroup: Identifiable, Equatable {
    let id: String
    let contacts: [ContactRecord]

    var keeper: ContactRecord? {
        contacts.max { lhs, rhs in
            if lhs.fieldCount != rhs.fieldCount { return lhs.fieldCount < rhs.fieldCount }
            return (lhs.imageData != nil ? 1 : 0) < (rhs.imageData != nil ? 1 : 0)
        }
    }

    var removableCount: Int { max(contacts.count - 1, 0) }
    var title: String { keeper?.name ?? "Contact" }
}

struct ScanReport {
    var scannedAt: Date
    var totalAssetCount: Int
    var totalLibraryBytes: Int64
    var screenshots: [ScannedAsset]
    var videos: [ScannedAsset]
    var largeFiles: [ScannedAsset]
    var blurry: [ScannedAsset]
    var duplicateGroups: [DuplicateGroup]
    var similarGroups: [DuplicateGroup]

    static let empty = ScanReport(
        scannedAt: .distantPast,
        totalAssetCount: 0,
        totalLibraryBytes: 0,
        screenshots: [],
        videos: [],
        largeFiles: [],
        blurry: [],
        duplicateGroups: [],
        similarGroups: []
    )

    var largeVideos: [ScannedAsset] {
        videos.filter { $0.sizeBytes >= 50_000_000 || $0.duration >= 60 }
    }

    var largePhotos: [ScannedAsset] {
        largeFiles.filter { !$0.isVideo }
    }

    var duplicateExtras: [ScannedAsset] {
        let ids = Set(duplicateGroups.flatMap(\.redundantIDs))
        return allByID.filter { ids.contains($0.key) }.map(\.value)
    }

    var similarExtras: [ScannedAsset] {
        let ids = Set(similarGroups.flatMap(\.redundantIDs))
        return allByID.filter { ids.contains($0.key) }.map(\.value)
    }

    var potentialBytes: Int64 {
        var seen = Set<String>()
        var total: Int64 = 0
        for asset in screenshots + duplicateExtras + similarExtras + blurry
        where seen.insert(asset.id).inserted {
            total += asset.sizeBytes
        }
        return total
    }

    private var allByID: [String: ScannedAsset] {
        var map: [String: ScannedAsset] = [:]
        for asset in screenshots + videos + largeFiles + blurry { map[asset.id] = asset }
        for group in duplicateGroups + similarGroups {
            for asset in group.assets { map[asset.id] = asset }
        }
        return map
    }

    /// Total size of the given assets, used to know how much a delete session moved.
    func bytes(for ids: [String]) -> Int64 {
        ids.compactMap { allByID[$0]?.sizeBytes }.reduce(0, +)
    }

    func removing(ids: Set<String>) -> ScanReport {
        guard !ids.isEmpty else { return self }
        func prune(_ list: [ScannedAsset]) -> [ScannedAsset] {
            list.filter { !ids.contains($0.id) }
        }
        func pruneGroups(_ groups: [DuplicateGroup]) -> [DuplicateGroup] {
            groups.compactMap { group in
                let remaining = group.assets.filter { !ids.contains($0.id) }
                guard remaining.count >= 2 else { return nil }
                let bestID = group.bestID.flatMap { best in
                    remaining.contains(where: { $0.id == best }) ? best : remaining.first?.id
                }
                return DuplicateGroup(
                    id: group.id,
                    kind: group.kind,
                    assets: remaining,
                    bestID: bestID
                )
            }
        }
        let removedBytes = ids.compactMap { allByID[$0]?.sizeBytes }.reduce(0, +)
        return ScanReport(
            scannedAt: scannedAt,
            totalAssetCount: max(totalAssetCount - ids.count, 0),
            totalLibraryBytes: max(totalLibraryBytes - removedBytes, 0),
            screenshots: prune(screenshots),
            videos: prune(videos),
            largeFiles: prune(largeFiles),
            blurry: prune(blurry),
            duplicateGroups: pruneGroups(duplicateGroups),
            similarGroups: pruneGroups(similarGroups)
        )
    }
}

struct StorageSnapshot {
    let totalBytes: Int64
    let freeBytes: Int64

    var usedBytes: Int64 { max(totalBytes - freeBytes, 0) }
    var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return min(max(Double(usedBytes) / Double(totalBytes), 0), 1)
    }
}
