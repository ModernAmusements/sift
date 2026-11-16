# Decisions

| # | Decision | Why |
| --- | --- | --- |
| D1 | Native SwiftUI app, not a web app | A cleaner needs PhotoKit/Contacts access; only a native app can deliver the real feature. |
| D2 | iPhone 12 / iOS 17 minimum | Wide install base, modern SwiftUI and Observation; matches the target folder. |
| D3 | Monochrome design with one green accent | Apple-minimal; green is reserved for reclaimed space so it carries meaning. |
| D4 | No third-party dependencies | Auditability, tiny binary, no supply-chain or tracking risk. |
| D5 | PhotoKit-only deletion | Only sanctioned path; Recently Deleted is the safety net. |
| D6 | dHash + Vision feature print, no Core ML model | No model shipping/licensing, fast, explainable, good enough. Same-day bucketing keeps it fast and accurate. |
| D7 | Contacts merge on shared handles only | Name-only matches are unsafe; shared phone/email is evidence. |
| D8 | Report size as "size unavailable" when KVC size fails | Honesty over a guess. |
| D9 | No contact permission at launch | Ask at the moment of use; lower friction and better consent. |
| D10 | MIT license | Maximum reuse; "we are good people" in license form. |
| D11 | Red VS Code status bar via repo-local `.vscode/settings.json` | Editor chrome only. Clearly marks the Sift window so the wrong repo/window is never edited; no effect on the app, build or CI. |
| D12 | Ship against one pain point: "you cannot tell what is safe to lose, at the moment your phone fails" | Features are commodities in this category; the unowned job is removing the gamble under time pressure. |
| D13 | Slowness is diagnosed, never "fixed" | A full volume, Low Power Mode and thermal pressure are the only things an app can honestly observe; any RAM/cooling/battery claim is the dark pattern we refuse. |
| D14 | Differentiate on the last mile and measured proof, not on feature count | Every cleaner stops at Recently Deleted, where nothing is freed, and shows forecasts instead of measurements. A paid app cannot copy a real number without admitting its old one was a guess. |
| D15 | No app uninstaller, no "leftover app data" claim; explain the App Store cloud badge instead | iOS exposes neither another app's container nor an uninstall API. The badge is an Apple ID purchase record. Claiming otherwise would be a lie we cannot ship. |
| D16 | Space check-ins: snapshot the volume at launch and report the real delta | It is the only honest answer to "I deleted things and got nothing back", needs no permissions, no network and no per-app attribution. |
| D17 | Credit only what Sift moved, and only after a later measurement proves the gain | A phone that gained space for another reason must not become a Sift marketing number; `Freed so far: 0 bytes.` is the honest state after moving to Recently Deleted. Proven space stays proven (cumulative `Reclaimed`); only unproven attribution expires, after 45 days. |
| D18 | Accept `photos-redirect://` in one file, with the manual Photos path always on screen | The last mile is where every other cleaner stops, so it must work; the scheme is undocumented, so the fallback is copy, not code, and deleting `PhotosDeepLink.swift` removes the dependency. |
| D19 | Follow the Apple HIG 1:1: native navigation, SF Pro/SF Symbols, Liquid Glass on iOS 26 with a flat fallback on iOS 17–25 | The owner rejected the bespoke header as “not the new Apple UI”. Native large titles, toolbars and glass controls are what iOS 26 users expect; content cards stay opaque for legibility. |
| D20 | Never fake scan progress: indeterminate spinner until the first real measurement, then numeric-text percent | A 0% ring that sits still reads as a hang. A spinner is honest (“working, not measurable yet”); a percentage starts only when the engine has a number. Motion is gated by Reduce Motion. |
| D21 | Signing: team in `Config/Local.xcconfig`, one Apple Development identity, identity by name (never a pinned hash); trust handled once on-device | XcodeGen rewrites the project and drops GUI team choices; automatic signing rejects a pinned hash; duplicate same-name certificates caused the trust loop. The durable setup is one team, one certificate, one trust record. |
