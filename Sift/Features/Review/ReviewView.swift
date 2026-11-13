import SwiftUI

struct ReviewView: View {
    let category: ReviewCategory

    @EnvironmentObject private var engine: ScanEngine
    @Environment(\.dismiss) private var dismiss

    @State private var selected: Set<String> = []
    @State private var isDeleting = false

    private var assets: [ScannedAsset] {
        guard let report = engine.report else { return [] }
        switch category {
        case .screenshots: return report.screenshots
        case .blurry: return report.blurry
        case .largeFiles: return report.largeFiles
        }
    }

    private var selectedBytes: Int64 {
        assets.filter { selected.contains($0.id) }.reduce(0) { $0 + $1.sizeBytes }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if assets.isEmpty {
                EmptyState(
                    symbol: category == .largeFiles ? "tray.full" : "checkmark.circle",
                    title: "Nothing here",
                    message: category == .screenshots
                        ? "No screenshots in the photos Sift can see."
                        : category == .blurry
                        ? "No soft shots worth another look."
                        : "No photos or videos over 25 MB."
                )
                .padding(.horizontal, Theme.margin)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(category.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryInk)
                            .padding(.horizontal, Theme.margin)

                        summary
                            .padding(.horizontal, Theme.margin)

                        LazyVGrid(columns: columns, spacing: 6) {
                            ForEach(assets) { asset in
                                Button {
                                    toggle(asset.id)
                                } label: {
                                    MediaThumbnail(
                                        asset: asset,
                                        isSelected: selected.contains(asset.id)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.margin)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Select all") { selectAll() }
                    Button("Deselect all") { selected.removeAll() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Theme.ink)
                }
                .accessibilityLabel("Selection options")
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !assets.isEmpty {
                SelectionBar(
                    count: selected.count,
                    bytes: selectedBytes,
                    actionTitle: "Move to Recently Deleted",
                    action: deleteSelected,
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
        .onChange(of: assets.map(\.id)) { _, ids in
            selected = selected.intersection(Set(ids))
        }
    }

    private var summary: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(Format.count(assets.count, "item"))
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(Format.bytes(assets.reduce(0) { $0 + $1.sizeBytes }) + " in total")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryInk)
            }
            Spacer()
            Button(selected.isEmpty ? "Select all" : "Deselect all") {
                if selected.isEmpty {
                    selectAll()
                } else {
                    selected.removeAll()
                }
                Haptics.selection()
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(Capsule().fill(Theme.card))
        }
    }

    private func toggle(_ id: String) {
        if selected.contains(id) {
            selected.remove(id)
        } else {
            selected.insert(id)
        }
        Haptics.selection()
    }

    private func selectAll() {
        selected = Set(assets.map(\.id))
        Haptics.selection()
    }

    private func deleteSelected() {
        guard !selected.isEmpty, !isDeleting else { return }
        isDeleting = true
        let ids = Array(selected)
        Task {
            let succeeded = await engine.delete(ids: ids)
            isDeleting = false
            if succeeded {
                selected.removeAll()
                if assets.isEmpty { dismiss() }
            }
        }
    }
}
