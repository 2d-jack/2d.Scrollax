#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

EXECUTABLE_NAME="Scrollax"
BUNDLE_NAME="2d.Scrollax"
BUILD_DIR=".build/app"
APP_BUNDLE="$BUILD_DIR/$BUNDLE_NAME.app"

echo "==> Building release binary"
swift build -c release

echo "==> Assembling app bundle"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp ".build/release/$EXECUTABLE_NAME" "$APP_BUNDLE/Contents/MacOS/$EXECUTABLE_NAME"
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo "==> Generating app icon"
ICONSET="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"
CROPPED="$BUILD_DIR/icon-cropped.png"
ICON_PNG="$BUILD_DIR/icon-1024.png"
sips -c 1536 1536 "Resources/AppIcon-source.png" --out "$CROPPED" >/dev/null
sips -z 1024 1024 "$CROPPED" --out "$ICON_PNG" >/dev/null
sips -z 16 16     "$ICON_PNG" --out "$ICONSET/icon_16x16.png"      >/dev/null
sips -z 32 32     "$ICON_PNG" --out "$ICONSET/icon_16x16@2x.png"   >/dev/null
sips -z 32 32     "$ICON_PNG" --out "$ICONSET/icon_32x32.png"      >/dev/null
sips -z 64 64     "$ICON_PNG" --out "$ICONSET/icon_32x32@2x.png"   >/dev/null
sips -z 128 128   "$ICON_PNG" --out "$ICONSET/icon_128x128.png"    >/dev/null
sips -z 256 256   "$ICON_PNG" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$ICON_PNG" --out "$ICONSET/icon_256x256.png"    >/dev/null
sips -z 512 512   "$ICON_PNG" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$ICON_PNG" --out "$ICONSET/icon_512x512.png"    >/dev/null
cp "$ICON_PNG" "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Building disk image"
DMG_STAGING="$BUILD_DIR/dmg-staging"
DMG_PATH="$BUILD_DIR/$BUNDLE_NAME.dmg"
rm -rf "$DMG_STAGING"
rm -f "$DMG_PATH"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create -volname "$BUNDLE_NAME" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_PATH" >/dev/null

echo "==> Done: $APP_BUNDLE"
echo "    $DMG_PATH"
echo "    Open the .dmg and drag the app into Applications, or run:"
echo "    open \"$APP_BUNDLE\""
