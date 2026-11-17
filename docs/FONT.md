# Neo Grotesque

Sift uses **Neo Grotesque-P5M5** for all app and web type. The typeface is supplied by ModernAmusement (Shady Nathan Tawfik) and is **not** covered by Sift's MIT license. It is included at the owner's direction so the app and the site share one voice.

## Files

| File | Source | Use |
| --- | --- | --- |
| `Sift/Resources/Fonts/SiftNeo-P5M5.ttf` | `Neo Grotesque-P5M5.ttf` | every app text style |
| `docs/fonts/SiftNeo-P5M5.ttf` / `.woff2` | the same cut | the landing page |
| `docs/index.html` | `@font-face` → `fonts/SiftNeo-P5M5.woff2` | the site |

The app registers the file through `UIAppFonts` in `Sift/Info.plist` (generated from `project.yml`). There is deliberately **one face**: hierarchy comes from size, colour and tracking, as on the ModernAmusement site. Tabular figures (`tnum`) are present, so `.monospacedDigit()` lines stay aligned. The web `@font-face` declares `font-weight: 100 900` against the same P5M5 file, so the browser never substitutes a different cut.

## Replacing the font

Drop a new `.ttf` into `Sift/Resources/Fonts/`, update `UIAppFonts`, update the PostScript name in `Typo` (`Sift/Design/Theme.swift`), refresh `docs/fonts/`, then regenerate:

```bash
xcodegen generate
```
