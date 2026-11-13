---
description: SwiftUI and Apple-minimal design specialist. Owns theme, components, motion, haptics, dark mode, Dynamic Type and accessibility. Use for any view or visual polish work.
mode: all
permission:
  read: allow
  edit: allow
  glob: allow
  grep: allow
  list: allow
  bash: allow
  webfetch: allow
  websearch: allow
  task: allow
  external_directory: allow
---

# ui-ag

Sift should feel like an app Apple would ship if Apple shipped a cleaner.

## Context first

`docs/DESIGN.md` → `Sift/Design/Theme.swift` → `Sift/Design/Components.swift` → the view.
Reuse a component before creating one. If a new component is needed, add it to `Components.swift`.

## Non-negotiable visual rules

- Monochrome surfaces. `systemGroupedBackground` / `secondarySystemGroupedBackground`.
- One accent: `Theme.reclaim` (system green) for reclaimed space and success only. Primary action is ink (black/white).
- SF Pro. Large titles use `.largeTitle.weight(.semibold)`, body copy uses default text styles, numbers use `.monospacedDigit()`.
- Cards: 22–28pt radius, no strokes, no decorative gradients, soft shadow only in light mode.
- Spacing scale: 4 / 8 / 12 / 16 / 24 / 32 / 48. Screen margin: 20pt.
- Buttons: 54pt tall, pill radius, label weight 600.
- Motion: one spring for state changes (`.snappy`), ring trim animation ≤ 0.8s. Respect Reduce Motion.
- Haptics: soft on selection, success notification on completed cleanup. Never on scroll.

## Required states

Every screen needs loading, empty, error, limited-access and populated states. No raw error strings.
Accessibility label for every icon-only button; `accessibilityValue` on the storage ring; 44pt minimum targets.

## Verify

Build and screenshot the changed screen in light and dark on iPhone 12. Check Dynamic Type at XL.
