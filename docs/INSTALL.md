# Install Sift

Sift 1.3.0 is a free, open-source iPhone app. It is **not on the App Store**, and there is no paid Apple Developer account behind it. That has one honest consequence: there is no one-tap App Store install, and no notarised EU web download. What exists is the source, a working unsigned build, and three real ways to install it.

## What you need

- An iPhone 12 or newer, iOS 17 or newer.
- A Mac or PC for the AltStore first setup, and a free Apple ID.
- About 5 minutes.

## Option A — AltStore (recommended)

[AltStore Classic](https://altstore.io) is a free, open-source installer for iPhone. It signs Sift with **your own Apple ID**, so the app can live on your phone without the App Store and without a paid developer account. It is not affiliated with Apple or with Sift.

1. Download AltStore from [altstore.io](https://altstore.io) and install **AltServer** on your Mac or PC.
2. Launch AltServer. Keep the iPhone and the computer on the same Wi-Fi and allow AltServer through the firewall.
3. In the AltServer menu bar, choose **Install AltStore → your iPhone** and sign in with your Apple ID (two-factor authentication works).
4. On the iPhone, install Sift:
   [Install Sift with AltStore](altstore://install?url=https://modernamusements.github.io/sift/Sift-1.3.0-unsigned.ipa) ·
   [Download the IPA](https://modernamusements.github.io/sift/Sift-1.3.0-unsigned.ipa)
5. Or add the source for automatic updates:
   `altstore://source?url=https://modernamusements.github.io/sift/source.json`
6. In AltStore: **My Apps → + → Sift-1.3.0-unsigned.ipa**.
7. Trust the developer certificate: **Einstellungen → Allgemein → VPN & Geräteverwaltung → Apple Development: … → Vertrauen**.
8. Refresh from AltStore every 7 days with a free Apple ID. AltStore renews through AltServer while the phone is on the same Wi-Fi; a paid account lasts a year.

**“AltServer could not be found”** means AltServer is not running, or the phone and computer are not on the same network. Launch AltServer, allow it through the macOS firewall, and retry. If the Wi-Fi isolates devices, connect the iPhone by USB and retry.

Verify the download if you like:

```bash
shasum -a 256 Sift-1.3.0-unsigned.ipa
# ed0e00b789e14d3150b8aa0a9f9a79ed12d23ce21e16bb205b15c57555d82de8
```

## Option B — Xcode

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

## Option C — SideStore (no AltServer after setup)

[SideStore](https://sidestore.io) uses the same unsigned IPA and your own Apple ID, but after a one-time pairing-file setup it can refresh on-device without AltServer. It is the better free choice if you do not want to keep a Mac or PC nearby every week.

1. Install SideStore and complete its one-time pairing setup.
2. Install the IPA: **Apps → + → Sift-1.3.0-unsigned.ipa**.
3. Trust the certificate as above.
4. Refresh on-device every 7 days.

The source JSON and the currently published IPA are both served from this site (`source.json`, `Sift-1.3.0-unsigned.ipa`). Regenerate the IPA with `./scripts/make-ipa.sh` after a build change, then update the `versions` entry in `source.json`.

## Option D — EU alternative distribution

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
