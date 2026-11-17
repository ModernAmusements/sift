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

`docs/DESIGN.md` → `Sift/Design/Theme.swift` → the view.
Reuse a component before creating one; components live in `Theme.swift` (there is no `Components.swift`).

## Non-negotiable visual rules

- Apple HIG 1:1 is the reference, not a custom brand skin. Native navigation, toolbars, lists and controls.
- Black-and-white surfaces (`#F5F5F7`/white light, black/`#1C1C1E` dark); no peach, no green.
- One accent: orange `#FF6600` for the primary action, storage ring, selection and success. The primary button label is near-black `#0A0A0A` (6:1).
- **Neo Grotesque-P5M5** for every text style — one bundled face. Hierarchy comes from size/colour/tracking. SF Symbols only for icons.
- iOS 26: Liquid Glass (`glassEffect`, SwiftUICore, availability-gated) on primary/secondary buttons, toolbar controls, the scan panel and the selection bar; content cards stay opaque. iOS 17–25 keep flat fills.
- Home uses an inline navigation bar with the **Sift lockup** as principal item and the system glass gear; pushed screens keep standard titles. No editorial index/chapter layout.
- Cards: 22–28pt radius, flat fill, no strokes, no shadows, no decorative gradients.
- Spacing scale: 4 / 8 / 12 / 16 / 24 / 32 / 48. Screen margin: 20pt.
- Buttons: 54pt tall, pill radius, label weight 600.
- Motion: one spring for state changes (`.snappy`), numeric-text transitions on measurements, proof symbol bounce, ring trim ≤ 0.8s. Respect Reduce Motion (no scale/bounce/rise).
- Scrolling: `.scrollBounceBehavior(.basedOnSize)`; indicators hidden on editorial screens only.
- Haptics: light impact on button press, soft selection, success notification on completed cleanup. Never on scroll.
- Adaptive: use `ViewThatFits` with an explicit `minWidth` or `dynamicTypeSize` checks; flexible `Text` alone never makes it switch. Test 320pt width (Display Zoom) and accessibility XXXL.

## Required states

Every screen needs loading, empty, error, limited-access and populated states. No raw error strings.
Accessibility label for every icon-only button; `accessibilityValue` on the storage ring; 44pt minimum targets.

## Verify

Build and screenshot the changed screen in light and dark on iPhone 12. Check Dynamic Type at XL.
