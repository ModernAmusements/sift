import Foundation

/// Caches PhotoKit `fileSize` lookups, which are expensive and stable.
/// Lives in the app's Caches directory, so iOS may purge it; that only costs a
/// slower next scan. Never leaves the device.
final class AssetSizeCache {
    static let shared = AssetSizeCache()

    private struct Entry: Codable {
        let modified: Double
        let bytes: Int64
    }

    private struct Store: Codable {
        var version: Int
        var savedAt: Date
        var entries: [String: Entry]
    }

    private let lock = NSLock()
    private var entries: [String: Entry] = [:]
    private var loaded = false
    private var dirty = false
    private var writesSinceFlush = 0

    private var url: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("sift-asset-sizes.json")
    }

    private init() {}

    func size(for id: String, modified: Date?) -> Int64? {
        lock.lock()
        loadIfNeededLocked()
        let entry = entries[id]
        lock.unlock()
        guard let entry else { return nil }
        // A different modification date means the asset changed; re-read it.
        guard entry.modified == (modified?.timeIntervalSince1970 ?? 0) else { return nil }
        return entry.bytes
    }

    func store(id: String, modified: Date?, bytes: Int64) {
        lock.lock()
        loadIfNeededLocked()
        entries[id] = Entry(
            modified: modified?.timeIntervalSince1970 ?? 0,
            bytes: bytes
        )
        dirty = true
        writesSinceFlush += 1
        let shouldFlush = writesSinceFlush >= 250
        lock.unlock()
        if shouldFlush { flush() }
    }

    /// Drops entries for assets that no longer exist.
    func prune(keeping ids: Set<String>) {
        lock.lock()
        loadIfNeededLocked()
        let stale = entries.keys.filter { !ids.contains($0) }
        if !stale.isEmpty {
            for key in stale { entries.removeValue(forKey: key) }
            dirty = true
        }
        lock.unlock()
    }

    func flush() {
        lock.lock()
        loadIfNeededLocked()
        guard dirty, let url else {
            lock.unlock()
            return
        }
        let store = Store(version: 1, savedAt: Date(), entries: entries)
        dirty = false
        writesSinceFlush = 0
        lock.unlock()

        do {
            let data = try JSONEncoder().encode(store)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
        } catch {
            // A failed cache write is harmless; the next scan re-reads sizes.
        }
    }

    private func loadIfNeededLocked() {
        guard !loaded else { return }
        loaded = true
        guard let url, let data = try? Data(contentsOf: url),
              let store = try? JSONDecoder().decode(Store.self, from: data),
              store.version == 1,
              // A month-old size map is likely wrong after iOS housekeeping.
              Date().timeIntervalSince(store.savedAt) < 30 * 86_400
        else { return }
        entries = store.entries
    }
}
