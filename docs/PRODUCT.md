# Sift — product definition

> **Keep the moments. Lose the clutter.**

Sift is a free, open-source iPhone cleaner. It finds the things people actually regret keeping — screenshots, near-duplicate shots, blurry photos, huge videos, and duplicate contacts — and removes them through Apple's own safety net.

## The problem

iPhone storage fills up with photos nobody chose: five versions of the same group shot, screenshots of train tickets, accidental 4K videos, contacts saved three times. Commercial cleaners charge weekly subscriptions for this, gate the useful part behind a paywall, and sometimes ship analytics SDKs that see your photo metadata.

## The promise

| Sift does | Sift does not |
| --- | --- |
| Scan your photo library on-device | Upload anything to a server |
| Group similar shots and recommend the best | Auto-delete without confirmation |
| Find screenshots, blurry photos, large files | Claim to clear other apps' caches |
| Merge duplicate contacts | "Boost RAM", "cool down" or "save battery" |
| Show device storage truthfully | Sell subscriptions, ads or data |
| Delete via PhotoKit → Recently Deleted | Touch the file system directly |

## Target user

Someone with a 64 GB or 128 GB iPhone who is out of storage, does not want a subscription, and cares where their photos go. They know their Photos app is a mess but not how much of it is junk.

## v1 scope

1. **Storage dashboard** — free/used space, library size, asset counts.
2. **Scan** — screenshots, exact duplicates, similar photos, blurry photos, large files, duplicate contacts. Cancellable, on-device, progress visible.
3. **Review** — grid with sizes, select/deselect, best-shot recommendation, bulk actions.
4. **Cleanup** — PhotoKit deletion with the system confirmation and Recently Deleted safety net.
5. **Large files** — photos and videos over 25 MB, sorted by size.
6. **Contacts** — merge duplicate cards, keep the richest record, delete the rest.
7. **Files & documents** — clean user-picked files from iCloud Drive or On My iPhone.
8. **Sift cache** — show and clear the app's own temporary data.
9. **System data guide** — explain what iOS does not allow third-party apps to clean.
10. **Swipe review** — fast keep/delete pass for screenshots and photos.
11. **Settings** — privacy statement, sensitivity, permission shortcuts, cache, open-source links.
12. **Onboarding** — honest explanation, permission request at the moment of use.

## Out of scope for v1

- Video compression/transcoding.
- Photo editing.
- iCloud optimisation controls (no public API).
- Live Photo → still conversion.
- Cleaning Safari, Mail, WhatsApp or other apps' containers (impossible on iOS).
- Scanning the whole Files app without user selection (not permitted).
- Android, web or Mac clients.

## Success measures

- A first-time user can scan and free space in under three minutes.
- Zero network requests at runtime.
- Every destructive action is reversible via Recently Deleted or a visible confirmation.
- Scan completes on a 10,000-asset library without jetsam and with usable progress.
- App launches and works with Photos access denied (explains how to enable it).

## Name

Sift: to pass through a sieve, to separate what matters from what does not. One syllable, verb and noun, no existing App Store conflict at time of writing. Repo: `sift`.
