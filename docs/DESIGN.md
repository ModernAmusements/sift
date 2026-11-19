# Design system

Sift is quiet. The content is the interface. Black and white do the work; orange is the one highlight.

## Principles

1. **One job per screen.** The home screen answers "how much space, what can go".
2. **Numbers are the hero.** Storage and reclaimed space get large, tabular figures.
3. **Black, white, one orange highlight.** No second brand colour, no gradients, no box shadows. Orange marks the primary action, the storage ring, selection and success.
4. **Space is a feature.** 20 pt margins, 24–32 pt between sections, no crowding.
5. **Liquid Glass where iOS 26 allows it.** Buttons, the scan panel and the selection bar use Apple's `glassEffect`; content cards stay opaque. iOS 17–25 gets the same layout with flat fills. Glass is never used as a substitute for hierarchy.
6. **Destructive actions are explicit.** Ink outline, then the system confirmation. Never red unless something is irreversible.

Apple is the reference: [Human Interface Guidelines](https://developer.apple.com/design/), [Design resources](https://developer.apple.com/design/resources/). SF Symbols only; no custom icon sets.

## Colour

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `Theme.background` | `#F5F5F7` | `#000000` | screen |
| `Theme.card` | `#FFFFFF` | `#1C1C1E` | cards, rows |
| `Theme.cardRaised` | `#FFFFFF` | `#2C2C2E` | elevated card |
| `Theme.ink` | `#0A0A0A` | `#FFFFFF` | primary text |
| `Theme.secondaryInk` | `#6E6E73` | `#A1A1A6` | captions |
| `Theme.tertiaryInk` | `#8E8E93` | `#8E8E93` | metadata |
| `Theme.separator` | `#D9D9DE` | `#38383A` | dividers |
| `Theme.accent` | `#FF6600` | `#FF6600` | primary action, selection, success |

Primary button: orange, with a near-black label (`#0A0A0A`, 6:1 contrast). On iOS 26 it is a light-tinted Liquid Glass capsule; on iOS 17–25 a solid orange capsule. Disabled controls use a neutral grey tint, never a washed-out orange. No shadows anywhere.

## Type

The app uses **Neo Grotesque-P5M5** for every text style. One face, supplied by the owner; hierarchy comes from size, colour and tracking. No SF Pro text, no bundled second weight. Tabular figures (`tnum`) are present, so `.monospacedDigit()` lines stay aligned.

| Role | Style |
| --- | --- |
| Screen title | `Typo.largeTitle` (34 pt, P5M5) |
| Storage number | `Typo.size(28, weight: .semibold)` + `.monospacedDigit()` |
| Section title | `Typo.title3` / `.headline` |
| Body | `Typo.body` (17 pt) |
| Caption | `Typo.caption` / `Typo.caption2` |
| Button | `Typo.headline` |
| Mono labels | `Typo.label` + tracking |

The website loads the same P5M5 cut from `docs/fonts/`. See [`FONT.md`](FONT.md).

## Navigation

- Home uses an inline navigation bar with the **Sift lockup** as the principal item and a system glass gear on the trailing edge.
- Push destinations use standard navigation bars and the system back button.
- Settings is a sheet with a standard `List` and a Done toolbar item.
- No custom tab bar; the home screen is the single entry point.

## Spacing and shape

`4 · 8 · 12 · 16 · 20 · 24 · 32 · 48`. Screen margin 20. Card padding 20. Row height 64 minimum. Screen cards: 26 pt continuous radius. Thumbnails: 14 pt. Buttons: capsule (height 54).

## Motion

| Event | Animation |
| --- | --- |
| Onboarding arrival | opacity + 12 pt rise, staggered; Reduce Motion keeps opacity |
| Storage ring | `.easeOut(duration: 0.8)` trim; numeric text for the byte label |
| Selection | `.snappy(duration: 0.22)` scale 0.985 → 1; checkmark symbol bounce |
| Button press | scale 0.975, light impact haptic on press |
| Scanning stage text | `.contentTransition(.opacity)`, `.snappy` |
| Scan overlay | `.snappy` opacity + 0.97 scale in; glass panel on iOS 26 |
| Scan progress | numeric-text percent; indeterminate until the first measurement |
| Swipe card | interactive spring, threshold 34% width, light tick when crossing |
| Proof seal | `.symbolEffect(.bounce)` on verification; orange ring appears only after proof |

Reduce Motion: disable the rise, scale, bounce and ring trim; keep opacity and numeric text.

## Scrolling

- A screen scrolls only when its content exceeds the viewport: `.scrollBounceBehavior(.basedOnSize)`.
- Hide scroll indicators on editorial screens (home, health, proof); leave system lists as Apple ships them.
- Never nest a vertical scroll inside another vertical scroll.

## Haptics

- Selection: `UISelectionFeedbackGenerator`.
- Button press: light impact via `.sensoryFeedback`, on press only.
- Successful cleanup: `UINotificationFeedbackGenerator.success`.
- Destructive confirmation: `.warning`.
- Never on scroll or launch.

## Components (`Sift/Design/Theme.swift`)

`Card`, `SectionHeader`, `StorageRing`, `PrimaryButtonStyle`, `SecondaryButtonStyle`, `PressableStyle`, `CategoryRow`, `MediaThumbnail`, `SelectionBadge`, `EmptyState`, `PermissionState`, `StatPill`, `SiftLockup`, `MAByline`.

The Sift lockup comes from the owner's `sift-logo-pack`; the app icon is the owner's Apple Icon Composer "Default" iOS export. The credit footer uses the owner's landscape wordmark (`MAWordmark.svg`, from `moder-amusement-logo-pack`) as template-tinted artwork — never as typeset "Modern Amusement" text. The lockup is leading-aligned wherever it appears.

## Accessibility

- Every icon button has a label.
- The storage ring reads "Storage", value "62.4 gigabytes used of 128 gigabytes, 65.6 gigabytes free".
- Thumbnails: "Photo, 12 March 2025, 4.2 megabytes", value "Selected/Not selected".
- Dynamic Type up to AX3: cards grow vertically, grids stay 3 columns but labels truncate gracefully.
- Contrast: secondary text ≥ 4.5:1 on card backgrounds; the orange label is near-black at 6:1.
- Swipe actions have visible buttons as alternatives.

## Copy

- Sentence case. Short verbs. No exclamation marks.
- "Move to Recently Deleted", not "Delete forever".
- "Nothing to clean here." not "You're all clean! 🎉".
- Every permission screen says why, what stays on device, and what happens on decline.
