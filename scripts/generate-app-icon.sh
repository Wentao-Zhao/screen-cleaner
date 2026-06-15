#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SDK="${SCREEN_CLEANER_SDK:-$(xcrun --show-sdk-path)}"
WORK_DIR="$(mktemp -d)"
ICONSET_DIR="$WORK_DIR/AppIcon.iconset"
GENERATOR="$WORK_DIR/generate-app-icon"
MASTER_PNG="$WORK_DIR/AppIcon-1024.png"

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "$ROOT_DIR/.build/clang-module-cache" "$ICONSET_DIR"

swiftc \
    -sdk "$SDK" \
    -module-cache-path "$ROOT_DIR/.build/clang-module-cache" \
    "$ROOT_DIR/scripts/generate-app-icon.swift" \
    -o "$GENERATOR"

"$GENERATOR" "$MASTER_PNG"

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

iconutil -c icns "$ICONSET_DIR" -o "$ROOT_DIR/Resources/AppIcon.icns"

echo "Created: $ROOT_DIR/Resources/AppIcon.icns"

