# Calendar Generator — Mac/iOS App

Multiplatform SwiftUI app that wraps the calendar PDF generator. Pick a month and year, browse all 10 palettes as live previews, shuffle the floral arrangement, import your own background, tap one to see it full size and save or share the PDF.

## Open

```bash
open CalendarApp.xcodeproj
```

Build targets:
- **My Mac** — runs as a regular Mac app
- **iPhone / iPad simulator or device** — same code

Bundle ID: `dollar2048.calendar-generator`. Team ID is read from the gitignored `Config/Signing.xcconfig` (see [Signing](#signing) below).

## Standalone Mac `.app`

Build a Release `.app` + zip ready to share:

```bash
./build_app.sh
# → dist/export/CalendarApp.app
# → dist/CalendarApp-macOS.zip
```

Output is a universal (arm64 + x86_64) macOS app, ~470 KB. Signed with the development certificate from the team configured in `Config/Signing.xcconfig`.

## Signing

The project's signing identity lives in `CalendarApp/Config/Signing.xcconfig`, which is **gitignored**. Your Apple Developer Team ID never gets committed.

First-time setup:

```bash
cp Config/Signing.template.xcconfig Config/Signing.xcconfig
$EDITOR Config/Signing.xcconfig   # set DEVELOPMENT_TEAM = ABCD1E2F3G
```

If you skip this, Xcode will prompt you to select a team in the **Signing & Capabilities** tab on first build.

CI builds disable signing entirely (`CODE_SIGN_IDENTITY=-`, `CODE_SIGNING_REQUIRED=NO`), so they don't need this file.

### Distribution caveats

- **Your own Macs**: launches normally.
- **Anyone else's Mac**: macOS Gatekeeper will refuse to open it because the developer cert is for development only. Workaround: right-click → Open → Open. Or run `xattr -cr CalendarApp.app` to drop the quarantine flag.
- **Public download (no warnings)**: requires a **Developer ID Application** certificate + notarization with `xcrun notarytool` + stapling with `xcrun stapler`. Hooks for that are marked `TODO` inside `build_app.sh`.

`dist/` is gitignored — distribute the zip via GitHub Releases, not by committing it to git.

## Features

- Gallery of all palettes generated on the fly (no precomputed assets shipped with the app).
- **Shuffle** re-rolls the procedural floral border into a new random arrangement.
- **Add your own** imports a background image (Photos on iOS, file picker on macOS) rendered full-bleed behind the grid.
- Month / year header in a single, sticky toolbar.
- PDF preview powered by PDFKit.
- macOS: **Save PDF…** writes to a chosen location via `NSSavePanel`.
- iOS: **Share PDF** opens the system share sheet.

## Project layout

```
CalendarApp/
├── CalendarApp.xcodeproj/
└── CalendarApp/
    ├── CalendarAppApp.swift           — @main entry
    ├── Models/
    │   ├── CalendarSpec.swift         — month/year value type
    │   └── Palette.swift              — 10 palette definitions + CalendarBackground
    ├── Drawing/
    │   ├── PlatformBridge.swift       — UColor/UFont/UImage typealiases
    │   ├── BackgroundRenderer.swift   — procedural floral border (CGContext only)
    │   └── CalendarPDFRenderer.swift  — PDF + thumbnail rendering
    ├── Views/
    │   ├── GalleryView.swift          — month/year picker + grid
    │   ├── PaletteCard.swift          — async-rendered palette tile
    │   ├── DetailView.swift           — full PDF preview + save/share
    │   ├── PDFKitView.swift           — PDFKit bridge (NSView/UIView)
    │   └── ShareSheet.swift           — UIActivityViewController bridge (iOS)
    ├── Assets.xcassets                — AppIcon + AccentColor
    └── Preview Content/Preview Assets.xcassets
```

## Cross-platform notes

- All drawing routines target `CGContext` directly — no `NSBezierPath`/`UIBezierPath`. The same code runs on macOS and iOS.
- `PlatformBridge.swift` provides `UColor` / `UFont` / `UImage` typealiases so model and rendering code never branches on platform.
- `PDFKitView` and `ShareSheet` are the only views with `#if os(...)` branches.

## Renderers

The app's drawing logic mirrors the standalone scripts at the repo root (`generate_calendar_pdf.swift`, `generate_backgrounds.swift`). Changes to one should be ported to the other.
