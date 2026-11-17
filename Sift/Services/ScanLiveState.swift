import SwiftUI

/// High-frequency scan state lives here so the home screen does not redraw
/// on every analysed batch. Only the scan overlay observes this object.
@MainActor
final class ScanLiveState: ObservableObject {
    @Published private(set) var progress: Double = 0
    @Published private(set) var processed: Int = 0
    @Published private(set) var analysisTotal: Int = 0
    @Published private(set) var libraryProcessed: Int = 0
    @Published private(set) var libraryTotal: Int = 0

    private var lastProgressFlush = Date.distantPast

    func reset() {
        progress = 0
        processed = 0
        analysisTotal = 0
        libraryProcessed = 0
        libraryTotal = 0
        lastProgressFlush = .distantPast
    }

    func updateLibrary(processed: Int, total: Int) {
        libraryProcessed = processed
        libraryTotal = total
    }

    /// Coalesces progress to roughly 20 updates per second.
    func updateAnalysis(processed: Int, total: Int, progress target: Double) {
        let now = Date()
        if now.timeIntervalSince(lastProgressFlush) > 0.05 || target >= 1 {
            lastProgressFlush = now
            self.processed = processed
            analysisTotal = total
            progress = target
        }
    }

    func complete() {
        progress = 1
    }
}
