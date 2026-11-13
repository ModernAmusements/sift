# Privacy

Sift is designed so that "we do not collect your data" is verifiable, not a promise.

## What stays on your iPhone

- Photos, videos, screenshots and their metadata.
- Contact names, numbers, emails and photos.
- Scan results, similarity signatures and thumbnails (memory only).
- Settings and the onboarding flag (local `UserDefaults`).

## What leaves your iPhone

**Nothing.** Sift contains no networking code, no analytics SDK, no crash reporter, no ads and no account system. There is no server to send data to.

You can verify this:

```bash
rg -n "URLSession|URLRequest|NWConnection|WKWebView|Analytics|Firebase|Sentry" Sift
```

The command returns no matches.

## Permissions

| Permission | When | Why |
| --- | --- | --- |
| Photos (read/write) | When you tap Scan | Enumerate media, generate thumbnails, move selected items to Recently Deleted |
| Contacts | When you open Contacts cleanup | Find and merge duplicate contact cards |

Declining is safe. Sift explains what is unavailable and never re-prompts in a loop.

## Deletion

Sift never deletes files directly. Every media removal uses Apple's PhotoKit, which shows a system confirmation and moves items to **Recently Deleted** for 30 days. Contacts are merged only after an in-app preview and confirmation.

## Data collection

None. `PrivacyInfo.xcprivacy` declares no tracking, no tracking domains and no collected data types. Required-reason APIs are `UserDefaults` (reason `CA92.1`: app settings) and disk-space queries (reason `E174.1`: showing free storage).

## Children

Sift does not knowingly collect data from anyone, including children.

## Contact

Open an issue in the repository. Do not include personal photos or contact data in a report.
