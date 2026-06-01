#!/usr/bin/env bash
# Package build/LLM Flex.app into a distributable .dmg.
# Runs build.sh first, then wraps the .app in a compressed disk image with a
# drag-to-Applications symlink. No external tools — just hdiutil.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="LLM Flex"
BUILD_DIR="build"
APP_PATH="$BUILD_DIR/${APP_NAME}.app"

VERSION="${LLMFLEX_VERSION:-$(cat VERSION 2>/dev/null || echo 0.0.0)}"
VERSION="${VERSION#v}"

# Build the .app (build.sh reads the same VERSION resolution).
LLMFLEX_VERSION="$VERSION" ./build.sh

if [[ ! -d "$APP_PATH" ]]; then
  echo "✗ $APP_PATH not found — build.sh did not produce the app" >&2
  exit 1
fi

DMG_NAME="LLM-Flex-${VERSION}.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

echo "→ Staging DMG contents"
cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "→ Creating $DMG_PATH"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING" \
  -fs HFS+ \
  -format UDZO \
  -ov \
  "$DMG_PATH" >/dev/null

echo "✓ Built $DMG_PATH"
