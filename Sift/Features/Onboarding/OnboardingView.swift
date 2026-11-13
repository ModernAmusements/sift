import SwiftUI

struct OnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Text("Sift")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.secondaryInk)
                        .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 18) {
                        Text("A lighter\niPhone.")
                            .font(.system(size: 50, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .lineSpacing(-4)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Find the photos, videos and contacts you no longer need. Sift works on this iPhone and never sends anything anywhere.")
                            .font(.body)
                            .foregroundStyle(Theme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(3)
                    }

                    VStack(spacing: 0) {
                        feature(
                            symbol: "camera.viewfinder",
                            title: "Screenshots",
                            detail: "Tickets, chats and receipts you already used."
                        )
                        divider
                        feature(
                            symbol: "square.stack.3d.up",
                            title: "Duplicates and near-duplicates",
                            detail: "Sift keeps the sharpest frame and shows the rest."
                        )
                        divider
                        feature(
                            symbol: "video",
                            title: "Large videos",
                            detail: "The clips quietly taking gigabytes."
                        )
                        divider
                        feature(
                            symbol: "person.2",
                            title: "Duplicate contacts",
                            detail: "Merge repeated cards into one clean entry."
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                            .fill(Theme.card)
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Label("No account. No ads. No tracking.", systemImage: "lock.shield")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Theme.ink)
                        Text("Sift is free and open source. Removals go through Apple's Recently Deleted, so you have 30 days to change your mind.")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, Theme.margin)
                .padding(.bottom, 20)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button("Get started", action: onContinue)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Theme.margin)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(Theme.background)
        }
    }

    private func feature(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.ink)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Theme.fill))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.separator)
            .frame(height: 0.5)
            .padding(.leading, 70)
    }
}
