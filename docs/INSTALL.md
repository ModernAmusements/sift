# Install Sift

Sift 1.3.0 is a free, open-source iPhone app. It is **not on the App Store**, and there is no paid Apple Developer account behind it. That has one honest consequence: there is no one-tap App Store install, and no notarised EU web download. What exists is the source, a working unsigned build, and three real ways to install it.

## What you need

- An iPhone 12 or newer, iOS 17 or newer.
- For the unsigned IPA: a Mac or PC for the first setup, and a free Apple ID.
- About 5 minutes.

## Option A — Xcode (recommended)

This is the path the app is developed and tested on.

1. Install **Xcode 26** from the Mac App Store.
2. Clone and generate:

   ```bash
   git clone https://github.com/ModernAmusements/sift.git
   cd sift
   xcodegen generate
   open Sift.xcodeproj
   ```

3. Select the **Sift** scheme and your iPhone as the run destination.
4. Open **Signing & Capabilities**, pick your Personal Team. If none exists, add your Apple ID in Xcode → Settings → Accounts.
5. Press **Run**. On the phone, trust the developer once:
   **Einstellungen → Allgemein → VPN & Geräteverwaltung → Apple Development: … → Vertrauen**.
6. iOS 17–26: the app uses native Liquid Glass on iOS 26 and a flat fallback on earlier versions. No account, no network, no subscription.

A free Apple ID signs for **7 days**. Re-run from Xcode to renew. A paid Apple Developer account signs for a year.

## Option B — AltStore or SideStore (EU-friendly)

The release includes an **unsigned IPA**. AltStore Classic and SideStore re-sign it with your own Apple ID and install it over USB/Wi-Fi, without the App Store and without a paid developer account. This works in the EU and elsewhere.

1. Install [AltStore Classic](https://altstore.io) or [SideStore](https://sidestore.io) and complete its one-time setup with your Apple ID.
2. Install Sift in one tap from the site:
   [Open in AltStore](altstore://install?url=https://modernamusements.github.io/sift/Sift-1.3.0-unsigned.ipa) ·
   [Download the IPA](https://modernamusements.github.io/sift/Sift-1.3.0-unsigned.ipa)
3. Or add the source for automatic updates:
   `altstore://source?url=https://modernamusements.github.io/sift/source.json`
4. In AltStore: **My Apps → + → Sift-1.3.0-unsigned.ipa**. In SideStore: **Apps → + → choose the IPA**.
5. Trust the developer certificate the same way as above.
6. Refresh from the same app every 7 days with a free Apple ID (automatic refresh is available while on the same Wi-Fi).

The source JSON and the currently published IPA are both served from this site (`source.json`, `Sift-1.3.0-unsigned.ipa`). Regenerate the IPA with `./scripts/make-ipa.sh` after a build change, then update the `versions` entry in `source.json`.

Verify the download if you like:

```bash
shasum -a 256 Sift-1.3.0-unsigned.ipa
# ed0e00b789e14d3150b8aa0a9f9a79ed12d23ce21e16bb205b15c57555d82de8
```

## Option C — EU alternative distribution

The EU Digital Markets Act allows alternative app marketplaces and web distribution, but Apple still requires the developer to join the paid Apple Developer Program, pass notarisation and meet Apple's distribution criteria. Sift is an MIT project without that account, so it is not listed in an EU marketplace or notarised for web distribution. The IPA above is the honest, auditable alternative: it is unsigned, you sign it with your own account, and the source is public.

## Why this is safe

- The complete source is in the same repository. Every build can be reproduced with Xcode 26.
- The app has **no networking code**. Photos and contacts never leave the phone.
- The privacy manifest declares no tracking and no collected data.
- The release IPA is built from the tagged source with `CODE_SIGNING_ALLOWED=NO`; it contains no developer certificate or profile.

## Troubleshooting

- **"Untrusted Developer"**: trust the certificate in Settings as described above.
- **App stops opening after a week**: the free certificate expired. Re-sign from Xcode or AltStore.
- **Photos access denied**: Settings → Privacy & Security → Photos → Sift → Full Access. Sift explains this on the home screen.
- **Nothing is freed after deleting**: photos move to Recently Deleted. Open Photos → Albums → Utilities → Recently Deleted → Select → Delete All. Sift then measures and verifies the real gain.
