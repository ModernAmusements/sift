import Contacts
import CoreGraphics
import Foundation
import Photos

@MainActor
final class ScanEngine: ObservableObject {
    enum Stage: Int {
        case preparing
        case library
        case analyzing
        case grouping
        case contacts
        case finished

        var title: String {
            switch self {
            case .preparing: return "Preparing"
            case .library: return "Reading your library"
            case .analyzing: return "Looking at every photo"
            case .grouping: return "Finding the keepers"
            case .contacts: return "Checking contacts"
            case .finished: return "Done"
            }
        }

        var detail: String {
            switch self {
            case .preparing: return "Checking access and storage"
            case .library: return "Reading dates and sizes"
            case .analyzing: return "On-device. Nothing is uploaded."
            case .grouping: return "Grouping duplicates and similar shots"
            case .contacts: return "Only contacts you already allowed"
            case .finished: return "Your library is ready to review"
            }
        }
    }

    @Published private(set) var stage: Stage = .preparing
    @Published private(set) var progress: Double = 0
    @Published private(set) var report: ScanReport?
    @Published private(set) var isScanning = false
    @Published private(set) var processedCount = 0
    @Published private(set) var totalCount = 0
    @Published private(set) var analysisTotal = 0
    @Published private(set) var contactGroups: [ContactGroup] = []
    @Published private(set) var contactsLoaded = false
    @Published private(set) var contactsDenied = false
    @Published var errorMessage: String?

    var lastScanDate: Date? {
        UserDefaults.standard.object(forKey: "lastScanDate") as? Date
    }

    private var similarityThreshold: Float {
        let stored = UserDefaults.standard.double(forKey: "similarityThreshold")
        return stored > 0 ? Float(stored) : 0.15
    }

    private var blurThreshold: Double {
        let stored = UserDefaults.standard.double(forKey: "blurThreshold")
        return stored > 0 ? stored : 28
    }

    func scan() async {
        guard !isScanning else { return }
        isScanning = true
        errorMessage = nil
        progress = 0
        processedCount = 0
        stage = .preparing
        defer { isScanning = false }

        var authorization = PhotoLibraryService.status
        if authorization == .notDetermined {
            authorization = await PhotoLibraryService.requestAuthorization()
        }
        guard authorization == .authorized || authorization == .limited else {
            errorMessage = "Photos access is off. Enable it in Settings to let Sift find media."
            stage = .finished
            return
        }
        guard !Task.isCancelled else { return }

        let assets = PhotoLibraryService.fetchAll()
        ThumbnailCache.shared.register(assets)
        let scanned = assets.map(PhotoLibraryService.scannedAsset(from:))
        totalCount = scanned.count
        stage = .library
        progress = 0.08
        guard !Task.isCancelled else { return }

        let screenshots = scanned
            .filter(\.isScreenshot)
            .sorted { $0.sizeBytes > $1.sizeBytes }
        let videos = scanned
            .filter(\.isVideo)
            .sorted { $0.sizeBytes > $1.sizeBytes }
        let totalBytes = scanned.reduce(Int64(0)) { $0 + $1.sizeBytes }

        let analyzable = assets.filter {
            $0.mediaType == .image && !PhotoLibraryService.isScreenshot($0)
        }
        analysisTotal = analyzable.count
        let largeFiles = scanned
            .filter {
                $0.sizeBytes >= 25_000_000 || ($0.isVideo && $0.duration >= 60)
            }
            .sorted { $0.sizeBytes > $1.sizeBytes }

        stage = .analyzing
        progress = 0.15
        var signatures: [String: ImageSignature] = [:]
        signatures.reserveCapacity(analyzable.count)

        let batchSize = 4
        var processed = 0
        for start in stride(from: 0, to: analyzable.count, by: batchSize) {
            if Task.isCancelled { return }
            let batch = Array(analyzable[start..<min(start + batchSize, analyzable.count)])
            await withTaskGroup(of: (String, ImageSignature?).self) { group in
                for asset in batch {
                    group.addTask {
                        if Task.isCancelled { return (asset.localIdentifier, nil) }
                        guard let image = await PhotoLibraryService.thumbnail(
                            for: asset,
                            size: CGSize(width: 320, height: 320)
                        ) else { return (asset.localIdentifier, nil) }
                        return (asset.localIdentifier, ImageAnalyzer.signature(for: image))
                    }
                }
                for await (id, signature) in group {
                    if let signature { signatures[id] = signature }
                    processed += 1
                }
            }
            processedCount = processed
            let fraction = analyzable.isEmpty ? 1 : Double(processed) / Double(analyzable.count)
            progress = 0.15 + fraction * 0.6
        }
        guard !Task.isCancelled else { return }

        stage = .grouping
        progress = 0.8
        let duplicates = SimilarityEngine.exactGroups(assets: scanned, signatures: signatures)
        let exactIDs = Set(duplicates.flatMap { $0.assets.map(\.id) })
        let similar = SimilarityEngine.similarGroups(
            assets: scanned,
            signatures: signatures,
            threshold: similarityThreshold,
            excluding: exactIDs
        )
        let blurry = scanned
            .filter { asset in
                guard !asset.isVideo, !asset.isScreenshot,
                      let signature = signatures[asset.id] else { return false }
                return signature.sharpness < blurThreshold
            }
            .sorted { (signatures[$0.id]?.sharpness ?? 0) < (signatures[$1.id]?.sharpness ?? 0) }
            .prefix(120)
            .map { $0 }

        guard !Task.isCancelled else { return }
        let newReport = ScanReport(
            scannedAt: Date(),
            totalAssetCount: scanned.count,
            totalLibraryBytes: totalBytes,
            screenshots: screenshots,
            videos: videos,
            largeFiles: largeFiles,
            blurry: Array(blurry),
            duplicateGroups: duplicates,
            similarGroups: similar
        )
        report = newReport
        UserDefaults.standard.set(Date(), forKey: "lastScanDate")

        if ContactService.status == .authorized {
            stage = .contacts
            progress = 0.9
            let groups = await ContactService.loadGroups()
            if !Task.isCancelled {
                contactGroups = groups
                contactsLoaded = true
            }
        }

        guard !Task.isCancelled else { return }
        progress = 1
        stage = .finished
        Haptics.success()
    }

    func loadContacts(requestAccess: Bool) async {
        if ContactService.status == .notDetermined {
            guard requestAccess else { return }
            let granted = await ContactService.requestAccess()
            guard granted else {
                contactsDenied = true
                return
            }
        }
        let status = ContactService.status
        guard status == .authorized else {
            contactsDenied = true
            return
        }
        contactsDenied = false
        let groups = await ContactService.loadGroups()
        contactGroups = groups
        contactsLoaded = true
    }

    @discardableResult
    func merge(_ group: ContactGroup) async -> Bool {
        do {
            try await ContactService.merge(group: group)
            contactGroups.removeAll { $0.id == group.id }
            Haptics.success()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func mergeAllContacts() async -> Int {
        var merged = 0
        for group in contactGroups {
            do {
                merged += try await ContactService.merge(group: group)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        contactGroups = await ContactService.loadGroups()
        contactsLoaded = true
        if merged > 0 { Haptics.success() }
        return merged
    }

    /// Returns true when the user finished the system deletion sheet, false when they cancelled.
    @discardableResult
    func delete(ids: [String]) async -> Bool {
        guard !ids.isEmpty else { return false }
        do {
            try await PhotoLibraryService.delete(ids: ids)
            if let report {
                self.report = report.removing(ids: Set(ids))
            }
            Haptics.success()
            return true
        } catch {
            let nsError = error as NSError
            if nsError.code == 3072 { return false } // PHPhotosError.userCancelled
            errorMessage = error.localizedDescription
            return false
        }
    }

    func clearResults() {
        report = nil
        contactGroups = []
        contactsLoaded = false
        contactsDenied = false
        progress = 0
        stage = .preparing
        UserDefaults.standard.removeObject(forKey: "lastScanDate")
    }

    func dismissError() {
        errorMessage = nil
    }
}
