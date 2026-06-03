#!/bin/bash
# Renders the 1024×1024 master AppIcon (via make_icon.swift), then resizes it
# to every iOS + macOS icon variant the asset catalog references and rewrites
# the AppIcon.appiconset/Contents.json accordingly.

set -euo pipefail

cd "$(dirname "$0")"

ICONSET="CalendarApp/Assets.xcassets/AppIcon.appiconset"
SOURCE="$ICONSET/AppIcon.png"

if [[ ! -f "$SOURCE" ]]; then
    echo "==> Generating master 1024 icon (make_icon.swift)…"
    swift make_icon.swift
fi

if [[ ! -f "$SOURCE" ]]; then
    echo "Failed to produce master icon at $SOURCE" >&2
    exit 1
fi

resize() {
    local size=$1
    local out=$2
    sips -z "$size" "$size" "$SOURCE" --out "$ICONSET/$out" >/dev/null
}

echo "==> Generating sized PNGs from ${SOURCE}…"
# iOS sizes
resize 40   icon-iphone-20@2x.png      # 20pt @2x = 40
resize 60   icon-iphone-20@3x.png      # 20pt @3x = 60
resize 58   icon-iphone-29@2x.png      # 29pt @2x = 58
resize 87   icon-iphone-29@3x.png      # 29pt @3x = 87
resize 80   icon-iphone-40@2x.png      # 40pt @2x = 80
resize 120  icon-iphone-40@3x.png      # 40pt @3x = 120
resize 120  icon-iphone-60@2x.png      # 60pt @2x = 120 (iPhone app)
resize 180  icon-iphone-60@3x.png      # 60pt @3x = 180 (iPhone app)
resize 20   icon-ipad-20.png
resize 40   icon-ipad-20@2x.png
resize 29   icon-ipad-29.png
resize 58   icon-ipad-29@2x.png
resize 40   icon-ipad-40.png
resize 80   icon-ipad-40@2x.png
resize 76   icon-ipad-76.png
resize 152  icon-ipad-76@2x.png        # iPad app
resize 167  icon-ipad-83.5@2x.png      # iPad Pro
resize 1024 icon-ios-marketing.png

# macOS sizes
resize 16   icon-mac-16.png
resize 32   icon-mac-16@2x.png
resize 32   icon-mac-32.png
resize 64   icon-mac-32@2x.png
resize 128  icon-mac-128.png
resize 256  icon-mac-128@2x.png
resize 256  icon-mac-256.png
resize 512  icon-mac-256@2x.png
resize 512  icon-mac-512.png
resize 1024 icon-mac-512@2x.png

echo "==> Writing Contents.json…"
cat > "$ICONSET/Contents.json" <<'JSON'
{
  "images" : [
    { "filename" : "icon-iphone-20@2x.png",  "idiom" : "iphone", "scale" : "2x", "size" : "20x20" },
    { "filename" : "icon-iphone-20@3x.png",  "idiom" : "iphone", "scale" : "3x", "size" : "20x20" },
    { "filename" : "icon-iphone-29@2x.png",  "idiom" : "iphone", "scale" : "2x", "size" : "29x29" },
    { "filename" : "icon-iphone-29@3x.png",  "idiom" : "iphone", "scale" : "3x", "size" : "29x29" },
    { "filename" : "icon-iphone-40@2x.png",  "idiom" : "iphone", "scale" : "2x", "size" : "40x40" },
    { "filename" : "icon-iphone-40@3x.png",  "idiom" : "iphone", "scale" : "3x", "size" : "40x40" },
    { "filename" : "icon-iphone-60@2x.png",  "idiom" : "iphone", "scale" : "2x", "size" : "60x60" },
    { "filename" : "icon-iphone-60@3x.png",  "idiom" : "iphone", "scale" : "3x", "size" : "60x60" },
    { "filename" : "icon-ipad-20.png",       "idiom" : "ipad",   "scale" : "1x", "size" : "20x20" },
    { "filename" : "icon-ipad-20@2x.png",    "idiom" : "ipad",   "scale" : "2x", "size" : "20x20" },
    { "filename" : "icon-ipad-29.png",       "idiom" : "ipad",   "scale" : "1x", "size" : "29x29" },
    { "filename" : "icon-ipad-29@2x.png",    "idiom" : "ipad",   "scale" : "2x", "size" : "29x29" },
    { "filename" : "icon-ipad-40.png",       "idiom" : "ipad",   "scale" : "1x", "size" : "40x40" },
    { "filename" : "icon-ipad-40@2x.png",    "idiom" : "ipad",   "scale" : "2x", "size" : "40x40" },
    { "filename" : "icon-ipad-76.png",       "idiom" : "ipad",   "scale" : "1x", "size" : "76x76" },
    { "filename" : "icon-ipad-76@2x.png",    "idiom" : "ipad",   "scale" : "2x", "size" : "76x76" },
    { "filename" : "icon-ipad-83.5@2x.png",  "idiom" : "ipad",   "scale" : "2x", "size" : "83.5x83.5" },
    { "filename" : "icon-ios-marketing.png", "idiom" : "ios-marketing", "scale" : "1x", "size" : "1024x1024" },

    { "filename" : "icon-mac-16.png",        "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "icon-mac-16@2x.png",     "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "icon-mac-32.png",        "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "icon-mac-32@2x.png",     "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "icon-mac-128.png",       "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "icon-mac-128@2x.png",    "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "icon-mac-256.png",       "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "icon-mac-256@2x.png",    "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "icon-mac-512.png",       "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "icon-mac-512@2x.png",    "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

echo "Done. Wrote $(ls "$ICONSET" | wc -l | tr -d ' ') files into $ICONSET"
