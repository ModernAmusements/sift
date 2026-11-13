import SwiftUI

private struct SwipeAction {
    let id: String
    let deleted: Bool
}

struct SwipeView: View {
    @EnvironmentObject private var engine: ScanEngine
    @Environment(\.dismiss) private var dismiss

    @State private var assets: [ScannedAsset] = []
    @State private var index = 0
    @State private var toDelete: [String] = []
    @State private var kept = 0
    @State private var undoStack: [SwipeAction] = []
    @State private var drag: CGSize = .zero
    @State private var isDeleting = false
    @State private var didLoad = false

    private var current: ScannedAsset? {
        guard index >= 0, index < assets.count else { return nil }
        return assets[index]
    }

    private var next: ScannedAsset? {
        guard index + 1 < assets.count else { return nil }
        return assets[index + 1]
    }

    private var queuedBytes: Int64 {
        let ids = Set(toDelete)
        return assets.filter { ids.contains($0.id) }.reduce(0) { $0 + $1.sizeBytes }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if assets.isEmpty {
                EmptyState(
                    symbol: "hand.draw",
                    title: "Nothing to swipe",
                    message: "Run a scan first, or there are no screenshots, blurry photos or duplicates to review."
                )
                .padding(.horizontal, Theme.margin)
            } else if index >= assets.count {
                finishedState
            } else {
                GeometryReader { geometry in
                    let horizontal: CGFloat = 40
                    let cardWidth = max(geometry.size.width - horizontal, 240)
                    let cardHeight = max(
                        320,
                        min(cardWidth * 4.0 / 3.0, geometry.size.height - 190)
                    )

                    VStack(spacing: 16) {
                        header
                        deck(width: cardWidth, height: cardHeight)
                        controls
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, Theme.margin)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                }
            }
        }
        .navigationTitle("Swipe review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if !toDelete.isEmpty && index < assets.count {
                SelectionBar(
                    count: toDelete.count,
                    bytes: queuedBytes,
                    actionTitle: "Move to Recently Deleted",
                    action: commit,
                    isBusy: isDeleting,
                    note: "Recoverable from Recently Deleted for 30 days."
                )
            }
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
        .onAppear(perform: loadQueue)
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(min(index + 1, assets.count)) of \(assets.count)")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Theme.secondaryInk)
                Spacer()
                if !undoStack.isEmpty {
                    Button {
                        undo()
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Theme.ink)
                    }
                    .buttonStyle(.plain)
                }
            }
            ProgressView(value: Double(index), total: Double(max(assets.count, 1)))
                .tint(Theme.ink)
        }
    }

    private func deck(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            if let next {
                SwipeCard(asset: next)
                    .frame(width: width, height: height)
                    .scaleEffect(0.96)
                    .offset(y: 14)
                    .opacity(0.55)
                    .allowsHitTesting(false)
            }

            if let current {
                SwipeCard(
                    asset: current,
                    drag: drag,
                    showsDelete: thresholdReached(delete: true),
                    showsKeep: thresholdReached(delete: false)
                )
                .frame(width: width, height: height)
                .offset(x: drag.width, y: drag.height * 0.08)
                .rotationEffect(.degrees(Double(drag.width / 22)))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            drag = value.translation
                        }
                        .onEnded { value in
                            if value.translation.width < -120 {
                                decide(delete: true)
                            } else if value.translation.width > 120 {
                                decide(delete: false)
                            } else {
                                withAnimation(.snappy(duration: 0.3)) { drag = .zero }
                            }
                        }
                )
                .animation(.snappy(duration: 0.28), value: index)
            }
        }
        .frame(width: width, height: height)
    }

    private var controls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 28) {
                controlButton(symbol: "xmark", label: "Delete", filled: false) {
                    decide(delete: true)
                }
                controlButton(symbol: "checkmark", label: "Keep", filled: true) {
                    decide(delete: false)
                }
            }
            Text("Swipe left to delete · right to keep")
                .font(.caption)
                .foregroundStyle(Theme.tertiaryInk)
        }
        .padding(.bottom, 4)
    }

    private func controlButton(
        symbol: String,
        label: String,
        filled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(filled ? Theme.background : Theme.ink)
                .frame(width: 64, height: 64)
                .background(
                    Circle().fill(filled ? Theme.ink : Theme.card)
                )
                .overlay(
                    Circle().stroke(filled ? Color.clear : Theme.separator, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var finishedState: some View {
        VStack(spacing: 20) {
            EmptyState(
                symbol: "checkmark.circle",
                title: "That is everything",
                message: kept == 0 && toDelete.isEmpty
                    ? "You went through \(assets.count) items."
                    : "You kept \(kept) and queued \(toDelete.count) for removal."
            )

            if !toDelete.isEmpty {
                Button {
                    commit()
                } label: {
                    HStack(spacing: 8) {
                        if isDeleting { ProgressView().tint(Theme.background) }
                        Text("Move \(Format.count(toDelete.count, "item")) to Recently Deleted")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isDeleting)
                .padding(.horizontal, Theme.margin)
            }

            Button("Done") { dismiss() }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, Theme.margin)
        }
        .padding(.vertical, 20)
    }

    private func thresholdReached(delete: Bool) -> Bool {
        delete ? drag.width < -60 : drag.width > 60
    }

    private func loadQueue() {
        guard !didLoad else { return }
        didLoad = true
        guard let report = engine.report else { return }
        var seen = Set<String>()
        var items: [ScannedAsset] = []
        for asset in report.screenshots + report.blurry + report.duplicateExtras + report.similarExtras {
            if seen.insert(asset.id).inserted { items.append(asset) }
        }
        assets = Array(items.sorted {
            ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast)
        }.prefix(300))
    }

    private func decide(delete: Bool) {
        guard let current else { return }
        if delete {
            toDelete.append(current.id)
        } else {
            kept += 1
        }
        undoStack.append(SwipeAction(id: current.id, deleted: delete))
        Haptics.selection()
        withAnimation(.snappy(duration: 0.28)) {
            drag = .zero
            index += 1
        }
    }

    private func undo() {
        guard let last = undoStack.popLast() else { return }
        if last.deleted {
            toDelete.removeAll { $0 == last.id }
        } else {
            kept = max(kept - 1, 0)
        }
        withAnimation(.snappy(duration: 0.28)) {
            index = max(index - 1, 0)
            drag = .zero
        }
        Haptics.selection()
    }

    private func commit() {
        guard !toDelete.isEmpty, !isDeleting else { return }
        isDeleting = true
        let ids = toDelete
        Task {
            let succeeded = await engine.delete(ids: ids)
            isDeleting = false
            if succeeded {
                toDelete.removeAll()
                Haptics.success()
                dismiss()
            }
        }
    }
}

private struct SwipeCard: View {
    let asset: ScannedAsset
    var drag: CGSize = .zero
    var showsDelete = false
    var showsKeep = false

    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Theme.card)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .transition(.opacity)
                } else {
                    ProgressView().tint(Theme.secondaryInk)
                }

                VStack {
                    HStack {
                        if showsDelete {
                            Label("Delete", systemImage: "xmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.background)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Theme.ink))
                                .transition(.scale.combined(with: .opacity))
                        }
                        Spacer()
                        if showsKeep {
                            Label("Keep", systemImage: "checkmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.background)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Theme.reclaim))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(16)
                    Spacer()
                }

                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text(asset.isScreenshot ? "Screenshot" : asset.isVideo ? "Video" : "Photo")
                            .font(.subheadline.weight(.semibold))
                        Text("\(Format.date(asset.creationDate)) · \(asset.sizeText)")
                            .font(.caption.monospacedDigit())
                            .opacity(0.85)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.55)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .task(id: asset.id) {
            image = await ThumbnailCache.shared.image(
                id: asset.id,
                size: CGSize(width: 900, height: 1200)
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(asset.isScreenshot ? "Screenshot" : "Photo"), \(Format.date(asset.creationDate)), \(asset.sizeText)")
        .accessibilityHint("Swipe left to delete, right to keep, or use the buttons below.")
    }
}
