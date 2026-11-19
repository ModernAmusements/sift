import SwiftUI
import UIKit

// MARK: - Type

/// Neo Grotesque, supplied by the owner. Static cuts are generated from the
/// variable P6M6 source (opsz 14/96) so every weight is a real face.
enum Typo {
    // One face only: Neo Grotesque-P5M5. Hierarchy comes from size, colour and
    // tracking rather than a second weight, exactly like the brand's site.
    private static func p5(_ size: CGFloat, _ style: Font.TextStyle) -> Font {
        .custom("SiftNeo-P5M5", size: size, relativeTo: style)
    }

    static var largeTitle: Font { p5(34, .largeTitle) }
    static var title: Font { p5(28, .title) }
    static var title2: Font { p5(22, .title2) }
    static var title2Semibold: Font { p5(22, .title2) }
    static var title3: Font { p5(20, .title3) }
    static var title3Semibold: Font { p5(20, .title3) }
    static var headline: Font { p5(17, .headline) }
    static var body: Font { p5(17, .body) }
    static var bodyMedium: Font { p5(17, .body) }
    static var bodySemibold: Font { p5(17, .body) }
    static var subheadline: Font { p5(15, .subheadline) }
    static var subheadlineMedium: Font { p5(15, .subheadline) }
    static var subheadlineSemibold: Font { p5(15, .subheadline) }
    static var footnote: Font { p5(13, .footnote) }
    static var footnoteMedium: Font { p5(13, .footnote) }
    static var footnoteSemibold: Font { p5(13, .footnote) }
    static var caption: Font { p5(12, .caption) }
    static var captionMedium: Font { p5(12, .caption) }
    static var captionSemibold: Font { p5(12, .caption) }
    static var caption2: Font { p5(11, .caption2) }
    static var caption2Medium: Font { p5(11, .caption2) }
    static var caption2Semibold: Font { p5(11, .caption2) }

    static var label: Font { caption2 }
    static var labelSemibold: Font { caption2 }

    static func size(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo style: Font.TextStyle = .body
    ) -> Font {
        p5(size, style)
    }

    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        p5(size, style)
    }

    static func displayFixed(_ size: CGFloat) -> Font {
        .custom("SiftNeo-P5M5", fixedSize: size)
    }

    static func registerNavigationAppearance() {
        guard let face = UIFont(name: "SiftNeo-P5M5", size: 34) else { return }
        let nav = UINavigationBar.appearance()
        nav.largeTitleTextAttributes = [.font: face]
        nav.titleTextAttributes = [.font: UIFont(name: "SiftNeo-P5M5", size: 17) ?? face]
        UIBarButtonItem.appearance().setTitleTextAttributes(
            [.font: UIFont(name: "SiftNeo-P5M5", size: 17) ?? face],
            for: .normal
        )
    }
}


// MARK: - Palette

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

enum Theme {
    /// The owner's brand orange. A highlight, never the page colour.
    static let accent = Color(light: 0xFF6600, dark: 0xFF6600)
    static let accentDeep = Color(light: 0xC2410C, dark: 0xFF8A33)

    /// Black, white and Apple's grouped greys. No second brand colour.
    static let background = Color(light: 0xF5F5F7, dark: 0x000000)
    static let card = Color(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let cardRaised = Color(light: 0xFFFFFF, dark: 0x2C2C2E)

    static let ink = Color(light: 0x0A0A0A, dark: 0xFFFFFF)
    static let secondaryInk = Color(light: 0x6E6E73, dark: 0xA1A1A6)
    static let tertiaryInk = Color(light: 0x8E8E93, dark: 0x8E8E93)
    static let separator = Color(light: 0xD9D9DE, dark: 0x38383A)
    static let hairline = Color(light: 0xE5E5EA, dark: 0x3A3A3C)
    static let fill = Color(light: 0xFF6600, dark: 0xFF6600).opacity(0.10)
    static let fillStrong = Color(light: 0xFF6600, dark: 0xFF6600).opacity(0.16)

    /// Label colour on an orange fill: near-black keeps 6:1 contrast.
    static let onAccent = Color(light: 0x0A0A0A, dark: 0x0A0A0A)
    /// Success is the same brand highlight; no green in the palette.
    static let reclaim = Color(light: 0xFF6600, dark: 0xFF6600)

    static let corner: CGFloat = 26
    static let margin: CGFloat = 20
}

struct Card<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.card)
            )
    }
}

struct SectionHeader: View {
    let title: String
    var detail: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Typo.title3Semibold)
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 12)
            if let detail {
                Text(detail)
                    .font(Typo.footnote).monospacedDigit()
                    .foregroundStyle(Theme.secondaryInk)
            }
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typo.headline)
            .foregroundStyle(isEnabled ? Theme.onAccent : Theme.secondaryInk)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                if #available(iOS 26.0, *) {
                    // Apple's Liquid Glass, tinted with the Sift orange.
                    Capsule(style: .continuous)
                        .fill(.clear)
                        .glassEffect(
                            .regular
                                .tint(isEnabled
                                      ? Theme.accent.opacity(colorScheme == .dark ? 0.95 : 0.78)
                                      : Color.gray.opacity(0.16))
                                .interactive(),
                            in: .capsule
                        )
                } else {
                    Capsule(style: .continuous)
                        .fill(isEnabled ? Theme.accent : Color.gray.opacity(0.16))
                }
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, pressed in
                pressed
            }
    }
}

/// Press response for rows and thumbnails. Keeps layout stable.
struct PressableStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typo.headline)
            .foregroundStyle(Theme.ink.opacity(isEnabled ? 1 : 0.3))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                if #available(iOS 26.0, *) {
                    Capsule(style: .continuous)
                        .fill(.clear)
                        .glassEffect(.regular.interactive(), in: .capsule)
                } else {
                    Capsule(style: .continuous)
                        .stroke(Theme.separator, lineWidth: 1)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, pressed in
                pressed
            }
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
                    Theme.accent,
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
                    .contentTransition(.numericText())
                    .animation(.snappy, value: usedText)
                Text("used")
                    .font(Typo.captionMedium)
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
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
            Text(label)
                .font(Typo.caption)
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
                .font(Typo.size(16, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Theme.fill))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typo.bodyMedium)
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(Typo.footnote)
                    .foregroundStyle(Theme.secondaryInk)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if let value {
                Text(value)
                    .font(Typo.footnote).monospacedDigit()
                    .foregroundStyle(Theme.secondaryInk)
            }
            Image(systemName: "chevron.right")
                .font(Typo.captionSemibold)
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
        GeometryReader { geometry in
            ZStack {
                Rectangle().fill(Theme.fill)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .transition(.opacity)
                } else {
                    Image(systemName: asset.isVideo ? "video" : "photo")
                        .font(Typo.title3)
                        .foregroundStyle(Theme.tertiaryInk)
                }

                if showsSize && asset.isVideo {
                    VStack {
                        Spacer()
                        HStack {
                            Label(Format.duration(asset.duration), systemImage: "play.fill")
                                .font(Typo.caption2Semibold).monospacedDigit()
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(.black.opacity(0.55)))
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
                        .stroke(Theme.accent, lineWidth: isSelected ? 3 : 0)
                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Theme.accent : .black.opacity(0.22))
                                Circle()
                                    .stroke(.white.opacity(0.9), lineWidth: 1.5)
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(Typo.captionSemibold)
                                        .foregroundStyle(Theme.onAccent)
                                }
                            }
                            .frame(width: 24, height: 24)
                            .padding(7)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .aspectRatio(1, contentMode: .fit)
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
                .font(Typo.size(28, weight: .light))
                .foregroundStyle(Theme.secondaryInk)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Theme.fill))
            Text(title)
                .font(Typo.headline)
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(Typo.subheadline)
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
                .font(Typo.size(28, weight: .light))
                .foregroundStyle(Theme.ink)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Theme.fill))

            VStack(spacing: 8) {
                Text(title)
                    .font(Typo.title3Semibold)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(Typo.subheadline)
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

extension View {
    /// A calm entrance: 12 pt rise with a per-index delay. Reduce Motion keeps opacity only.
    func riseIn(_ appeared: Bool, index: Int = 0) -> some View {
        modifier(RiseIn(appeared: appeared, index: index))
    }
}

private struct RiseIn: ViewModifier {
    let appeared: Bool
    let index: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 12)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.18)
                    : .snappy(duration: 0.46).delay(Double(min(index, 10)) * 0.045),
                value: appeared
            )
    }
}

/// The ModernAmusement signature. The wordmark is the owner's own artwork.
struct MAByline: View {
    var compact = false

    var body: some View {
        VStack(spacing: compact ? 6 : 8) {
            Image("MAWordmark")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(height: compact ? 18 : 26)
                .foregroundStyle(Theme.accent)
            if !compact {
                Text("Shady Nathan Tawfik · Bielefeld, DE")
                    .font(Typo.caption)
                    .foregroundStyle(Theme.tertiaryInk)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ModernAmusement. Shady Nathan Tawfik, Bielefeld.")
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
                    .font(Typo.subheadlineMedium)
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(Format.bytes(bytes))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.secondaryInk)
            }
            Button(action: action) {
                HStack(spacing: 8) {
                    if isBusy { ProgressView().tint(Theme.onAccent) }
                    Text(isBusy ? "Moving…" : actionTitle)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(count == 0 || isBusy)

            if let note {
                Text(note)
                    .font(Typo.caption2)
                    .foregroundStyle(Theme.tertiaryInk)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Theme.margin)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background { barBackground }
    }

    @ViewBuilder
    private var barBackground: some View {
        if #available(iOS 26.0, *) {
            Rectangle()
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: 0))
        } else {
            Rectangle().fill(.bar)
        }
    }
}
