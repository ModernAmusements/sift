import XCTest
@testable import Sift

@MainActor
final class SpaceLedgerStoreTests: XCTestCase {
    private let gb: Int64 = 1_000_000_000
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "sift.spaceledger.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private func snapshot(free: Int64, total: Int64 = 128_000_000_000) -> StorageSnapshot {
        StorageSnapshot(totalBytes: total, freeBytes: free)
    }

    func testLaunchSnapshotIsRecordedOnce() {
        let store = SpaceLedgerStore(defaults: defaults)
        let start = Date().addingTimeInterval(-86_400)

        XCTAssertNotNil(store.recordLaunch(snapshot(free: 2 * gb), at: start))
        XCTAssertEqual(store.entries.count, 1)

        // A second launch a minute later is noise, not history.
        XCTAssertNil(store.recordLaunch(snapshot(free: 2 * gb), at: start.addingTimeInterval(60)))
        XCTAssertEqual(store.entries.count, 1)

        // Eleven minutes later is a real observation.
        XCTAssertNotNil(store.recordLaunch(snapshot(free: 3 * gb), at: start.addingTimeInterval(11 * 60)))
        XCTAssertEqual(store.entries.count, 2)
    }

    func testUnusableSnapshotIsIgnored() {
        let store = SpaceLedgerStore(defaults: defaults)
        XCTAssertNil(store.recordLaunch(StorageSnapshot(totalBytes: 0, freeBytes: 0)))
        XCTAssertTrue(store.entries.isEmpty)
    }

    func testChangeSinceLastVisitNeedsTwoEntries() {
        let store = SpaceLedgerStore(defaults: defaults)
        let start = Date().addingTimeInterval(-86_400)
        store.recordLaunch(snapshot(free: 2 * gb), at: start)
        XCTAssertNil(store.changeSinceLastVisit(now: start))

        store.recordLaunch(snapshot(free: 5 * gb), at: start.addingTimeInterval(3600))
        let change = store.changeSinceLastVisit(now: start.addingTimeInterval(3600))
        XCTAssertEqual(change?.delta, 3 * gb)
    }

    func testVerifiedRequiresMeasuredGainAndCapsAtMoved() {
        let store = SpaceLedgerStore(defaults: defaults)
        let start = Date().addingTimeInterval(-86_400)
        store.recordLaunch(snapshot(free: 2 * gb), at: start)
        store.recordSession(moved: 2 * gb, snapshot: snapshot(free: 2 * gb), at: start.addingTimeInterval(120))

        // Nothing came back yet: no proof, no claim.
        XCTAssertNil(store.confirmVerified(snapshot: snapshot(free: 2 * gb), at: start.addingTimeInterval(180)))
        XCTAssertEqual(store.verifiedTotal, 0)
        XCTAssertEqual(store.pendingTotal, 2 * gb)

        // The system handed back 3 GB, but Sift only moved 2 GB and may only claim 2 GB.
        let verified = store.confirmVerified(snapshot: snapshot(free: 5 * gb), at: start.addingTimeInterval(240))
        XCTAssertEqual(verified, 2 * gb)
        XCTAssertEqual(store.verifiedTotal, 2 * gb)
        XCTAssertEqual(store.pendingTotal, 0)

        // Proof is not counted twice.
        XCTAssertNil(store.confirmVerified(snapshot: snapshot(free: 6 * gb), at: start.addingTimeInterval(300)))
        XCTAssertEqual(store.verifiedTotal, 2 * gb)
    }

    func testSubThresholdGainIsNotTreatedAsProof() {
        let store = SpaceLedgerStore(defaults: defaults)
        let start = Date().addingTimeInterval(-86_400)
        store.recordLaunch(snapshot(free: 2 * gb), at: start)
        store.recordSession(moved: 900_000_000, snapshot: snapshot(free: 2 * gb), at: start.addingTimeInterval(120))

        XCTAssertNil(store.confirmVerified(snapshot: snapshot(free: 2_050_000_000), at: start.addingTimeInterval(200)))
        XCTAssertEqual(store.verifiedTotal, 0)
    }

    func testHistoryIsCapped() {
        let store = SpaceLedgerStore(defaults: defaults)
        let start = Date().addingTimeInterval(-86_400)
        for index in 0..<40 {
            store.recordLaunch(snapshot(free: Int64(index + 1) * gb), at: start.addingTimeInterval(Double(index) * 3600))
        }
        XCTAssertEqual(store.entries.count, SpaceLedgerStore.limit)
        XCTAssertNotNil(store.entries.last)
    }

    func testSessionAtWindowStartStillGetsCreditForTheGain() {
        let store = SpaceLedgerStore(defaults: defaults)
        let start = Date().addingTimeInterval(-3 * 86_400)
        store.recordLaunch(snapshot(free: 2 * gb), at: start)
        store.recordSession(moved: 2 * gb, snapshot: snapshot(free: 2 * gb), at: start.addingTimeInterval(120))

        // Next visit, after emptying Recently Deleted: the window starts at the session itself.
        XCTAssertTrue(store.recordLaunch(snapshot(free: 5 * gb), at: start.addingTimeInterval(86_400)) != nil)
        let change = store.changeSinceLastVisit(now: start.addingTimeInterval(86_400))
        XCTAssertEqual(change?.delta, 3 * gb)

        let moved = store.movedSince(change!.since)
        XCTAssertEqual(moved, 2 * gb)
        XCTAssertEqual(
            SpaceLedger.detail(delta: change!.delta, movedBytes: moved),
            "2.0 GB of that was freed by Sift."
        )
    }

    func testVerifiedHistorySurvivesPruning() {
        let store = SpaceLedgerStore(defaults: defaults)
        let start = Date().addingTimeInterval(-90 * 86_400)

        var proven = SpaceCheckIn(date: start, totalBytes: 128 * gb, freeBytes: 2 * gb)
        proven.movedBytes = 3 * gb
        proven.verifiedFreedBytes = 3 * gb
        store.seedHistory([proven])

        // 35 quiet launches would evict a naive FIFO history.
        for index in 0..<35 {
            store.recordLaunch(
                snapshot(free: Int64(index + 2) * gb),
                at: start.addingTimeInterval(Double(index + 1) * 3600)
            )
        }

        XCTAssertEqual(store.entries.count, SpaceLedgerStore.limit)
        XCTAssertEqual(store.verifiedTotal, 3 * gb, "Reclaimed is cumulative; proof must not be pruned")
    }

    func testRestoreStartsAFreshBaseline() {
        let store = SpaceLedgerStore(defaults: defaults)
        let start = Date().addingTimeInterval(-86_400)
        store.recordLaunch(snapshot(free: 2 * gb), at: start)
        store.recordLaunch(snapshot(free: 90 * gb, total: 256_000_000_000), at: start.addingTimeInterval(3600))

        // A different capacity means the comparison is meaningless, so nothing is claimed.
        XCTAssertEqual(store.changeSinceLastVisit(now: start.addingTimeInterval(3600))?.delta, 0)
    }
}
