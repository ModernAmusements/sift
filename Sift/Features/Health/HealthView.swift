import SwiftUI

/// Diagnosis only. Every row is something iOS actually reports.
struct HealthView: View {
    let storage: StorageSnapshot?
    let report: ScanReport?
    let onScan: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var rows: [HealthRow] = []

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    Text("Sift can only see what iOS exposes. There is no speed, RAM or battery boost on this screen — those are not possible for any app.")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Card(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                                if index > 0 { divider }
                                rowView(row)
                            }
                        }
                    }

                    if let storage, Headroom.level(freeBytes: storage.freeBytes) != .comfortable {
                        Text("Freeing space is the one thing here that genuinely helps: iOS needs working room, and a full phone is slower.")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if report == nil {
                        Text("Scanning shows how much of your library is screenshots and repeat shots — usually the easiest space to get back.")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(spacing: 10) {
                        Button {
                            dismiss()
                            onScan()
                        } label: {
                            HStack(spacing: 9) {
                                Image(systemName: "magnifyingglass")
                                    .font(.body.weight(.semibold))
                                Text("Find what is safe to remove")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Text("Nothing is deleted without your confirmation.")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, Theme.margin)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Phone health")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.separator)
            .frame(height: 0.5)
            .padding(.leading, 68)
    }

    private func rowView(_ row: HealthRow) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol(for: row.kind))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(row.isNotable ? Theme.reclaim : Theme.ink)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Theme.fill))

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Theme.ink)
                            Text(row.value)
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(row.isNotable ? Theme.ink : Theme.secondaryInk)
                        }
                    } else {
                        HStack(alignment: .firstTextBaseline) {
                            Text(row.title)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Theme.ink)
                            Spacer(minLength: 8)
                            Text(row.value)
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(row.isNotable ? Theme.ink : Theme.secondaryInk)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                if let note = row.note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.opacity)
        .accessibilityElement(children: .combine)
    }

    private func symbol(for kind: HealthRow.Kind) -> String {
        switch kind {
        case .headroom: return "internaldrive"
        case .lowPowerMode: return "battery.25"
        case .thermal: return "thermometer.medium"
        case .library: return "photo.on.rectangle"
        case .battery: return "battery.100"
        }
    }

    private func load() {
        let process = ProcessInfo.processInfo
        let next = HealthReading.rows(
            freeBytes: storage?.freeBytes ?? 0,
            totalBytes: storage?.totalBytes ?? 0,
            lowPowerMode: process.isLowPowerModeEnabled,
            thermalState: process.thermalState,
            libraryBytes: report?.totalLibraryBytes,
            libraryAssetCount: report?.totalAssetCount
        )
        if reduceMotion {
            rows = next
        } else {
            withAnimation(.snappy(duration: 0.3)) { rows = next }
        }
    }
}
