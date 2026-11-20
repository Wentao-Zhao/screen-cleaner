#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SDK="${SCREEN_CLEANER_SDK:-$(xcrun --show-sdk-path)}"
WORK_DIR="$(mktemp -d)"
ICONSET_DIR="$WORK_DIR/AppIcon.iconset"
MASTER_PNG="$ROOT_DIR/Resources/AppIcon.png"

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "$ROOT_DIR/.build/clang-module-cache" "$ICONSET_DIR"

if [[ ! -f "$MASTER_PNG" ]]; then
    print -u2 "Missing icon master: $MASTER_PNG"
    exit 1
fi

sips -z 16 16 "$MASTER_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$MASTER_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$MASTER_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$MASTER_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$MASTER_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$MASTER_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$MASTER_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$MASTER_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$MASTER_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
cp "$MASTER_PNG" "$ICONSET_DIR/icon_512x512@2x.png"

swiftc \
    -sdk "$SDK" \
    -module-cache-path "$ROOT_DIR/.build/clang-module-cache" \
    -parse-as-library \
    "$ROOT_DIR/Sources/ScreenCleaner/MenuBarIcon.swift" \
    "$ROOT_DIR/scripts/export-status-icon.swift" \
    -o "$WORK_DIR/export-status-icon"
"$WORK_DIR/export-status-icon" "$ROOT_DIR/Resources" "$ICONSET_DIR"

echo "Created: $ROOT_DIR/Resources/AppIcon.icns"

