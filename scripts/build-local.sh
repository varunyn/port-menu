#!/bin/zsh

set -euo pipefail

PROJECT="${PROJECT:-Porter.xcodeproj}"
SCHEME="${SCHEME:-Porter}"
CONFIGURATION="${CONFIGURATION:-Debug}"
APP_NAME="${APP_NAME:-Port Menu}"

# Derive the first Apple Development certificate from the keychain
CERT_IDENTITY=$(security find-identity -v -p basic 2>/dev/null \
  | grep "Apple Development" \
  | head -1 \
  | awk '{print $2}')

if [[ -z "$CERT_IDENTITY" ]]; then
  echo "No Apple Development certificate found in keychain."
  echo "Run: security find-identity -v -p basic"
  exit 1
fi

BUILD_DIR=$(xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -showBuildSettings 2>/dev/null \
  | grep "CONFIGURATION_BUILD_DIR" \
  | awk '{print $3}')

rm -rf "$BUILD_DIR/$APP_NAME.app"

echo "Building $APP_NAME..."
xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "platform=macOS" \
  CODE_SIGNING_ALLOWED=NO

APP_PATH="$BUILD_DIR/$APP_NAME.app"

echo "Signing with certificate: $CERT_IDENTITY"

# Sign every dylib in the bundle
find "$APP_PATH" -name "*.dylib" -exec codesign --force --sign "$CERT_IDENTITY" --options runtime {} \; 2>/dev/null

# Sign XPC services and app bundles nested inside frameworks
find "$APP_PATH" -name "*.xpc" -exec codesign --force --sign "$CERT_IDENTITY" --options runtime --timestamp {} \; 2>/dev/null
find "$APP_PATH" -path "*/Sparkle.framework/*" -name "Autoupdate" -type f -exec codesign --force --sign "$CERT_IDENTITY" --options runtime --timestamp {} \; 2>/dev/null
find "$APP_PATH" -path "*/Sparkle.framework/*" -name "Updater" -type f -exec codesign --force --sign "$CERT_IDENTITY" --options runtime --timestamp {} \; 2>/dev/null
find "$APP_PATH" -path "*/Sparkle.framework/*" -name "*.app" -depth -exec codesign --force --sign "$CERT_IDENTITY" --options runtime --timestamp {} \; 2>/dev/null

# Sign Sparkle framework itself
codesign --force --sign "$CERT_IDENTITY" --options runtime --timestamp "$APP_PATH/Contents/Frameworks/Sparkle.framework" 2>/dev/null

# Sign main app bundle
codesign --force --sign "$CERT_IDENTITY" --options runtime --timestamp "$APP_PATH"

echo "Installing to /Applications..."
rm -rf "/Applications/$APP_NAME.app"
ditto "$APP_PATH" "/Applications/$APP_NAME.app"

echo "Launching $APP_NAME..."
open "/Applications/$APP_NAME.app"
