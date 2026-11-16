import Foundation

/// Local history of real free-space measurements. UserDefaults only: no files, no network.
@MainActor
final class SpaceLedgerStore {
    static let storageKey = "spaceCheckIns"
    static let limit = 30

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var entries: [SpaceCheckIn] {
        guard let data = defaults.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([SpaceCheckIn].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.date < $1.date }
    }

    var latest: SpaceCheckIn? { entries.last }

    /// The delta against the previous visit, if there is one worth reporting.
    func changeSinceLastVisit(now: Date = Date()) -> (delta: Int64, since: Date)? {
        let list = entries
        guard list.count >= 2, let current = list.last else { return nil }
        let previous = list[list.count - 2]
        let delta = SpaceLedger.delta(previous: previous, current: current)
        guard SpaceLedger.isReportable(delta) else { return (0, previous.date) }
        return (delta, previous.date)
    }

    /// Called on launch. Silent when the snapshot is unusable or too close to the last one.
    @discardableResult
    func recordLaunch(_ snapshot: StorageSnapshot, at date: Date = Date()) -> SpaceCheckIn? {
        guard let candidate = SpaceCheckIn(snapshot: snapshot, date: date) else { return nil }
        guard SpaceLedger.shouldRecord(candidate, after: latest) else { return nil }
        append(candidate)
        return candidate
    }

    /// Called when a delete session finishes. Holds the moved bytes until a later measurement proves them.
    @discardableResult
    func recordSession(moved bytes: Int64, snapshot: StorageSnapshot, at date: Date = Date()) -> SpaceCheckIn? {
        guard let base = SpaceCheckIn(snapshot: snapshot, date: date) else { return nil }
        var entry = base
        entry.movedBytes = max(bytes, 0)
        append(entry)
        return entry
    }

    /// Called after the user comes back from Photos. Only a measured increase counts as freed.
    @discardableResult
    func confirmVerified(snapshot: StorageSnapshot, at date: Date = Date()) -> Int64? {
        var list = entries
        guard let index = list.lastIndex(where: { $0.movedBytes != nil && $0.verifiedFreedBytes == nil }) else {
            return nil
        }
        let pending = list[index]
        guard !SpaceLedger.capacityChanged(pending, SpaceCheckIn(snapshot: snapshot, date: date) ?? pending) else {
            return nil
        }
        let gained = snapshot.freeBytes - pending.freeBytes
        guard gained > 0, SpaceLedger.isReportable(gained) else { return nil }

        let verified = min(gained, pending.movedBytes ?? gained)
        guard verified > 0 else { return nil }

        list[index].verifiedFreedBytes = verified
        save(list)
        recordLaunch(snapshot, at: date)
        return verified
    }

    var verifiedTotal: Int64 {
        SpaceLedger.verifiedFreed(in: entries)
    }

    var pendingTotal: Int64 {
        SpaceLedger.pendingFreed(in: entries)
    }

    /// Bytes Sift moved in a check-in window. Inclusive, because the window starts at a
    /// session snapshot: the delete that caused the gain is dated exactly at `date`.
    func movedSince(_ date: Date) -> Int64 {
        entries
            .filter { $0.date >= date }
            .compactMap(\.movedBytes)
            .reduce(0, +)
    }

    /// The first check-in whose space was proven — the honest start of the cumulative figure.
    var verifiedSince: Date? {
        entries.first { ($0.verifiedFreedBytes ?? 0) > 0 }?.date
    }

    // MARK: Storage

    /// Forget the measured history. Only the app's own records are removed.
    func reset() {
        defaults.removeObject(forKey: Self.storageKey)
    }

    #if DEBUG
    /// UI-test seam: replace history with synthetic readings.
    func seedHistory(_ list: [SpaceCheckIn]) {
        save(list)
    }
    #endif

    private func append(_ entry: SpaceCheckIn) {
        var list = entries
        list.append(entry)
        // Prune the quiet history, never the proof: "Reclaimed" is cumulative.
        while list.count > Self.limit {
            if let oldestUnproven = list.firstIndex(where: { $0.verifiedFreedBytes == nil }) {
                list.remove(at: oldestUnproven)
            } else {
                list.removeFirst()
            }
        }
        save(list)
    }

    private func save(_ list: [SpaceCheckIn]) {
        guard let data = try? JSONEncoder().encode(list) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
