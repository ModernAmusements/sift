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
