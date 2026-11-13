# Design system

Sift is quiet. The content is the interface.

## Principles

1. **One job per screen.** The home screen answers "how much space, what can go".
2. **Numbers are the hero.** Storage and reclaimed space get large, monospaced-digit type.
3. **Monochrome, one accent.** Ink on paper; green only for reclaimed space and success.
4. **Space is a feature.** 20 pt margins, 24–32 pt between sections, no crowding.
5. **No decoration for its own sake.** No gradients, glassmorphism, emoji, illustrations or progress confetti.
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

Primary button: ink background, background-colored label. In dark mode this inverts naturally via semantic colors.

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
| Storage ring | `.easeOut(duration: 0.8)` trim |
| Screen content | `.snappy` opacity + 8 pt rise |
| Selection | `.snappy(duration: 0.22)` scale 0.97 → 1 |
| Scanning stage text | `.contentTransition(.opacity)` |
| Swipe card | interactive spring, threshold 34% width |

Reduce Motion: disable the rise and ring animation; keep opacity.

## Haptics

- Selection: `UISelectionFeedbackGenerator`.
- Successful cleanup: `UINotificationFeedbackGenerator.success`.
- Destructive confirmation: `.warning`.
- Never on scroll or launch.

## Components (`Sift/Design/Components.swift`)

`Card`, `SectionHeader`, `StorageRing`, `PrimaryButton`, `SecondaryButton`, `CategoryRow`, `MediaThumbnail`, `SelectionBadge`, `EmptyState`, `PermissionState`, `StatPill`, `ScreenTitle`.

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
