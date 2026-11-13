import XCTest
import UIKit
@testable import Sift

final class SiftTests: XCTestCase {
    func testPhoneNormalizationMatchesFormats() {
        XCTAssertEqual(ContactNormalizer.phoneKey("+49 (151) 2345-6789"), "23456789")
        XCTAssertEqual(ContactNormalizer.phoneKey("0151 2345 6789"), "23456789")
        XCTAssertEqual(ContactNormalizer.phoneKey("2345 6789"), "23456789")
        XCTAssertNil(ContactNormalizer.phoneKey("110"))
        XCTAssertNil(ContactNormalizer.phoneKey(""))
    }

    func testEmailNormalization() {
        XCTAssertEqual(ContactNormalizer.emailKey("  Jane@Example.COM "), "jane@example.com")
        XCTAssertNil(ContactNormalizer.emailKey("not-an-email"))
    }

    func testDisplayNameFallsBackToOrganization() {
        XCTAssertEqual(
            ContactNormalizer.displayName(given: "Jane", family: "Doe", organization: ""),
            "Jane Doe"
        )
        XCTAssertEqual(
            ContactNormalizer.displayName(given: "", family: "", organization: "Studio"),
            "Studio"
        )
        XCTAssertEqual(
            ContactNormalizer.displayName(given: "", family: "", organization: ""),
            "No name"
        )
    }

    func testHammingDistance() {
        XCTAssertEqual(SimilarityEngine.hamming(0b1010, 0b1010), 0)
        XCTAssertEqual(SimilarityEngine.hamming(0b1010, 0b1000), 1)
        XCTAssertEqual(SimilarityEngine.hamming(0, .max), 64)
    }

    func testDHashIsStableForSameImage() {
        let image = makeImage(background: .systemBlue)
        guard let cgImage = image.cgImage else { return XCTFail("no cgImage") }
        XCTAssertEqual(ImageAnalyzer.dHash(cgImage), ImageAnalyzer.dHash(cgImage))
    }

    func testSignatureProvidesFallbackWhenFeaturePrintIsUnavailable() {
        let image = makeImage(background: .systemBlue)
        guard let signature = ImageAnalyzer.signature(for: image) else {
            return XCTFail("no signature")
        }
        XCTAssertFalse(signature.colorGrid.isEmpty)
    }

    func testColorMosaicSeparatesScenes() {
        guard let blue = makeImage(background: .systemBlue).cgImage,
              let blueVariant = makeImage(background: .systemTeal).cgImage,
              let red = makeImage(background: .systemRed).cgImage else {
            return XCTFail("no cgImage")
        }
        let a = ImageAnalyzer.colorGrid(blue)
        let b = ImageAnalyzer.colorGrid(blueVariant)
        let c = ImageAnalyzer.colorGrid(red)
        XCTAssertEqual(ImageAnalyzer.colorGrid(blue), a)
        XCTAssertLessThan(SimilarityEngine.colorDistance(a, b), SimilarityEngine.colorDistance(a, c))
    }

    func testColorMosaicDistanceBounds() {
        XCTAssertEqual(SimilarityEngine.colorDistance([], []), 1)
        let white = [UInt8](repeating: 255, count: 32)
        let black = [UInt8](repeating: 0, count: 32)
        XCTAssertEqual(SimilarityEngine.colorDistance(white, white), 0)
        XCTAssertEqual(SimilarityEngine.colorDistance(white, black), 1, accuracy: 0.001)
    }


    func testDHashDiffersForDifferentImages() {
        let left = makeSplitImage(blackOnLeft: true)
        let right = makeSplitImage(blackOnLeft: false)
        guard let leftImage = left.cgImage, let rightImage = right.cgImage else {
            return XCTFail("no cgImage")
        }
        XCTAssertNotEqual(ImageAnalyzer.dHash(leftImage), ImageAnalyzer.dHash(rightImage))
    }

    func testSharpnessIsHigherForDetailedImage() {
        guard let sharp = makeImage(background: .white, square: CGRect(x: 20, y: 20, width: 60, height: 60)).cgImage,
              let flat = makeImage(background: .gray, square: .zero).cgImage else {
            return XCTFail("no cgImage")
        }
        XCTAssertGreaterThan(
            ImageAnalyzer.sharpness(sharp),
            ImageAnalyzer.sharpness(flat)
        )
    }

    func testUnionFindGroups() {
        var union = UnionFind(count: 4)
        union.union(0, 1)
        union.union(1, 2)
        let groups = union.groups()
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].sorted(), [0, 1, 2])
    }

    func testSimilarFallbackGroupsSameDayVariants() {
        let noon = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 12))!
        let other = Calendar.current.date(byAdding: .hour, value: 2, to: noon)!
        let differentDay = Calendar.current.date(byAdding: .day, value: 2, to: noon)!
        let assets = [
            ScannedAsset(id: "a", creationDate: noon, mediaType: .image, isScreenshot: false, pixelWidth: 4000, pixelHeight: 3000, duration: 0, sizeBytes: 2_000_000, isFavorite: false),
            ScannedAsset(id: "b", creationDate: other, mediaType: .image, isScreenshot: false, pixelWidth: 4000, pixelHeight: 3000, duration: 0, sizeBytes: 2_000_000, isFavorite: false),
            ScannedAsset(id: "c", creationDate: noon, mediaType: .image, isScreenshot: false, pixelWidth: 4000, pixelHeight: 3000, duration: 0, sizeBytes: 2_000_000, isFavorite: false),
            ScannedAsset(id: "d", creationDate: differentDay, mediaType: .image, isScreenshot: false, pixelWidth: 4000, pixelHeight: 3000, duration: 0, sizeBytes: 2_000_000, isFavorite: false)
        ]
        let same = [UInt8](repeating: 120, count: 32)
        let different = [UInt8](repeating: 10, count: 32)
        let signatures = [
            "a": ImageSignature(dHash: 1, sharpness: 50, featurePrint: nil, colorGrid: same),
            "b": ImageSignature(dHash: 2, sharpness: 55, featurePrint: nil, colorGrid: same),
            "c": ImageSignature(dHash: 3, sharpness: 60, featurePrint: nil, colorGrid: different),
            "d": ImageSignature(dHash: 4, sharpness: 60, featurePrint: nil, colorGrid: same)
        ]
        let groups = SimilarityEngine.similarGroups(
            assets: assets,
            signatures: signatures,
            threshold: 0.15
        )
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(Set(groups[0].assets.map(\.id)), ["a", "b"])
    }

    func testExactGroupingRequiresMatchingDimensions() {
        let assets = [
            ScannedAsset(id: "a", creationDate: Date(), mediaType: .image, isScreenshot: false, pixelWidth: 4000, pixelHeight: 3000, duration: 0, sizeBytes: 2_000_000, isFavorite: false),
            ScannedAsset(id: "b", creationDate: Date(), mediaType: .image, isScreenshot: false, pixelWidth: 3000, pixelHeight: 2000, duration: 0, sizeBytes: 2_000_000, isFavorite: false)
        ]
        let signatures = [
            "a": signature(hash: 0xFFFF_FFFF_FFFF_FFFF, sharpness: 30),
            "b": signature(hash: 0xFFFF_FFFF_FFFF_FFFF, sharpness: 30)
        ]
        XCTAssertTrue(SimilarityEngine.exactGroups(assets: assets, signatures: signatures).isEmpty)
    }

    func testExactDuplicateGrouping() {
        let assets = [
            asset(id: "a", date: Date()),
            asset(id: "b", date: Date()),
            asset(id: "c", date: Date())
        ]
        let signatures = [
            "a": signature(hash: 0xFFFF_FFFF_FFFF_FFFF, sharpness: 30),
            "b": signature(hash: 0xFFFF_FFFF_FFFF_FFFF, sharpness: 90),
            "c": signature(hash: 0x0000_0000_0000_0000, sharpness: 40)
        ]
        let groups = SimilarityEngine.exactGroups(assets: assets, signatures: signatures)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(Set(groups[0].assets.map(\.id)), ["a", "b"])
        XCTAssertEqual(groups[0].bestID, "b")
    }

    func testBestShotPrefersSharpness() {
        let assets = [
            asset(id: "soft", pixels: 8000, size: 9_000_000),
            asset(id: "sharp", pixels: 4000, size: 2_000_000)
        ]
        let signatures = [
            "soft": signature(hash: 1, sharpness: 12),
            "sharp": signature(hash: 2, sharpness: 240)
        ]
        XCTAssertEqual(SimilarityEngine.bestShot(in: assets, signatures: signatures), "sharp")
    }

    func testReportRemovalPrunesGroupsAndBytes() {
        let screenshot = asset(id: "s1", isScreenshot: true, size: 5_000_000)
        let screenshot2 = asset(id: "s2", isScreenshot: true, size: 3_000_000)
        let a = asset(id: "a", size: 2_000_000)
        let b = asset(id: "b", size: 2_000_000)
        let group = DuplicateGroup(id: "a", kind: .exact, assets: [a, b], bestID: "a")
        let report = ScanReport(
            scannedAt: Date(),
            totalAssetCount: 4,
            totalLibraryBytes: 12_000_000,
            screenshots: [screenshot, screenshot2],
            videos: [],
            largeFiles: [],
            blurry: [],
            duplicateGroups: [group],
            similarGroups: []
        )
        let pruned = report.removing(ids: ["s1", "b"])
        XCTAssertEqual(pruned.screenshots.map(\.id), ["s2"])
        XCTAssertTrue(pruned.duplicateGroups.isEmpty)
        XCTAssertEqual(pruned.totalAssetCount, 2)
        XCTAssertEqual(pruned.totalLibraryBytes, 5_000_000)
    }

    func testFormatting() {
        XCTAssertEqual(Format.bytes(0), "—")
        XCTAssertEqual(Format.bytes(4_200_000), "4.2 MB")
        XCTAssertEqual(Format.bytes(128_000_000_000), "128 GB")
        XCTAssertEqual(Format.duration(65), "1:05")
        XCTAssertEqual(Format.count(1, "photo"), "1 photo")
        XCTAssertEqual(Format.count(3, "photo"), "3 photos")
    }

    @MainActor
    func testPickedFileDeletion() throws {
        let manager = FileManager.default
        let directory = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? manager.removeItem(at: directory) }

        let first = directory.appendingPathComponent("first.bin")
        let second = directory.appendingPathComponent("second.bin")
        try Data(count: 2_048).write(to: first)
        try Data(count: 4_096).write(to: second)

        let model = FilePickerModel()
        model.add([first, second])
        XCTAssertEqual(model.files.count, 2)
        XCTAssertEqual(model.files.first(where: { $0.name == "first.bin" })?.bytes, 2_048)

        model.selected = [first.standardizedFileURL.path]
        model.deleteSelected()

        XCTAssertFalse(manager.fileExists(atPath: first.path))
        XCTAssertTrue(manager.fileExists(atPath: second.path))
        XCTAssertEqual(model.files.count, 1)
    }

    // MARK: - Helpers

    private func makeImage(background: UIColor, square: CGRect = CGRect(x: 10, y: 10, width: 30, height: 30)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        return renderer.image { context in
            background.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
            if square != .zero {
                UIColor.black.setFill()
                context.fill(square)
            }
        }
    }

    private func makeSplitImage(blackOnLeft: Bool) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
            UIColor.black.setFill()
            context.fill(
                CGRect(x: blackOnLeft ? 0 : 50, y: 0, width: 50, height: 100)
            )
        }
    }

    private func asset(
        id: String,
        date: Date = Date(),
        isScreenshot: Bool = false,
        pixels: Int = 4000,
        size: Int64 = 1_000_000
    ) -> ScannedAsset {
        ScannedAsset(
            id: id,
            creationDate: date,
            mediaType: .image,
            isScreenshot: isScreenshot,
            pixelWidth: pixels,
            pixelHeight: pixels,
            duration: 0,
            sizeBytes: size,
            isFavorite: false
        )
    }

    private func signature(hash: UInt64, sharpness: Double) -> ImageSignature {
        ImageSignature(dHash: hash, sharpness: sharpness, featurePrint: nil, colorGrid: [])
    }
}
