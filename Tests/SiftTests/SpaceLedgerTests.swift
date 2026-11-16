import XCTest
@testable import Sift

final class SpaceLedgerTests: XCTestCase {
    private let gb: Int64 = 1_000_000_000

    private func day(_ year: Int, _ month: Int, _ dayOfMonth: Int, hour: Int = 9) -> Date {
        DateComponents(
            calendar: .current,
            year: year, month: month, day: dayOfMonth, hour: hour
        ).date!
    }

    // MARK: Formatting

    func testFloorBytesNeverRoundsUp() {
        XCTAssertEqual(Format.floorBytes(3_240_000_000), "3.2 GB")
        XCTAssertEqual(Format.floorBytes(3_290_000_000), "3.2 GB")
        XCTAssertEqual(Format.floorBytes(14_900_000_000), "14 GB")
        XCTAssertEqual(Format.floorBytes(999_900_000), "999 MB")
        XCTAssertEqual(Format.floorBytes(500), "500 B")
        XCTAssertEqual(Format.floorBytes(0), "0 bytes")
    }

    func testFloorBytesStaysUnderTenGigabytesWithOneDecimal() {
        XCTAssertEqual(Format.floorBytes(9_990_000_000), "9.9 GB")
        XCTAssertEqual(Format.floorBytes(10_000_000_000), "10 GB")
    }

    // MARK: Delta rules

    func testDeltaIsDifferenceInFreeSpace() {
        let a = SpaceCheckIn(date: day(2026, 11, 11), totalBytes: 128 * gb, freeBytes: 2 * gb)
        let b = SpaceCheckIn(date: day(2026, 11, 16), totalBytes: 128 * gb, freeBytes: 5 * gb)
        XCTAssertEqual(SpaceLedger.delta(previous: a, current: b), 3 * gb)
    }

    func testDeltaIsZeroAfterRestore() {
        let old = SpaceCheckIn(date: day(2026, 11, 11), totalBytes: 128 * gb, freeBytes: 2 * gb)
        let fresh = SpaceCheckIn(date: day(2026, 11, 16), totalBytes: 256 * gb, freeBytes: 90 * gb)
        XCTAssertTrue(SpaceLedger.capacityChanged(old, fresh))
        XCTAssertEqual(SpaceLedger.delta(previous: old, current: fresh), 0)
    }

    func testSubThresholdMovementIsNotReported() {
        XCTAssertFalse(SpaceLedger.isReportable(99_999_999))
        XCTAssertTrue(SpaceLedger.isReportable(100_000_000))
        XCTAssertTrue(SpaceLedger.isReportable(-100_000_000))
    }

    func testSnapshotsCloserThanTenMinutesAreDropped() {
        let first = SpaceCheckIn(date: day(2026, 11, 16, hour: 9), totalBytes: 128 * gb, freeBytes: gb)
        let soon = SpaceCheckIn(date: day(2026, 11, 16, hour: 9).addingTimeInterval(5 * 60), totalBytes: 128 * gb, freeBytes: gb)
        let later = SpaceCheckIn(date: day(2026, 11, 16, hour: 9).addingTimeInterval(11 * 60), totalBytes: 128 * gb, freeBytes: gb)
        XCTAssertFalse(SpaceLedger.shouldRecord(soon, after: first))
        XCTAssertTrue(SpaceLedger.shouldRecord(later, after: first))
        XCTAssertTrue(SpaceLedger.shouldRecord(first, after: nil))
    }

    // MARK: Copy

    func testHeadlineCopyPositiveNegativeAndQuiet() {
        let since = day(2026, 11, 11)
        XCTAssertEqual(SpaceLedger.headline(delta: 3_200_000_000, since: since), "3.2 GB came back since Wed 11 Nov")
        XCTAssertEqual(SpaceLedger.headline(delta: -1_600_000_000, since: since), "1.6 GB less free space since Wed 11 Nov")
        XCTAssertEqual(SpaceLedger.headline(delta: 40_000_000, since: since), "About the same as last time")
    }

    func testAttributionOnlyCreditsWhatSiftMoved() {
        XCTAssertEqual(
            SpaceLedger.detail(delta: 3_200_000_000, movedBytes: 1_400_000_000),
            "1.4 GB of that was freed by Sift."
        )
        // A phone that gained space for other reasons is never credited to Sift.
        XCTAssertNil(SpaceLedger.detail(delta: 3_200_000_000, movedBytes: nil))
        // Nor is a loss.
        XCTAssertNil(SpaceLedger.detail(delta: -1_000_000_000, movedBytes: 900_000_000))
    }

    func testProofHeadlineRefusesToClaimUnverifiedSpace() {
        XCTAssertEqual(
            SpaceLedger.proofHeadline(moved: 2_100_000_000, verified: nil),
            "Moved 2.1 GB. Freed so far: 0 bytes."
        )
        XCTAssertEqual(
            SpaceLedger.proofHeadline(moved: 2_100_000_000, verified: 2_000_000_000),
            "Verified: 2.0 GB freed."
        )
        // Proof can never exceed what was moved.
        XCTAssertEqual(
            SpaceLedger.proofHeadline(moved: 2_100_000_000, verified: 9_000_000_000),
            "Verified: 2.1 GB freed."
        )
    }

    // MARK: Totals

    func testVerifiedTotalCountsProvenSpaceAndPendingExpires() {
        let now = day(2026, 11, 16)
        let entries = [
            // Proven 60 days ago: still reclaimed, provenance does not expire.
            SpaceCheckIn(date: now.addingTimeInterval(-60 * 24 * 3600), totalBytes: 128 * gb, freeBytes: gb, movedBytes: gb, verifiedFreedBytes: gb),
            SpaceCheckIn(date: now.addingTimeInterval(-2 * 3600), totalBytes: 128 * gb, freeBytes: gb, movedBytes: 2 * gb, verifiedFreedBytes: 2 * gb),
            SpaceCheckIn(date: now, totalBytes: 128 * gb, freeBytes: gb, movedBytes: 3 * gb, verifiedFreedBytes: nil),
            // Moved 50 days ago and never proved: no longer attributable, and never added to the total.
            SpaceCheckIn(date: now.addingTimeInterval(-50 * 24 * 3600), totalBytes: 128 * gb, freeBytes: gb, movedBytes: 4 * gb, verifiedFreedBytes: nil)
        ]
        XCTAssertEqual(SpaceLedger.verifiedFreed(in: entries), 3 * gb)
        XCTAssertEqual(SpaceLedger.pendingFreed(in: entries, now: now), 3 * gb)
    }

    // MARK: Health readings

    func testHeadroomLevels() {
        XCTAssertEqual(Headroom.level(freeBytes: 999_000_000), .critical)
        XCTAssertEqual(Headroom.level(freeBytes: 2 * gb), .tight)
        XCTAssertEqual(Headroom.level(freeBytes: 6 * gb), .comfortable)
    }

    func testHealthRowsOnlyClaimWhatIOSExposes() {
        let rows = HealthReading.rows(
            freeBytes: 800_000_000,
            totalBytes: 128 * gb,
            lowPowerMode: true,
            thermalState: .serious,
            libraryBytes: 41 * gb,
            libraryAssetCount: 12_400
        )
        XCTAssertEqual(rows.map(\.kind), [.headroom, .lowPowerMode, .thermal, .library, .battery])

        let headroom = rows[0]
        XCTAssertTrue(headroom.isNotable)
        XCTAssertTrue(headroom.value.contains("Critical"))
        XCTAssertEqual(
            headroom.note,
            "iOS needs working room. Below about 1 GB the camera can refuse to save and updates stall."
        )

        XCTAssertTrue(rows[1].isNotable)
        XCTAssertEqual(rows[2].value, "Hot")
        XCTAssertEqual(rows[2].note, "iOS is limiting performance while the phone is warm.")

        let battery = rows[4]
        XCTAssertEqual(battery.value, "In Settings")
        XCTAssertTrue(battery.note?.contains("no public API") == true)
    }

    func testHealthyPhoneHasNoNotableRowsExceptNone() {
        let rows = HealthReading.rows(
            freeBytes: 30 * gb,
            totalBytes: 128 * gb,
            lowPowerMode: false,
            thermalState: .nominal,
            libraryBytes: nil,
            libraryAssetCount: nil
        )
        XCTAssertFalse(rows.contains(where: \.isNotable))
        XCTAssertEqual(rows.count, 4)
    }
}
