import Foundation

enum StorageService {
    static func snapshot() -> StorageSnapshot? {
        let url = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        guard let values = try? url.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ]) else { return nil }

        guard let total = values.volumeTotalCapacity else { return nil }
        let free = values.volumeAvailableCapacityForImportantUsage
            ?? Int64(values.volumeAvailableCapacity ?? 0)
        guard total > 0 else { return nil }
        return StorageSnapshot(totalBytes: Int64(total), freeBytes: free)
    }
}
