import Photos
import SwiftUI

enum ReviewCategory: String, Hashable {
    case screenshots
    case blurry
    case largeFiles

    var title: String {
        switch self {
        case .screenshots: return "Screenshots"
        case .blurry: return "Blurry photos"
        case .largeFiles: return "Large files"
        }
    }

    var subtitle: String {
        switch self {
        case .screenshots: return "Old tickets, chats and receipts."
        case .blurry: return "Soft shots that rarely get a second look."
        case .largeFiles: return "Photos and videos over 25 MB."
        }
    }
}

enum Route: Hashable {
    case review(ReviewCategory)
    case similar(DuplicateKind)
    case contacts
    case files
    case systemData
    case swipe
}

struct HomeView: View {
    @EnvironmentObject private var engine: ScanEngine
    @Environment(\.scenePhase) private var scenePhase

    @State private var path: [Route] = []
    @State private var storage: StorageSnapshot?
    @State private var showSettings = false
    @State private var scanTask: Task<Void, Never>?
    @State private var photoStatus = PhotoLibraryService.status

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 26) {
                        header
                        if photoStatus == .denied || photoStatus == .restricted {
                            photosOffCard
                        } else if photoStatus == .limited {
                            limitedCard
                        }
                        storageCard
                        scanSection
                        if let report = engine.report {
                            resultsSection(report)
                        }
                        toolsSection
                        footer
                    }
                    .padding(.horizontal, Theme.margin)
                    .padding(.top, 10)
                    .padding(.bottom, 44)
                }

                if engine.isScanning {
                    ScanProgressView(
                        stage: engine.stage,
                        progress: engine.progress,
                        processed: engine.processedCount,
                        total: engine.analysisTotal,
                        onCancel: cancelScan
                    )
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .review(let category):
                    ReviewView(category: category)
                case .similar(let kind):
                    SimilarView(mode: kind)
                case .contacts:
                    ContactsView()
                case .files:
                    FilesView()
                case .systemData:
                    SystemDataView()
                case .swipe:
                    SwipeView()
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear(perform: refresh)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { refreshAccess() }
            }
            .onChange(of: engine.stage) { _, stage in
                if stage == .finished { storage = StorageService.snapshot() }
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { engine.errorMessage != nil },
                    set: { if !$0 { engine.dismissError() } }
                )
            ) {
                Button("OK") { engine.dismissError() }
            } message: {
                Text(engine.errorMessage ?? "")
            }
            .animation(.snappy(duration: 0.3), value: engine.isScanning)
            .animation(.snappy(duration: 0.3), value: engine.report?.scannedAt)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            ScreenTitle(
                title: "Sift",
                subtitle: "Keep the moments. Lose the clutter."
            )
            Button {
                Haptics.selection()
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Theme.card))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    private var photosOffCard: some View {
        PermissionState(
            symbol: "photo.on.rectangle.angled",
            title: "Your library is out of reach",
            message: "Sift needs access to your photos to find duplicates and screenshots. Nothing leaves this iPhone.",
            primaryTitle: "Open Settings",
            primaryAction: openSettings
        )
    }

    private var limitedCard: some View {
        PermissionState(
            symbol: "photo.badge.plus",
            title: "Only some photos are shared",
            message: "Sift can only tidy what it can see. Select your full library, or choose the albums you want to clean.",
            primaryTitle: "Select more photos",
            secondaryTitle: "Open Settings",
            primaryAction: {
                PhotoLibraryService.presentLimitedPicker()
            },
            secondaryAction: openSettings
        )
    }

    private var storageCard: some View {
        Card {
            HStack(alignment: .center, spacing: 22) {
                StorageRing(
                    fraction: storage?.usedFraction ?? 0,
                    usedText: storage.map { Format.bytes($0.usedBytes) } ?? "—",
                    freeText: storage.map { Format.bytes($0.freeBytes) } ?? "—"
                )

                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("iPhone storage")
                            .font(.headline)
                            .foregroundStyle(Theme.ink)
                        Text(storage.map { "\(Format.bytes($0.freeBytes)) free" } ?? "Storage unavailable")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryInk)
                    }

                    StatPill(
                        value: engine.report.map { Format.bytes($0.totalLibraryBytes) } ?? "—",
                        label: "Photos & videos"
                    )
                    StatPill(
                        value: engine.report.map { Format.count($0.totalAssetCount, "item") } ?? "Not scanned",
                        label: "Library"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var scanSection: some View {
        VStack(spacing: 10) {
            Button {
                startScan()
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "magnifyingglass")
                        .font(.body.weight(.semibold))
                    Text(engine.report == nil ? "Scan my iPhone" : "Scan again")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(engine.isScanning)

            Text("On-device. No uploads. No account.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryInk)
        }
    }

    private func resultsSection(_ report: ScanReport) -> some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Found",
                detail: Format.bytes(report.potentialBytes)
            )

            Card(padding: 0) {
                VStack(spacing: 0) {
                    row(
                        route: .review(.screenshots),
                        symbol: "camera.viewfinder",
                        title: "Screenshots",
                        detail: Format.count(report.screenshots.count, "screenshot"),
                        value: Format.bytes(report.screenshots.reduce(0) { $0 + $1.sizeBytes })
                    )
                    rowDivider
                    row(
                        route: .similar(.exact),
                        symbol: "photo.on.rectangle.angled",
                        title: "Duplicates",
                        detail: Format.count(report.duplicateGroups.count, "group"),
                        value: Format.bytes(report.duplicateGroups.reduce(0) { $0 + $1.redundantBytes })
                    )
                    rowDivider
                    row(
                        route: .similar(.similar),
                        symbol: "square.stack.3d.up",
                        title: "Similar photos",
                        detail: Format.count(report.similarGroups.count, "group"),
                        value: Format.bytes(report.similarGroups.reduce(0) { $0 + $1.redundantBytes })
                    )
                    rowDivider
                    row(
                        route: .review(.blurry),
                        symbol: "camera.filters",
                        title: "Blurry photos",
                        detail: Format.count(report.blurry.count, "photo"),
                        value: Format.bytes(report.blurry.reduce(0) { $0 + $1.sizeBytes })
                    )
                    rowDivider
                    row(
                        route: .review(.largeFiles),
                        symbol: "tray.full",
                        title: "Large files",
                        detail: Format.count(report.largeFiles.count, "item") + " over 25 MB",
                        value: Format.bytes(report.largeFiles.reduce(0) { $0 + $1.sizeBytes })
                    )
                }
            }

            Text("Suggestions only. You choose what moves to Recently Deleted.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        }
    }

    private var toolsSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Go through it")
            Card(padding: 0) {
                VStack(spacing: 0) {
                    row(
                        route: .swipe,
                        symbol: "hand.draw",
                        title: "Swipe review",
                        detail: "Keep or delete, one at a time",
                        value: nil
                    )
                    rowDivider
                    row(
                        route: .files,
                        symbol: "folder",
                        title: "Files & documents",
                        detail: "Pick big files from On My iPhone or iCloud Drive",
                        value: nil
                    )
                    rowDivider
                    row(
                        route: .contacts,
                        symbol: "person.2",
                        title: "Duplicate contacts",
                        detail: engine.contactsLoaded
                            ? Format.count(engine.contactGroups.count, "group")
                            : "Find and merge repeated cards",
                        value: nil
                    )
                    rowDivider
                    row(
                        route: .systemData,
                        symbol: "internaldrive",
                        title: "System data",
                        detail: "What iOS lets you do — and what it doesn't",
                        value: nil
                    )
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Label("Everything stays on this iPhone.", systemImage: "lock.shield")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Theme.secondaryInk)
            Text("Sift is free and open source.")
                .font(.caption)
                .foregroundStyle(Theme.tertiaryInk)
            if let url = URL(string: "https://github.com/ModernAmusements/sift") {
                Link("View source", destination: url)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Theme.separator)
            .frame(height: 0.5)
            .padding(.leading, 72)
    }

    private func row(
        route: Route,
        symbol: String,
        title: String,
        detail: String,
        value: String?
    ) -> some View {
        NavigationLink(value: route) {
            CategoryRow(symbol: symbol, title: title, detail: detail, value: value)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private func startScan() {
        guard !engine.isScanning else { return }
        Haptics.selection()
        scanTask = Task {
            await engine.scan()
            storage = StorageService.snapshot()
            refreshAccess()
        }
    }

    private func cancelScan() {
        scanTask?.cancel()
        Haptics.warning()
    }

    private func refresh() {
        refreshAccess()
        storage = StorageService.snapshot()
    }

    private func refreshAccess() {
        photoStatus = PhotoLibraryService.status
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

struct ScanProgressView: View {
    let stage: ScanEngine.Stage
    let progress: Double
    let processed: Int
    let total: Int
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .stroke(Theme.fill, lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: max(0.01, min(progress, 1)))
                        .stroke(
                            Theme.ink,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.35), value: progress)
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 30, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Theme.ink)
                }
                .frame(width: 132, height: 132)

                VStack(spacing: 6) {
                    Text(stage.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.opacity)
                    Text(stage.detail)
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryInk)
                        .multilineTextAlignment(.center)
                }

                if total > 0 && stage == .analyzing {
                    Text("\(processed) of \(total)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.tertiaryInk)
                }

                Button("Cancel", action: onCancel)
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: 180)
            }
            .padding(28)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner + 2, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: .black.opacity(0.12), radius: 30, y: 12)
            )
            .padding(.horizontal, 32)
        }
        .accessibilityAddTraits(.isModal)
    }
}
