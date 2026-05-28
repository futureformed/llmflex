#!/usr/bin/env bash
# Build LLM Flex.app from the SPM release binary. No Xcode required.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="LLM Flex"
BUNDLE_ID="cc.holdtight.llmflex"
EXEC_NAME="LLMFlex"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/${APP_NAME}.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "→ swift build -c release"
swift build -c release --product "$EXEC_NAME"

BIN_PATH=$(swift build -c release --product "$EXEC_NAME" --show-bin-path)
EXEC_SRC="$BIN_PATH/$EXEC_NAME"
if [[ ! -x "$EXEC_SRC" ]]; then
  echo "✗ executable not found at $EXEC_SRC"
  exit 1
fi

echo "→ Assembling .app bundle"
rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"
cp "$EXEC_SRC" "$MACOS/$EXEC_NAME"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
  <key>CFBundleExecutable</key><string>${EXEC_NAME}</string>
  <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
  <key>CFBundleShortVersionString</key><string>0.0.1</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

ENT_FILE="$BUILD_DIR/adhoc.entitlements"
cat > "$ENT_FILE" <<'ENT'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.app-sandbox</key><false/>
  <key>com.apple.security.files.user-selected.read-write</key><true/>
</dict>
</plist>
ENT

echo "→ Ad-hoc codesign"
codesign --force --sign - --entitlements "$ENT_FILE" "$APP_DIR" 2>&1 | sed 's/^/   /'

echo "✓ Built $APP_DIR"
echo "  Launch: open '$APP_DIR'"
