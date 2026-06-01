#!/bin/bash
# Builds CalendarApp.app for macOS in Release config and writes a zip
# under dist/ ready for GitHub Releases.
#
# Notes on signing:
# - Reads your DEVELOPMENT_TEAM from CalendarApp/Config/Signing.xcconfig
#   (gitignored). The app is signed with a *development* certificate from
#   that team — works on your machines, may warn on others.
# - For unrestricted public distribution you need a Developer ID
#   certificate + notarization (xcrun notarytool). Hooks for that are
#   marked TODO below — we just produce a development build here.

set -euo pipefail

cd "$(dirname "$0")"

PROJECT="CalendarApp.xcodeproj"
SCHEME="CalendarApp"
CONFIG="Release"
DIST_DIR="dist"
ARCHIVE_PATH="$DIST_DIR/CalendarApp.xcarchive"
EXPORT_PATH="$DIST_DIR/export"
APP_PATH="$EXPORT_PATH/CalendarApp.app"
ZIP_PATH="$DIST_DIR/CalendarApp-macOS.zip"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

cat > "$DIST_DIR/ExportOptions.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
PLIST

echo "==> Archiving Release build…"
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    -destination 'generic/platform=macOS' \
    -archivePath "$ARCHIVE_PATH" \
    archive | tail -8

echo
echo "==> Exporting .app from archive…"
xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$DIST_DIR/ExportOptions.plist" | tail -8

if [[ ! -d "$APP_PATH" ]]; then
    echo "FAILED: $APP_PATH not produced." >&2
    exit 1
fi

echo
echo "==> Zipping for distribution…"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

# TODO (optional, for public distribution without Gatekeeper warnings):
# 1. Replace the development signing identity with a Developer ID
#    Application certificate.
# 2. Notarize:
#       xcrun notarytool submit "$ZIP_PATH" \
#           --keychain-profile "AC_NOTARY" --wait
# 3. Staple:
#       xcrun stapler staple "$APP_PATH"
#       ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo
echo "Done."
echo "  App : $APP_PATH"
echo "  Zip : $ZIP_PATH"
echo
echo "First launch on someone else's Mac: right-click the app → Open → Open"
echo "(Gatekeeper warns about unidentified developer until the app is notarized.)"
