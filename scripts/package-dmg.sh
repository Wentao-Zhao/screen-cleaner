#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/ScreenCleaner.app"
INFO_PLIST="$ROOT_DIR/Resources/Info.plist"
README_FILE="$ROOT_DIR/Resources/DMG-README.txt"

mkdir -p "$ROOT_DIR/.build" "$DIST_DIR"

STAGING_DIR="$(mktemp -d "$ROOT_DIR/.build/screen-cleaner-dmg.XXXXXX")"
cleanup() {
    rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

"$ROOT_DIR/scripts/package-app.sh"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
DMG_PATH="$DIST_DIR/ScreenCleaner-$VERSION.dmg"
TMP_DMG_PATH="$DIST_DIR/.ScreenCleaner-$VERSION.dmg.tmp.dmg"

ditto "$APP_DIR" "$STAGING_DIR/ScreenCleaner.app"
touch "$STAGING_DIR/ScreenCleaner.app"
ln -s /Applications "$STAGING_DIR/Applications"
install -m 644 "$README_FILE" "$STAGING_DIR/首次打开说明.txt"

rm -f "$TMP_DMG_PATH"
hdiutil create \
    -volname "屏幕清洁" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$TMP_DMG_PATH"

zsh "$ROOT_DIR/scripts/verify-dmg.sh" "$TMP_DMG_PATH"
mv -f "$TMP_DMG_PATH" "$DMG_PATH"
(
    cd "$DIST_DIR"
    shasum -a 256 "$(basename "$DMG_PATH")" > "$(basename "$DMG_PATH").sha256"
)
echo "Created: $DMG_PATH"
