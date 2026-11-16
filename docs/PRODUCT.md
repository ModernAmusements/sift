# Sift — product definition

> **Keep the moments. Lose the clutter.**

Sift is a free, open-source iPhone cleaner. It finds the things people actually regret keeping — screenshots, near-duplicate shots, blurry photos, huge videos, and duplicate contacts — and removes them through Apple's own safety net.

## The pain point

**The moment the phone fails.**

Not "clutter". The pain arrives as one event: the shutter will not fire, the app you need hangs, the iOS update refuses to install — usually while something is happening in front of you that will not wait.

Two things make that moment bad instead of annoying:

1. **The only fix on offer is deleting something you are not sure you can lose.** Photos are the one dataset where a wrong tap is permanent in the only sense that matters. Under time pressure people either delete nothing — and the phone keeps failing — or delete the wrong thing.
2. **The tools lie.** Every cleaner shows an urgent number ("12.4 GB of junk"), takes a card for a weekly subscription, and afterwards the free-space bar barely moves, because deletions land in Recently Deleted, where nothing is freed.

Slowness is the same story with a worse lie attached. A full phone really does get slower — iOS needs working space and room to install updates — but no app can "boost RAM", cool the CPU, clean system cache or save battery, and every cleaner claiming it is the dark pattern Sift exists to refuse.

So the pain Sift fixes is not "too many photos". It is: **you cannot tell what is safe to lose, at the one moment you need to know fast.**

## The promise

| Sift does | Sift does not |
| --- | --- |
| Scan your photo library on-device | Upload anything to a server |
| Group similar shots and recommend the best | Auto-delete without confirmation |
| Find screenshots, blurry photos, large files | Claim to clear other apps' caches |
| Merge duplicate contacts | "Boost RAM", "cool down" or "save battery" |
| Show device storage truthfully | Sell subscriptions, ads or data |
| Delete via PhotoKit → Recently Deleted | Touch the file system directly |
| Measure the space actually freed and prove it | Guess a number and call it cleaning |
| Diagnose slowness from what iOS exposes | Promise a speed, RAM or battery boost |
| Show the real free-space delta since your last visit | Claim to remove another app completely |

## Slowness: diagnose, never boost

Sift may state only what is honest and checkable:

- Free space and headroom. iOS needs working room; a full volume is slower, blocks camera capture and blocks updates.
- Low Power Mode (`ProcessInfo.isLowPowerModeEnabled`).
- Thermal pressure (`ProcessInfo.thermalState` serious or critical).
- Uptime since boot, device model, iOS version.
- Battery health: a deep link into Settings → Battery only. There is no public API, so never state a percentage.

Sift never says: boost RAM, clean system cache, cool down, optimize CPU, extend battery. The System data screen explains the same limits and links to Apple's own settings.

## Space accounting: "I deleted 40 apps and got 3 GB back"

This is the same pain as the last mile, wearing different clothes: the user acted, expected a result, and cannot verify what happened. It is the most common reason people conclude that *nothing* on iOS works.

What is actually true, and what Sift may therefore never promise:

- iOS gives no third-party app any view of another app's container, and no public API to uninstall apps or delete their data. An "app uninstaller" is not a feature we are choosing not to build — it is impossible. Offloading and deleting stay in Settings.
- The cloud badge in the App Store after deletion is **your Apple ID purchase record**, not leftover files on the phone. No app can remove it and neither can Apple; purchases can only be hidden in the App Store account screen. Sift explains this instead of pretending to purge it.
- Space that genuinely lingers after an uninstall: iCloud Backup (the removed app's data survives in older backups until they roll over), Recently Deleted for photos and files, keychain items, and System Data that iOS purges on its own schedule.

What Sift does about it: **free-space check-ins.** A local snapshot of the volume at each launch, compared with the previous one, so the app can say "3.2 GB came back since Tuesday" and honestly explain where the rest went. No per-app attribution, no "deep clean", no invented leftovers.

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

## v1.2 — Check-in

See [`SPEC-V1.2.md`](SPEC-V1.2.md): Check-in → Diagnose → Clean → Prove. Real free-space deltas since the last visit, honest readings of the only causes iOS exposes, and the last mile through Recently Deleted with a measured result. Implemented; release pending a device pass.

## Out of scope for v1

- Any "speed", RAM, cooling or battery optimisation feature. iOS does not allow it; diagnosis and hand-off only.
- An app uninstaller or "residual app data" cleaner. No public API exists; other apps' containers are unreadable by design.
- Removing the App Store cloud badge on a deleted app. It is an account purchase record, not device storage.
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
