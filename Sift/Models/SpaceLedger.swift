import Foundation

/// One measured point in time: what the volume looked like when the app was opened.
struct SpaceCheckIn: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let totalBytes: Int64
    let freeBytes: Int64
    /// Set when a Sift delete session finished; compared against a later measurement.
    var movedBytes: Int64?
    /// Set once a later measurement proved the space came back.
    var verifiedFreedBytes: Int64?

    init(
        id: UUID = UUID(),
        date: Date,
        totalBytes: Int64,
        freeBytes: Int64,
        movedBytes: Int64? = nil,
        verifiedFreedBytes: Int64? = nil
    ) {
        self.id = id
        self.date = date
        self.totalBytes = totalBytes
        self.freeBytes = freeBytes
        self.movedBytes = movedBytes
        self.verifiedFreedBytes = verifiedFreedBytes
    }

    init?(snapshot: StorageSnapshot, date: Date = Date()) {
        guard snapshot.totalBytes > 0 else { return nil }
        self.init(date: date, totalBytes: snapshot.totalBytes, freeBytes: snapshot.freeBytes)
    }
}

/// Pure rules for honest space accounting. No UI, no I/O, no network.
enum SpaceLedger {
    /// Below this, movement is noise and must not be reported as a change.
    static let reportThreshold: Int64 = 100_000_000
    /// How long a delete session stays attributable to a later measurement.
    static let attributionWindow: TimeInterval = 45 * 24 * 60 * 60
    /// Snapshots closer together than this are dropped instead of stored.
    static let minimumSnapshotInterval: TimeInterval = 10 * 60
    /// A free-space jump this large relative to total capacity means a different device or a restore.
    static let capacityTolerance: Double = 0.05

    static func capacityChanged(_ lhs: SpaceCheckIn, _ rhs: SpaceCheckIn) -> Bool {
        guard lhs.totalBytes > 0, rhs.totalBytes > 0 else { return false }
        let ratio = Double(rhs.totalBytes) / Double(lhs.totalBytes)
        return abs(ratio - 1) > capacityTolerance
    }

    /// Free-space change in bytes. Zero when a baseline reset makes the comparison meaningless.
    static func delta(previous: SpaceCheckIn, current: SpaceCheckIn) -> Int64 {
        guard !capacityChanged(previous, current) else { return 0 }
        return current.freeBytes - previous.freeBytes
    }

    /// Only real movement is worth a sentence.
    static func isReportable(_ delta: Int64) -> Bool {
        abs(delta) >= reportThreshold
    }

    /// A pointless duplicate snapshot is noise in the history, so drop it.
    static func shouldRecord(_ candidate: SpaceCheckIn, after last: SpaceCheckIn?) -> Bool {
        guard let last else { return true }
        if capacityChanged(last, candidate) { return true }
        return candidate.date.timeIntervalSince(last.date) >= minimumSnapshotInterval
    }

    /// Bytes Sift moved but the system has not proved yet, while attribution is still open.
    static func pendingFreed(in entries: [SpaceCheckIn], now: Date = Date()) -> Int64 {
        entries
            .filter {
                $0.movedBytes != nil
                    && $0.verifiedFreedBytes == nil
                    && attributionExpiry(for: $0) > now
            }
            .reduce(0) { $0 + ($1.movedBytes ?? 0) }
    }

    /// The only number that may be called "reclaimed": sums that a later measurement proved.
    /// Proven space stays proven; the 45-day window only limits attribution of the unproven.
    static func verifiedFreed(in entries: [SpaceCheckIn]) -> Int64 {
        entries.reduce(0) { $0 + ($1.verifiedFreedBytes ?? 0) }
    }

    /// After this moment a moved-but-unproven session is no longer attributed.
    static func attributionExpiry(for entry: SpaceCheckIn) -> Date {
        entry.date.addingTimeInterval(attributionWindow)
    }

    /// The most recent entry that is still waiting for proof.
    static func pendingSession(in entries: [SpaceCheckIn]) -> SpaceCheckIn? {
        entries.last { $0.movedBytes != nil && $0.verifiedFreedBytes == nil }
    }

    // MARK: Copy

    static func headline(delta: Int64, since date: Date) -> String {
        let since = Format.shortDay(date)
        guard isReportable(delta) else { return "About the same as last time" }
        if delta > 0 {
            return "\(Format.floorBytes(delta)) came back since \(since)"
        }
        return "\(Format.floorBytes(-delta)) less free space since \(since)"
    }

    /// Attribution is only allowed when Sift itself moved the bytes.
    static func detail(delta: Int64, movedBytes: Int64?) -> String? {
        guard delta > 0, let movedBytes, movedBytes > 0 else { return nil }
        let credited = min(delta, movedBytes)
        guard isReportable(credited) else { return nil }
        return "\(Format.floorBytes(credited)) of that was freed by Sift."
    }

    /// Never claims a freed number before the system has handed the space back.
    static func proofHeadline(moved: Int64, verified: Int64?) -> String {
        guard let verified, verified > 0, isReportable(verified) else {
            return "Moved \(Format.floorBytes(moved)). Freed so far: 0 bytes."
        }
        return "Verified: \(Format.floorBytes(min(verified, moved))) freed."
    }
}
