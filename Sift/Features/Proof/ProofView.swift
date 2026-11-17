import SwiftUI

/// The last mile: what was moved, what iOS actually returned, and nothing else.
struct ProofView: View {
    let movedBytes: Int64
    let store: SpaceLedgerStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var verifiedBytes: Int64?
    @State private var didOpenPhotos: Bool?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        seal

                        VStack(spacing: 8) {
                            Text(SpaceLedger.proofHeadline(moved: movedBytes, verified: verifiedBytes))
                                .font(Typo.title3Semibold)
                                .foregroundStyle(Theme.ink)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .contentTransition(.numericText())
                                .animation(.snappy, value: verifiedBytes)

                            Text(explanation)
                                .font(Typo.subheadline)
                                .foregroundStyle(Theme.secondaryInk)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .contentTransition(.opacity)
                                .animation(.snappy, value: verifiedBytes)
                        }

                        Card {
                            VStack(alignment: .leading, spacing: 14) {
                                step(1, "Open Recently Deleted", "Photos → Albums → Utilities → Recently Deleted.")
                                step(2, "Select, then Delete All", "iOS keeps deleted photos for 30 days. The space returns when you empty it.")
                                step(3, "Come back and check", "Sift measures the volume again and shows what actually came back.")
                            }
                        }

                        VStack(spacing: 10) {
                            Button("Open Recently Deleted") {
                                didOpenPhotos = PhotosDeepLink.openPhotos()
                                Haptics.selection()
                            }
                            .buttonStyle(PrimaryButtonStyle())

                            if didOpenPhotos == false {
                                Text("If Photos did not open: Photos → Albums → Utilities → Recently Deleted → Select → Delete All.")
                                    .font(Typo.caption)
                                    .foregroundStyle(Theme.secondaryInk)
                                    .multilineTextAlignment(.center)
                            }

                            Button("Check again") { measure() }
                                .buttonStyle(SecondaryButtonStyle())
                        }
                        .padding(.top, 2)

                        Button("Done") { dismiss() }
                            .font(Typo.subheadlineMedium)
                            .foregroundStyle(Theme.secondaryInk)
                            .frame(minHeight: 44)
                    }
                    .padding(.horizontal, Theme.margin)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Recently Deleted")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: measure)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { measure() }
            }
        }
    }

    private var seal: some View {
        ZStack {
            Circle()
                .fill(verifiedBytes == nil ? Theme.fill : Theme.reclaim.opacity(0.14))
                .frame(width: 112, height: 112)
                .animation(.snappy, value: verifiedBytes)
            Image(systemName: verifiedBytes == nil ? "tray.and.arrow.down" : "checkmark.seal")
                .font(Typo.size(38, weight: .light, relativeTo: .largeTitle))
                .foregroundStyle(verifiedBytes == nil ? Theme.secondaryInk : Theme.reclaim)
                .symbolEffect(.bounce, value: verifiedBytes)
                .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityHidden(true)
    }

    private var explanation: String {
        if let verifiedBytes, verifiedBytes > 0 {
            return "Sift moved \(Format.floorBytes(movedBytes)). iOS returned \(Format.floorBytes(verifiedBytes)) to free space."
        }
        return "Nothing is freed until Recently Deleted is emptied. This is the step every other cleaner leaves out."
    }

    private func step(_ number: Int, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(Typo.footnoteSemibold).monospacedDigit()
                .foregroundStyle(Theme.ink)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Theme.fill))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typo.subheadlineMedium)
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func measure() {
        guard let snapshot = StorageService.snapshot() else { return }
        guard let verified = store.confirmVerified(snapshot: snapshot) else { return }
        if reduceMotion {
            verifiedBytes = verified
        } else {
            withAnimation(.snappy(duration: 0.3)) { verifiedBytes = verified }
        }
        Haptics.success()
    }
}
