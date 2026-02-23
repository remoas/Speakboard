#!/bin/bash
set -e

APP_NAME="Speakboard"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="Speakboard-Installer"
VERSION="1.0"

# First build the app
echo "========================================"
echo "Building Speakboard for Distribution"
echo "========================================"
echo ""

./build-app.sh

echo ""
echo "Creating styled DMG installer..."

# Clean up any existing DMG
rm -f "$DMG_NAME.dmg"

# Use create-dmg for a proper installer look
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

# Get file size
DMG_SIZE=$(ls -lh "$DMG_NAME.dmg" | awk '{print $5}')

echo ""
echo "========================================"
echo "Distribution package ready!"
echo "========================================"
echo ""
echo "DMG file: $DMG_NAME.dmg"
echo "Size: $DMG_SIZE"
echo ""
echo "This file is ready to upload to your website."
echo ""
