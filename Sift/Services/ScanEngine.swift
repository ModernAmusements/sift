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
    @Published private(set) var report: ScanReport?
    @Published private(set) var isScanning = false
    @Published private(set) var contactGroups: [ContactGroup] = []
    @Published private(set) var contactsLoaded = false
    @Published private(set) var contactsDenied = false
    @Published var errorMessage: String?
    /// Set after a delete session so the proof screen can show what was moved and what came back.
    @Published private(set) var proof: ProofSession?

    struct ProofSession: Identifiable, Equatable {
        let id = UUID()
        let movedBytes: Int64
    }

    private let ledger = SpaceLedgerStore()

    /// High-frequency progress is deliberately not @Published on the engine:
    /// Home owns this object but does not observe it, so a scan never redraws
    /// the whole home screen on every batch.
    let live = ScanLiveState()

    func dismissProof() {
        proof = nil
    }

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
        live.reset()
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

        // Fetching assets and reading every file size is the slow part of a scan.
        // It runs off the main thread and reports its own progress.
        stage = .library
        let loaded = await PhotoLibraryService.loadLibrary { [weak self] done, total in
            guard let self else { return }
            await self.live.updateLibrary(processed: done, total: total)
        }
        guard !Task.isCancelled else { return }

        let assets = loaded.assets
        let scanned = loaded.scanned
        ThumbnailCache.shared.register(assets)
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
        live.updateAnalysis(processed: 0, total: analyzable.count, progress: 0.15)
        let largeFiles = scanned
            .filter {
                $0.sizeBytes >= 25_000_000 || ($0.isVideo && $0.duration >= 60)
            }
            .sorted { $0.sizeBytes > $1.sizeBytes }

        stage = .analyzing
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
                        return (
                            asset.localIdentifier,
                            autoreleasepool { ImageAnalyzer.signature(for: image) }
                        )
                    }
                }
                for await (id, signature) in group {
                    if let signature { signatures[id] = signature }
                    processed += 1
                }
            }
            let fraction = analyzable.isEmpty ? 1 : Double(processed) / Double(analyzable.count)
            live.updateAnalysis(
                processed: processed,
                total: analyzable.count,
                progress: 0.15 + fraction * 0.6
            )
        }
        guard !Task.isCancelled else { return }

        stage = .grouping
        live.updateAnalysis(
            processed: analyzable.count,
            total: analyzable.count,
            progress: 0.8
        )
        let threshold = similarityThreshold
        let blurCutoff = blurThreshold
        // Pairwise grouping is pure work and can take a moment on a 10,000-asset
        // library. Keep it off the main thread so the cancel button still responds.
        let grouped = await Task.detached(priority: .userInitiated) {
            () -> (duplicates: [DuplicateGroup], similar: [DuplicateGroup], blurry: [ScannedAsset]) in
            let duplicates = SimilarityEngine.exactGroups(assets: scanned, signatures: signatures)
            let exactIDs = Set(duplicates.flatMap { $0.assets.map(\.id) })
            let similar = SimilarityEngine.similarGroups(
                assets: scanned,
                signatures: signatures,
                threshold: threshold,
                excluding: exactIDs
            )
            let blurry = scanned
                .filter { asset in
                    guard !asset.isVideo, !asset.isScreenshot,
                          let signature = signatures[asset.id] else { return false }
                    return signature.sharpness < blurCutoff
                }
                .sorted { (signatures[$0.id]?.sharpness ?? 0) < (signatures[$1.id]?.sharpness ?? 0) }
                .prefix(120)
                .map { $0 }
            return (duplicates, similar, blurry)
        }.value

        guard !Task.isCancelled else { return }
        let duplicates = grouped.duplicates
        let similar = grouped.similar
        let blurry = grouped.blurry
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
            live.updateAnalysis(
                processed: analyzable.count,
                total: analyzable.count,
                progress: 0.9
            )
            let groups = await ContactService.loadGroups()
            if !Task.isCancelled {
                contactGroups = groups
                contactsLoaded = true
            }
        }

        guard !Task.isCancelled else { return }
        live.complete()
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
        let movedBytes = report?.bytes(for: ids) ?? 0
        do {
            try await PhotoLibraryService.delete(ids: ids)
            if let report {
                self.report = report.removing(ids: Set(ids))
            }
            if movedBytes > 0, let snapshot = StorageService.snapshot() {
                ledger.recordSession(moved: movedBytes, snapshot: snapshot)
                proof = ProofSession(movedBytes: movedBytes)
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
        live.reset()
        stage = .preparing
        UserDefaults.standard.removeObject(forKey: "lastScanDate")
    }

    func dismissError() {
        errorMessage = nil
    }
}
