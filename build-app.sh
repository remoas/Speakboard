#!/bin/bash
set -e

# Build the app
echo "Building Speakboard..."
swift build -c release

# Create app bundle structure
APP_NAME="Speakboard"
APP_BUNDLE="$APP_NAME.app"
BUILD_DIR=".build/release"
BUNDLE_ID="com.benspink.Speakboard"

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# Copy Info.plist
cp "Info.plist" "$APP_BUNDLE/Contents/"

# Copy app icon
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
    echo "App icon copied"
fi

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Sign the app with ad-hoc signature
echo "Signing app bundle..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo ""
echo "================================================"
echo "App bundle created: $APP_BUNDLE"
echo "================================================"
echo ""
echo "To run: open $APP_BUNDLE"
echo ""
echo "Hold Option (⌥) to record, release to transcribe!"
echo ""
