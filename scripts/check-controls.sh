#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT
args=(-target "$(uname -m)-apple-macos13" -module-cache-path "$PWD/.build/clang-module-cache")
mkdir -p "$PWD/.build/clang-module-cache"
swiftc "${args[@]}" -module-name ScreenCleanerCore -emit-module -emit-library -static \
  -o "$build_dir/libScreenCleanerCore.a" Sources/ScreenCleanerCore/*.swift
swiftc "${args[@]}" -I "$build_dir" -L "$build_dir" -lScreenCleanerCore \
  Sources/ScreenCleaner/CleaningHotKeyMonitor.swift \
  Sources/ScreenCleaner/CleanerControlsController.swift \
  Sources/ScreenCleaner/CleanerPreferencesWindowController.swift \
  Tests/ScreenCleanerAppTests/ControlsCheck.swift -o "$build_dir/controls-check"
"$build_dir/controls-check" | tee "$build_dir/result"
rg -q '^PASS: [0-9]+ native controls checks$' "$build_dir/result"
