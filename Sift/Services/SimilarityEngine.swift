import Foundation
import Vision

struct UnionFind {
    private(set) var parent: [Int]
    private(set) var rank: [Int]

    init(count: Int) {
        parent = Array(0..<count)
        rank = Array(repeating: 0, count: count)
    }

    mutating func find(_ value: Int) -> Int {
        var value = value
        while parent[value] != value {
            parent[value] = parent[parent[value]]
            value = parent[value]
        }
        return value
    }

    mutating func union(_ lhs: Int, _ rhs: Int) {
        let left = find(lhs)
        let right = find(rhs)
        guard left != right else { return }
        if rank[left] < rank[right] {
            parent[left] = right
        } else if rank[left] > rank[right] {
            parent[right] = left
        } else {
            parent[right] = left
            rank[left] += 1
        }
    }

    mutating func groups() -> [[Int]] {
        var buckets: [Int: [Int]] = [:]
        for index in parent.indices {
            let root = find(index)
            buckets[root, default: []].append(index)
        }
        return buckets.values.filter { $0.count > 1 }.sorted { $0[0] < $1[0] }
    }
}

enum SimilarityEngine {
    static func hamming(_ lhs: UInt64, _ rhs: UInt64) -> Int {
        (lhs ^ rhs).nonzeroBitCount
    }

    /// A duplicate must match on both the perceptual hash and the feature print.
    /// Similar shots score ~0.05–0.2; a re-encoded copy sits near 0.
    private static func isSameFrame(
        _ lhs: VNFeaturePrintObservation?,
        _ rhs: VNFeaturePrintObservation?,
        maxDistance: Float,
        hashesIdentical: Bool
    ) -> Bool {
        guard let lhs, let rhs else {
            // Feature print unavailable: only an identical hash is safe.
            return hashesIdentical
        }
        var distance: Float = 0
        do {
            try lhs.computeDistance(&distance, to: rhs)
        } catch {
            return false
        }
        return distance <= maxDistance
    }

    static func exactGroups(
        assets: [ScannedAsset],
        signatures: [String: ImageSignature],
        maxDistance: Int = 2,
        maxFeatureDistance: Float = 0.03
    ) -> [DuplicateGroup] {
        let entries = assets
            .filter { signatures[$0.id] != nil }
            .sorted { $0.id < $1.id }
        guard entries.count >= 2 else { return [] }

        // Duplicates always share pixel dimensions. Compare every pair inside a
        // dimension bucket, then require both a tight hash and a feature-print match.
        struct Dimensions: Hashable {
            let width: Int
            let height: Int
        }
        var buckets: [Dimensions: [Int]] = [:]
        for (index, asset) in entries.enumerated() {
            let key = Dimensions(width: asset.pixelWidth, height: asset.pixelHeight)
            buckets[key, default: []].append(index)
        }

        var union = UnionFind(count: entries.count)
        for indices in buckets.values where indices.count >= 2 {
            for position in 0..<indices.count {
                let index = indices[position]
                guard let hash = signatures[entries[index].id]?.dHash else { continue }
                for otherPosition in (position + 1)..<indices.count {
                    let otherIndex = indices[otherPosition]
                    guard let otherHash = signatures[entries[otherIndex].id]?.dHash else { continue }
                    guard hamming(hash, otherHash) <= maxDistance else { continue }
                    guard isSameFrame(
                        signatures[entries[index].id]?.featurePrint,
                        signatures[entries[otherIndex].id]?.featurePrint,
                        maxDistance: maxFeatureDistance,
                        hashesIdentical: hash == otherHash
                    ) else { continue }
                    union.union(index, otherIndex)
                }
            }
        }

        let groups: [DuplicateGroup] = union.groups().compactMap { indices in
            let groupAssets = indices.map { entries[$0] }
            guard groupAssets.count >= 2 else { return nil }
            let best = bestShot(in: groupAssets, signatures: signatures)
            return DuplicateGroup(
                id: groupAssets[0].id,
                kind: .exact,
                assets: groupAssets.sorted(by: sortByDate),
                bestID: best
            )
        }
        return groups.sorted { $0.redundantBytes > $1.redundantBytes }
    }

    static func similarGroups(
        assets: [ScannedAsset],
        signatures: [String: ImageSignature],
        threshold: Float,
        excluding excludedIDs: Set<String> = []
    ) -> [DuplicateGroup] {
        let candidates = assets.filter {
            !excludedIDs.contains($0.id) && signatures[$0.id] != nil
        }
        guard candidates.count >= 2 else { return [] }

        let calendar = Calendar.current
        var byDay: [Date: [ScannedAsset]] = [:]
        for asset in candidates {
            guard let date = asset.creationDate else { continue }
            let day = calendar.startOfDay(for: date)
            byDay[day, default: []].append(asset)
        }

        var result: [DuplicateGroup] = []
        for day in byDay.keys.sorted() {
            var dayAssets = byDay[day] ?? []
            guard dayAssets.count >= 2 else { continue }
            // Very large days get trimmed; comparing thousands of pairs costs more than it finds.
            if dayAssets.count > 400 {
                dayAssets = Array(dayAssets.sorted { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }.prefix(400))
            }

            var union = UnionFind(count: dayAssets.count)
            for i in 0..<dayAssets.count {
                guard let left = signatures[dayAssets[i].id] else { continue }
                for j in (i + 1)..<dayAssets.count {
                    guard let right = signatures[dayAssets[j].id] else { continue }
                    guard imagesLookAlike(
                        left,
                        right,
                        featureThreshold: threshold,
                        colorThreshold: Double(threshold) * 0.66
                    ) else { continue }
                    union.union(i, j)
                }
            }

            for indices in union.groups() {
                let groupAssets = indices.map { dayAssets[$0] }
                guard groupAssets.count >= 2 else { continue }
                let best = bestShot(in: groupAssets, signatures: signatures)
                result.append(DuplicateGroup(
                    id: groupAssets[0].id,
                    kind: .similar,
                    assets: groupAssets.sorted(by: sortByDate),
                    bestID: best
                ))
            }
        }
        return result.sorted { $0.redundantBytes > $1.redundantBytes }
    }

    static func bestShot(
        in assets: [ScannedAsset],
        signatures: [String: ImageSignature]
    ) -> String? {
        assets.max { lhs, rhs in
            score(lhs, signatures: signatures) < score(rhs, signatures: signatures)
        }?.id
    }

    static func score(_ asset: ScannedAsset, signatures: [String: ImageSignature]) -> Double {
        let sharpness = signatures[asset.id]?.sharpness ?? 0
        let megapixels = Double(asset.pixelCount) / 1_000_000
        let megabytes = Double(asset.sizeBytes) / 1_000_000
        let screenshotPenalty = asset.isScreenshot ? -1_000.0 : 0
        return screenshotPenalty + sharpness + megapixels * 2 + min(megabytes, 50) * 0.1
    }

    /// Vision feature prints are the best signal. Simulator builds (and rare failed
    /// requests) return nil, so fall back to the color mosaic.
    static func imagesLookAlike(
        _ lhs: ImageSignature,
        _ rhs: ImageSignature,
        featureThreshold: Float,
        colorThreshold: Double
    ) -> Bool {
        if let left = lhs.featurePrint, let right = rhs.featurePrint {
            var distance: Float = 0
            do {
                try left.computeDistance(&distance, to: right)
                return distance <= featureThreshold
            } catch {
                return colorDistance(lhs.colorGrid, rhs.colorGrid) <= colorThreshold
            }
        }
        return colorDistance(lhs.colorGrid, rhs.colorGrid) <= colorThreshold
    }

    /// Mean absolute RGB difference across an 8×8 mosaic, 0…1.
    static func colorDistance(_ lhs: [UInt8], _ rhs: [UInt8]) -> Double {
        guard lhs.count == rhs.count, !lhs.isEmpty else { return 1 }
        var total = 0.0
        var count = 0
        for index in 0..<lhs.count where index % 4 != 3 {
            total += abs(Double(lhs[index]) - Double(rhs[index]))
            count += 1
        }
        guard count > 0 else { return 1 }
        return total / (Double(count) * 255)
    }

    private static func sortByDate(_ lhs: ScannedAsset, _ rhs: ScannedAsset) -> Bool {
        (lhs.creationDate ?? .distantPast) > (rhs.creationDate ?? .distantPast)
    }
}
