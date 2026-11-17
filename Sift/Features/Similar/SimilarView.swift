import SwiftUI

struct SimilarView: View {
    let mode: DuplicateKind

    @EnvironmentObject private var engine: ScanEngine
    @Environment(\.dismiss) private var dismiss

    @State private var selected: Set<String> = []
    @State private var didPreselect = false
    @State private var isDeleting = false
    @State private var appeared = false

    private var groups: [DuplicateGroup] {
        guard let report = engine.report else { return [] }
        return mode == .exact ? report.duplicateGroups : report.similarGroups
    }

    private var selectedBytes: Int64 {
        let all = groups.flatMap(\.assets)
        return all.filter { selected.contains($0.id) }.reduce(0) { $0 + $1.sizeBytes }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if groups.isEmpty {
                EmptyState(
                    symbol: "square.stack.3d.up",
                    title: mode == .exact ? "No exact duplicates" : "No similar photos",
                    message: mode == .exact
                        ? "Sift compares a fingerprint of every photo on-device."
                        : "Nothing looked like a second take. That is a good thing."
                )
                .padding(.horizontal, Theme.margin)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(mode == .exact
                             ? "The same frame saved more than once. Sift keeps the sharpest copy."
                             : "Shots from the same day that look alike. Keep the best, review the rest.")
                            .font(Typo.subheadline)
                            .foregroundStyle(Theme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, Theme.margin)

                        HStack {
                            Text("\(Format.count(groups.count, "group")) · \(Format.bytes(groups.reduce(0) { $0 + $1.redundantBytes })) suggested")
                                .font(Typo.footnote).monospacedDigit()
                                .foregroundStyle(Theme.secondaryInk)
                            Spacer()
                            Menu {
                                Button("Select all suggestions") { preselect(force: true) }
                                Button("Deselect all") { selected.removeAll() }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundStyle(Theme.ink)
                                    .frame(width: 36, height: 36)
                            }
                            .accessibilityLabel("Selection options")
                        }
                        .padding(.horizontal, Theme.margin)

                        ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                            groupCard(group)
                                .riseIn(appeared, index: index + 1)
                        }
                        .padding(.horizontal, Theme.margin)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle(mode == .exact ? "Duplicates" : "Similar photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if !groups.isEmpty {
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
        .onAppear {
            appeared = true
            if !didPreselect {
                didPreselect = true
                preselect(force: false)
            }
        }
        .animation(.snappy(duration: 0.3), value: groups.count)
        .onChange(of: groups.map(\.id)) { _, _ in
            let valid = Set(groups.flatMap { $0.assets.map(\.id) })
            selected = selected.intersection(valid)
        }
    }

    private func groupCard(_ group: DuplicateGroup) -> some View {
        Card(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(Format.count(group.assets.count, "photo"))
                            .font(Typo.headline)
                            .foregroundStyle(Theme.ink)
                        Text("\(Format.bytes(group.totalBytes)) · keep the best")
                            .font(Typo.footnote)
                            .foregroundStyle(Theme.secondaryInk)
                    }
                    Spacer()
                    Text(mode == .exact ? "Duplicate" : "Similar")
                        .font(Typo.captionSemibold)
                        .foregroundStyle(Theme.secondaryInk)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Theme.fill))
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(group.assets) { asset in
                            Button {
                                toggle(asset.id)
                                Haptics.selection()
                            } label: {
                                ZStack(alignment: .topLeading) {
                                    MediaThumbnail(
                                        asset: asset,
                                        isSelected: selected.contains(asset.id),
                                        targetSize: 300
                                    )
                                    .frame(width: 112, height: 112)

                                    if asset.id == group.bestID {
                                        Text("Best")
                                            .font(Typo.caption2Semibold)
                                            .foregroundStyle(Theme.background)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(Theme.ink))
                                            .padding(7)
                                    }
                                }
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func toggle(_ id: String) {
        if selected.contains(id) {
            selected.remove(id)
        } else {
            selected.insert(id)
        }
    }

    private func preselect(force: Bool) {
        if force { selected.removeAll() }
        for group in groups {
            for asset in group.assets where asset.id != group.bestID {
                selected.insert(asset.id)
            }
        }
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
                if groups.isEmpty { dismiss() }
            }
        }
    }
}
