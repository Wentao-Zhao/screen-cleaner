#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/dist/ScreenCleaner.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/clang-module-cache}"
mkdir -p "$CLANG_MODULE_CACHE_PATH"

BUILD_ARGS=(--disable-sandbox --cache-path "$ROOT_DIR/.build/swift-cache"
    --config-path "$ROOT_DIR/.build/swift-config" --security-path "$ROOT_DIR/.build/swift-security"
    -c release -debug-info-format none)
if [[ -n "${SCREEN_CLEANER_SDK:-}" ]]; then
    BUILD_ARGS+=(--sdk "$SCREEN_CLEANER_SDK")
fi

cd "$ROOT_DIR"
swift build "${BUILD_ARGS[@]}" --product ScreenCleaner
BIN_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"

SCREEN_CLEANER_SDK="${SCREEN_CLEANER_SDK:-}" "$ROOT_DIR/scripts/generate-app-icon.sh"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

install -m 755 "$BIN_DIR/ScreenCleaner" "$MACOS_DIR/ScreenCleaner"
install -m 644 "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
install -m 644 "$ROOT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$CONTENTS_DIR/Info.plist")"
SIGNING_IDENTITY="${SCREEN_CLEANER_SIGNING_IDENTITY:--}"

if [[ "$SIGNING_IDENTITY" == "-" ]]; then
    codesign \
        --force \
        --sign - \
        --identifier "$BUNDLE_ID" \
        --requirements "=designated => identifier \"$BUNDLE_ID\"" \
        "$APP_DIR"
else
    codesign \
        --force \
        --sign "$SIGNING_IDENTITY" \
        --options runtime \
        --timestamp \
        "$APP_DIR"
fi

codesign --verify --strict "$APP_DIR"
touch "$APP_DIR"
echo "Created: $APP_DIR"
