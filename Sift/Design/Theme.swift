import SwiftUI

enum Theme {
    static let background = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let ink = Color(uiColor: .label)
    static let secondaryInk = Color(uiColor: .secondaryLabel)
    static let tertiaryInk = Color(uiColor: .tertiaryLabel)
    static let separator = Color(uiColor: .separator).opacity(0.55)
    static let reclaim = Color(uiColor: .systemGreen)
    static let fill = Color(uiColor: .tertiarySystemFill)
    static let corner: CGFloat = 26
    static let margin: CGFloat = 20
}

struct Card<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.card)
            )
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.035),
                radius: 18,
                x: 0,
                y: 8
            )
    }
}

struct ScreenTitle: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(Theme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionHeader: View {
    let title: String
    var detail: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 12)
            if let detail {
                Text(detail)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Theme.secondaryInk)
            }
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.background)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Capsule(style: .continuous)
                    .fill(Theme.ink.opacity(isEnabled ? 1 : 0.25))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.ink.opacity(isEnabled ? 1 : 0.3))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                Capsule(style: .continuous)
                    .stroke(Theme.separator, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

struct StorageRing: View {
    let fraction: Double
    let usedText: String
    let freeText: String
    var size: CGFloat = 154

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.fill, lineWidth: 13)
            Circle()
                .trim(from: 0, to: max(0.001, min(shown, 1)))
                .stroke(
                    Theme.ink,
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text(usedText)
                    .font(.system(size: 30, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("used")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.secondaryInk)
            }
            .padding(.horizontal, 18)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Storage")
        .accessibilityValue("\(usedText) used, \(freeText) free")
        .onAppear { update(fraction) }
        .onChange(of: fraction) { _, value in update(value) }
    }

    private func update(_ value: Double) {
        if reduceMotion {
            shown = value
        } else {
            withAnimation(.easeOut(duration: 0.8)) { shown = value }
        }
    }
}

struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CategoryRow: View {
    let symbol: String
    let title: String
    let detail: String
    var value: String?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Theme.fill))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryInk)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if let value {
                Text(value)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Theme.secondaryInk)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.tertiaryInk)
        }
        .contentShape(Rectangle())
        .frame(minHeight: 52)
    }
}

struct MediaThumbnail: View {
    let asset: ScannedAsset
    var isSelected: Bool?
    var showsSize = true
    var targetSize: CGFloat = 360

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Rectangle().fill(Theme.fill)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else {
                Image(systemName: asset.isVideo ? "video" : "photo")
                    .font(.title3)
                    .foregroundStyle(Theme.tertiaryInk)
            }

            if showsSize {
                VStack {
                    Spacer()
                    HStack {
                        if asset.isVideo {
                            Label(Format.duration(asset.duration), systemImage: "play.fill")
                                .font(.caption2.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(.black.opacity(0.55)))
                        }
                        Spacer()
                    }
                    .padding(7)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.28)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .padding(.top, -18)
                    )
                }
            }

            if let isSelected {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.ink, lineWidth: isSelected ? 3 : 0)
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(isSelected ? Theme.ink : .black.opacity(0.22))
                            Circle()
                                .stroke(.white.opacity(0.9), lineWidth: 1.5)
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Theme.background)
                            }
                        }
                        .frame(width: 24, height: 24)
                        .padding(7)
                    }
                    Spacer()
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .task(id: asset.id) {
            image = await ThumbnailCache.shared.image(
                id: asset.id,
                size: CGSize(width: targetSize, height: targetSize)
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(asset.isScreenshot ? "Screenshot" : asset.isVideo ? "Video" : "Photo"), \(Format.date(asset.creationDate)), \(asset.sizeBytes > 0 ? asset.sizeText : "size unavailable")"
        )
        .accessibilityValue(isSelected == true ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected == true ? .isSelected : [])
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Theme.secondaryInk)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Theme.fill))
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryInk)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
    }
}

struct PermissionState: View {
    let symbol: String
    let title: String
    let message: String
    let primaryTitle: String
    var secondaryTitle: String?
    let primaryAction: () -> Void
    var secondaryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Theme.ink)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Theme.fill))

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryInk)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(primaryTitle, action: primaryAction)
                .buttonStyle(PrimaryButtonStyle())

            if let secondaryTitle, let secondaryAction {
                Button(secondaryTitle, action: secondaryAction)
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Theme.card)
        )
    }
}

struct SelectionBar: View {
    let count: Int
    let bytes: Int64
    let actionTitle: String
    let action: () -> Void
    var isBusy = false
    var note: String?

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(count == 0 ? "Nothing selected" : Format.count(count, "item"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(Format.bytes(bytes))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.secondaryInk)
            }
            Button(action: action) {
                HStack(spacing: 8) {
                    if isBusy { ProgressView().tint(Theme.background) }
                    Text(isBusy ? "Moving…" : actionTitle)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(count == 0 || isBusy)

            if let note {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(Theme.tertiaryInk)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Theme.margin)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background(.bar)
    }
}
