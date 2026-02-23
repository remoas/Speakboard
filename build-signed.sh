#!/bin/bash
set -e

APP_NAME="Speakboard"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="Speakboard-Installer"
SIGNING_IDENTITY="Developer ID Application: BEN LUKE SPINK (KWYFM8BDV5)"
TEAM_ID="KWYFM8BDV5"

echo "========================================"
echo "Building Signed Speakboard"
echo "========================================"

# Build the app
echo "Building..."
swift build -c release

# Create app bundle
echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp ".build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
cp "Info.plist" "$APP_BUNDLE/Contents/"
cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Sign the app with Developer ID and entitlements
echo "Signing with Developer ID..."
codesign --force --options runtime --entitlements "Speakboard.entitlements" --sign "$SIGNING_IDENTITY" "$APP_BUNDLE"

# Verify signature
echo "Verifying signature..."
codesign --verify --verbose "$APP_BUNDLE"

echo ""
echo "App signed successfully!"
echo ""

# Create DMG
echo "Creating DMG..."
rm -f "$DMG_NAME.dmg"

create-dmg \
    --volname "Speakboard" \
    --volicon "Resources/AppIcon.icns" \
    --background "Resources/dmg-background.png" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 80 \
    --icon "$APP_BUNDLE" 480 190 \
    --hide-extension "$APP_BUNDLE" \
    --app-drop-link 180 190 \
    --no-internet-enable \
    "$DMG_NAME.dmg" \
    "$APP_BUNDLE"

# Sign the DMG
echo "Signing DMG..."
codesign --force --sign "$SIGNING_IDENTITY" "$DMG_NAME.dmg"

echo ""
echo "========================================"
echo "Ready for notarization!"
echo "========================================"
echo ""
echo "To notarize, you need an app-specific password from appleid.apple.com"
echo "Then run:"
echo ""
echo "  xcrun notarytool submit $DMG_NAME.dmg --apple-id benlukespink@gmail.com --team-id $TEAM_ID --password YOUR_APP_PASSWORD --wait"
echo ""
echo "After notarization completes:"
echo "  xcrun stapler staple $DMG_NAME.dmg"
echo ""
