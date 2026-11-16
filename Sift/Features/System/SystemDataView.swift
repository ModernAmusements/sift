import SwiftUI

struct SystemDataView: View {
    private let steps: [(String, String)] = [
        ("Restart your iPhone", "A restart clears temporary system state that no app can reach."),
        ("Update iOS", "Settings → General → Software Update. Newer builds often reclaim stale system data."),
        ("Offload unused apps", "Settings → General → iPhone Storage. Offloading keeps documents while removing the app binary."),
        ("Review Messages", "Large photos and videos in conversations live inside Messages, not Photos."),
        ("Clear Safari data", "Settings → Safari → Clear History and Website Data."),
        ("Empty Recently Deleted", "Photos → Albums → Recently Deleted. This is where Sift's removals wait for 30 days."),
        ("Remove downloads", "Music, Podcasts and TV keep their own offline files. Remove what you no longer play."),
        ("Delete big files", "Use Sift's Files tool to remove exports, archives and downloads from On My iPhone or iCloud Drive.")
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Why Sift can't clear it for you", systemImage: "lock.shield")
                                .font(.headline)
                                .foregroundStyle(Theme.ink)
                            Text("iOS sandboxes every app. No third-party app can read or delete another app's cache, system caches or “other” storage. Apps that claim to do it are guessing or misleading you. Sift will not.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.secondaryInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    SectionHeader(title: "What you can do")

                    Card(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 14) {
                                    Text("\(index + 1)")
                                        .font(.caption.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(Theme.ink)
                                        .frame(width: 26, height: 26)
                                        .background(Circle().fill(Theme.fill))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(step.0)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(Theme.ink)
                                        Text(step.1)
                                            .font(.footnote)
                                            .foregroundStyle(Theme.secondaryInk)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)

                                if index != steps.count - 1 {
                                    Rectangle()
                                        .fill(Theme.separator)
                                        .frame(height: 0.5)
                                        .padding(.leading, 58)
                                }
                            }
                        }
                    }

                    NavigationLink(value: Route.files) {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundStyle(Theme.ink)
                            Text("Open Files & documents")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.tertiaryInk)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                                .fill(Theme.card)
                        )
                    }
                    .buttonStyle(.plain)

                    Text("Sift removes only what iOS lets it touch: your photos, videos, chosen files and duplicate contacts.")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, Theme.margin)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        .navigationTitle("System data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}
