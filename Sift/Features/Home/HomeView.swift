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
    case health
}

struct HomeView: View {
    @EnvironmentObject private var engine: ScanEngine
    @Environment(\.scenePhase) private var scenePhase

    @State private var path: [Route] = []
    @State private var storage: StorageSnapshot?
    @State private var showSettings = false
    @State private var scanTask: Task<Void, Never>?
    @State private var photoStatus = PhotoLibraryService.status
    @State private var checkIn: (delta: Int64, since: Date)?

    private let ledger = SpaceLedgerStore()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 26) {
                        Text("Keep the moments. Lose the clutter.")
                            .font(Typo.subheadline)
                            .foregroundStyle(Theme.secondaryInk)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)

                if engine.isScanning {
                    ScanProgressView(
                        stage: engine.stage,
                        live: engine.live,
                        onCancel: cancelScan
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(2)
                }
            }
            .navigationTitle("Sift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("SiftLockup")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 18)
                        .foregroundStyle(Theme.ink)
                        .accessibilityLabel("Sift")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.selection()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
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
                case .health:
                    HealthView(
                        storage: storage,
                        report: engine.report,
                        onScan: startScan
                    )
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(item: proofBinding) { proof in
                ProofView(movedBytes: proof.movedBytes, store: ledger)
            }
            .onAppear(perform: refresh)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    refreshAccess()
                    measureStorage()
                }
            }
            .onChange(of: engine.stage) { _, stage in
                if stage == .finished { measureStorage() }
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
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 22) {
                    storageRing
                    storageDetails
                        .frame(minWidth: 140)
                }

                VStack(alignment: .leading, spacing: 18) {
                    storageRing
                        .frame(maxWidth: .infinity, alignment: .center)
                    storageDetails
                }
            }
            .accessibilityElement(children: .contain)
        }
    }

    private var storageRing: some View {
        StorageRing(
            fraction: storage?.usedFraction ?? 0,
            usedText: storage.map { Format.bytes($0.usedBytes) } ?? "—",
            freeText: storage.map { Format.bytes($0.freeBytes) } ?? "—"
        )
    }

    private var storageDetails: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(checkInHeadline)
                    .font(Typo.headline)
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: checkInHeadline)
                if let detail = checkInDetail {
                    Text(detail)
                        .font(Typo.footnote)
                        .foregroundStyle(Theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                        .animation(.snappy, value: detail)
                }
                if let storage {
                    Text("\(Format.bytes(storage.freeBytes)) free of \(Format.bytes(storage.totalBytes))")
                        .font(Typo.caption).monospacedDigit()
                        .foregroundStyle(Theme.tertiaryInk)
                }
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

    private var scanSection: some View {
        VStack(spacing: 10) {
            Button {
                startScan()
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "magnifyingglass")
                        .font(Typo.bodySemibold)
                    Text(engine.report == nil ? "Scan my iPhone" : "Scan again")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(engine.isScanning)

            Text("On-device. No uploads. No account.")
                .font(Typo.caption)
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
                .font(Typo.caption)
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
                        route: .health,
                        symbol: "waveform.path.ecg",
                        title: "Phone health",
                        detail: "Free space, heat and battery — what iOS really reports",
                        value: nil
                    )
                    rowDivider
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
            Image("SiftLockup")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(height: 20)
                .foregroundStyle(Theme.secondaryInk)
                .accessibilityLabel("Sift")
            Label("Everything stays on this iPhone.", systemImage: "lock.shield")
                .font(Typo.footnoteMedium)
                .foregroundStyle(Theme.secondaryInk)
            Text("FREE · OPEN SOURCE · MADE IN BIELEFELD")
                .font(Typo.label)
                .tracking(0.8)
                .foregroundStyle(Theme.tertiaryInk)
                .multilineTextAlignment(.center)
            if let url = URL(string: "https://github.com/ModernAmusements/sift") {
                Link("View source", destination: url)
                    .font(Typo.captionMedium)
                    .foregroundStyle(Theme.secondaryInk)
            }
            MAByline()
                .padding(.top, 14)
            if let url = URL(string: "https://modern-amusement.dev") {
                Link("modern-amusement.dev", destination: url)
                    .font(Typo.label)
                    .tracking(0.5)
                    .foregroundStyle(Theme.accent)
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
            measureStorage()
            refreshAccess()
        }
    }

    private func cancelScan() {
        scanTask?.cancel()
        Haptics.warning()
    }

    private var proofBinding: Binding<ScanEngine.ProofSession?> {
        Binding(
            get: { engine.proof },
            set: { if $0 == nil { engine.dismissProof() } }
        )
    }

    private var checkInHeadline: String {
        if let checkIn {
            return SpaceLedger.headline(delta: checkIn.delta, since: checkIn.since)
        }
        return storage.map { "\(Format.bytes($0.freeBytes)) free" } ?? "Storage unavailable"
    }

    private var checkInDetail: String? {
        guard let checkIn else {
            return storage == nil ? nil : "Baseline saved. Sift shows the real change next time."
        }
        if checkIn.delta > 0 {
            let moved = ledger.movedSince(checkIn.since)
            return SpaceLedger.detail(delta: checkIn.delta, movedBytes: moved)
                ?? "iOS returned space. Sift moved nothing this time."
        }
        if checkIn.delta < 0 {
            return "New photos, downloads or app updates."
        }
        return nil
    }

    private func refresh() {
        refreshAccess()
        measureStorage()
    }

    private func measureStorage() {
        guard let snapshot = StorageService.snapshot() else {
            storage = nil
            return
        }
        storage = snapshot
        #if DEBUG
        DemoSeed.prepareLedgerIfRequested(ledger, snapshot: snapshot)
        #endif
        ledger.recordLaunch(snapshot)
        checkIn = ledger.changeSinceLastVisit()
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
    @ObservedObject var live: ScanLiveState
    let onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    /// Access checks and the library fetch can take a moment; a fake 0% is not a measurement.
    private var isPreparing: Bool {
        stage == .preparing || stage == .library || live.progress < 0.01
    }
    private var percent: Int { min(100, max(0, Int((live.progress * 100).rounded()))) }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .stroke(Theme.fill, lineWidth: 10)

                    if isPreparing {
                        ProgressView()
                            .controlSize(.large)
                            .tint(Theme.accent)
                    } else {
                        Circle()
                            .trim(from: 0, to: max(0.01, min(live.progress, 1)))
                            .stroke(
                                Theme.accent,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 0.45), value: live.progress)

                        Text("\(percent)%")
                            .font(Typo.size(30, weight: .semibold)).monospacedDigit()
                            .foregroundStyle(Theme.ink)
                            .contentTransition(.numericText(value: Double(percent)))
                            .animation(.snappy, value: percent)
                    }
                }
                .frame(width: 132, height: 132)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(isPreparing ? "Preparing" : "\(percent) percent")

                VStack(spacing: 6) {
                    Text(stage.title)
                        .font(Typo.title3Semibold)
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.opacity)
                        .animation(.snappy, value: stage)
                    Text(stage.detail)
                        .font(Typo.footnote)
                        .foregroundStyle(Theme.secondaryInk)
                        .multilineTextAlignment(.center)
                        .contentTransition(.opacity)
                        .animation(.snappy, value: stage)
                }

                if live.analysisTotal > 0 && stage == .analyzing {
                    Text("\(live.processed) of \(live.analysisTotal)")
                        .font(Typo.caption).monospacedDigit()
                        .foregroundStyle(Theme.tertiaryInk)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: live.processed)
                } else if stage == .library && live.libraryTotal > 0 {
                    Text("\(live.libraryProcessed) of \(live.libraryTotal) items")
                        .font(Typo.caption).monospacedDigit()
                        .foregroundStyle(Theme.tertiaryInk)
                }

                Button("Cancel", action: onCancel)
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: 180)
            }
            .padding(28)
            .frame(maxWidth: 340)
            .background {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: Theme.corner + 2, style: .continuous)
                        .fill(.clear)
                        .glassEffect(
                            .regular,
                            in: .rect(cornerRadius: Theme.corner + 2, style: .continuous)
                        )
                } else {
                    RoundedRectangle(cornerRadius: Theme.corner + 2, style: .continuous)
                        .fill(Theme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.corner + 2, style: .continuous)
                                .stroke(Theme.separator, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 32)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.97)
        }
        .accessibilityAddTraits(.isModal)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.snappy(duration: 0.28)) { appeared = true }
            }
        }
    }
}
