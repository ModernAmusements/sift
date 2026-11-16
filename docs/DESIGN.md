# Design system

Sift is quiet. The content is the interface.

## Principles

1. **One job per screen.** The home screen answers "how much space, what can go".
2. **Numbers are the hero.** Storage and reclaimed space get large, monospaced-digit type.
3. **Monochrome, one accent.** Ink on paper; green only for reclaimed space and success.
4. **Space is a feature.** 20 pt margins, 24–32 pt between sections, no crowding.
5. **No decoration for its own sake.** No gradients, emoji, illustrations or progress confetti. On iOS 26, Apple's Liquid Glass is the system material, so controls and floating surfaces use it per the HIG; on iOS 17–25 the same surfaces stay flat. Glass is never applied to content cards.

Apple is the reference: [Human Interface Guidelines](https://developer.apple.com/design/), [Design resources](https://developer.apple.com/design/resources/). Use SF Pro through system text styles and SF Symbols only; no bundled fonts, no custom icon sets.
6. **Destructive actions are explicit.** Ink outline, then the system confirmation. Never red unless something is irreversible.

## Color

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `Theme.background` | systemGroupedBackground | systemGroupedBackground | screen |
| `Theme.card` | secondarySystemGroupedBackground | secondarySystemGroupedBackground | cards, rows |
| `Theme.ink` | label | label | primary text, primary button |
| `Theme.secondaryInk` | secondaryLabel | secondaryLabel | captions |
| `Theme.separator` | separator (0.6 opacity) | separator | dividers |
| `Theme.reclaim` | systemGreen | systemGreen | reclaimed bytes, success |
| `Theme.fill` | tertiarySystemFill | tertiarySystemFill | unselected chip, track |

Primary button: ink background, background-colored label on iOS 17–25. On iOS 26 it is a light-tinted Liquid Glass capsule with an ink label, still the single strongest action on the screen. In dark mode this inverts naturally via semantic colors.

## Type

| Role | Style |
| --- | --- |
| Screen title | `.largeTitle.weight(.semibold)` |
| Storage number | `.system(size: 44, weight: .semibold, design: .default)` + `.monospacedDigit()` |
| Section title | `.title3.weight(.semibold)` |
| Card title | `.headline` |
| Body | `.body` |
| Caption | `.footnote` / `.caption` secondary |
| Button | `.headline` |

No custom fonts. No all-caps labels. No letter-spacing games.

## Navigation

- The root screen uses a native large navigation title (`Sift`) and a system toolbar; there is no custom header.
- Push destinations use standard navigation bars and the system back button.
- Settings is a sheet with a standard `List` and a Done toolbar item.
- No custom tab bar; the home screen is the single entry point.

## Spacing

`4 · 8 · 12 · 16 · 20 · 24 · 32 · 48`. Screen margin 20. Card padding 20. Row height 64 minimum.

## Shape

- Screen cards: 26 pt continuous corner radius.
- Thumbnails: 14 pt.
- Buttons: capsule (height 54).
- Selection: 2.5 pt ink ring + checkmark disc, not a color wash.

## Motion

| Event | Animation |
| --- | --- |
| Storage ring | `.easeOut(duration: 0.8)` trim; numeric text for the byte label |
| Screen content | `.snappy` opacity + 8 pt rise |
| Selection | `.snappy(duration: 0.22)` scale 0.97 → 1 |
| Scanning stage text | `.contentTransition(.opacity)`, `.snappy` |
| Scan overlay | `.snappy` opacity + 0.97 scale in; glass panel on iOS 26 |
| Scan progress | numeric-text percent; indeterminate spinner until the first measurement (never a fake 0%) |
| Check-in copy | numeric-text delta and opacity detail when the measurement changes |
| Proof seal | `.symbolEffect(.bounce)` on verification; green ring appears only after proof |
| Swipe card | interactive spring, threshold 34% width |

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

`Card`, `SectionHeader`, `StorageRing`, `PrimaryButton`, `SecondaryButton`, `CategoryRow`, `MediaThumbnail`, `SelectionBadge`, `EmptyState`, `PermissionState`, `StatPill`.

## Accessibility

- Every icon button has a label.
- Storage ring: label "Storage", value "62.4 gigabytes used of 128 gigabytes, 65.6 gigabytes free".
- Thumbnails: label "Photo, 12 March 2025, 4.2 megabytes", value "Selected/Not selected".
- Dynamic Type up to AX3: cards grow vertically, grids stay 3 columns but labels truncate gracefully.
- Contrast: secondary text ≥ 4.5:1 on card backgrounds.
- Swipe actions have visible buttons as alternatives.

## Copy

- Sentence case. Short verbs. No exclamation marks.
- "Move to Recently Deleted", not "Delete forever".
- "Nothing to clean here." not "You're all clean! 🎉".
- Every permission screen says why, what stays on device, and what happens on decline.
