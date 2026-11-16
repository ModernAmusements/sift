import Contacts
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var engine: ScanEngine
    @Environment(\.dismiss) private var dismiss

    @AppStorage("similarityThreshold") private var similarity: Double = 0.15
    @State private var contactStatus = CNContactStore.authorizationStatus(for: .contacts)
    @State private var cacheBytes: Int64 = 0
    @State private var activeAlert: LocalAlert?

    private enum LocalAlert: Identifiable {
        case clearResults
        case cacheError(String)

        var id: String {
            switch self {
            case .clearResults: return "clearResults"
            case .cacheError: return "cacheError"
            }
        }
    }

    private let repository = "https://github.com/ModernAmusements/sift"
    private let ledger = SpaceLedgerStore()

    var body: some View {
        NavigationStack {
            List {
                scanningSection
                reclaimedSection
                cacheSection
                permissionsSection
                privacySection
                aboutSection
                resetSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .clearResults:
                    return Alert(
                        title: Text("Clear scan results?"),
                        message: Text("This only removes Sift's results. No photo or contact is touched."),
                        primaryButton: .destructive(Text("Clear")) {
                            engine.clearResults()
                            Haptics.warning()
                        },
                        secondaryButton: .cancel()
                    )
                case .cacheError(let message):
                    return Alert(
                        title: Text("Could not clear cache"),
                        message: Text(message),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .onAppear {
                contactStatus = CNContactStore.authorizationStatus(for: .contacts)
                cacheBytes = CacheService.bytes()
            }
        }
    }

    private var reclaimedSection: some View {
        Section {
            LabeledContent("Reclaimed") {
                Text(reclaimedText)
                    .foregroundStyle(Theme.secondaryInk)
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
            }
        } header: {
            Text("Reclaimed")
        } footer: {
            Text("Only space iOS actually gave back counts. Moving photos to Recently Deleted is not freeing — emptying it is.")
        }
    }

    private var reclaimedText: String {
        guard ledger.verifiedTotal > 0, let since = ledger.verifiedSince else {
            return "Nothing verified yet"
        }
        return "\(Format.floorBytes(ledger.verifiedTotal)) verified since \(Format.shortDay(since))"
    }

    private var cacheSection: some View {
        Section {
            LabeledContent("Sift cache") {
                Text(cacheBytes > 0 ? Format.bytes(cacheBytes) : "0 B")
                    .foregroundStyle(Theme.secondaryInk)
            }
            Button("Clear cache") {
                do {
                    try CacheService.clear()
                    cacheBytes = CacheService.bytes()
                    Haptics.success()
                } catch {
                    activeAlert = .cacheError(error.localizedDescription)
                }
            }
            .disabled(cacheBytes == 0)
        } header: {
            Text("Local cache")
        } footer: {
            Text("Temporary thumbnails and scratch files created by Sift. Clearing this never touches your photos, contacts or scan results.")
        }
    }

    private var scanningSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Similarity")
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(similarityLabel)
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryInk)
                }
                Slider(value: $similarity, in: 0.08...0.30, step: 0.01)
                    .tint(Theme.ink)
                    .accessibilityLabel("Similarity sensitivity")
                    .accessibilityValue(similarityLabel)
                HStack {
                    Text("Stricter")
                    Spacer()
                    Text("Broader")
                }
                .font(.caption2)
                .foregroundStyle(Theme.tertiaryInk)
            }
            .padding(.vertical, 4)

            LabeledContent("Last scan") {
                Text(engine.lastScanDate.map { Format.date($0) } ?? "Never")
                    .foregroundStyle(Theme.secondaryInk)
            }
        } header: {
            Text("Scanning")
        } footer: {
            Text("Lower is stricter. Sift only compares photos captured on the same day. Changes apply to the next scan.")
        }
    }

    private var permissionsSection: some View {
        Section {
            LabeledContent {
                Text(PhotoLibraryService.authorizationCopy)
                    .foregroundStyle(Theme.secondaryInk)
            } label: {
                Label("Photos", systemImage: "photo.on.rectangle")
            }

            LabeledContent {
                Text(contactsText)
                    .foregroundStyle(Theme.secondaryInk)
            } label: {
                Label("Contacts", systemImage: "person.2")
            }

            Button {
                openSettings()
            } label: {
                Label("Open iOS Settings", systemImage: "arrow.up.right.square")
            }
        } header: {
            Text("Permissions")
        } footer: {
            Text("Sift asks for Contacts only when you open the contacts tool.")
        }
    }

    private var privacySection: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 3) {
                    Text("No network, no analytics")
                        .foregroundStyle(Theme.ink)
                    Text("There is no code in Sift that can send your data anywhere.")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryInk)
                }
            } icon: {
                Image(systemName: "lock.shield")
            }

            if let url = URL(string: "\(repository)/blob/main/docs/PRIVACY.md") {
                Link(destination: url) {
                    LabeledContent("Privacy policy") {
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.tertiaryInk)
                    }
                }
            }
        } header: {
            Text("Privacy")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version") {
                Text(versionText)
                    .foregroundStyle(Theme.secondaryInk)
            }
            if let url = URL(string: repository) {
                Link(destination: url) {
                    LabeledContent("Source code") {
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.tertiaryInk)
                    }
                }
                if let license = URL(string: "\(repository)/blob/main/LICENSE") {
                    Link(destination: license) {
                        LabeledContent("License", value: "MIT")
                    }
                }
            }
            Text("Made with restraint. Free because it should be.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryInk)
        } header: {
            Text("About")
        }
    }

    private var resetSection: some View {
        Section {
            Button("Clear scan results", role: .destructive) {
                activeAlert = .clearResults
            }
            .disabled(engine.report == nil && engine.contactGroups.isEmpty)
        }
    }

    private var similarityLabel: String {
        if similarity < 0.13 { return "Stricter" }
        if similarity > 0.19 { return "Broader" }
        return "Balanced"
    }

    private var contactsText: String {
        if #available(iOS 18.0, *), contactStatus == .limited {
            return "Limited access"
        }
        switch contactStatus {
        case .authorized: return "Full access"
        case .denied: return "Not allowed"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not requested"
        case .limited: return "Limited access"
        @unknown default: return "Unknown"
        }
    }

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
