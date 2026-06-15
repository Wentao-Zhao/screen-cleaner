#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/dist/ScreenCleaner.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/clang-module-cache}"
mkdir -p "$CLANG_MODULE_CACHE_PATH"

BUILD_ARGS=(-c release)
if [[ -n "${SCREEN_CLEANER_SDK:-}" ]]; then
    BUILD_ARGS+=(--sdk "$SCREEN_CLEANER_SDK")
fi

cd "$ROOT_DIR"
swift build "${BUILD_ARGS[@]}"
BIN_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"

install -m 755 "$BIN_DIR/ScreenCleaner" "$MACOS_DIR/ScreenCleaner"
install -m 644 "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

codesign --force --sign - "$APP_DIR"

echo "Created: $APP_DIR"

