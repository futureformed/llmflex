#!/usr/bin/env bash
# Build LLM Flex.app from the SPM release binary. No Xcode required.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="LLM Flex"
BUNDLE_ID="cc.holdtight.llmflex"
EXEC_NAME="LLMFlex"
BUILD_DIR="build"

# Version: env override (CI passes the git tag) → VERSION file → fallback.
# Strip a leading "v" so a tag like v0.1.0 normalizes to 0.1.0.
VERSION="${LLMFLEX_VERSION:-$(cat VERSION 2>/dev/null || echo 0.0.0)}"
VERSION="${VERSION#v}"
# CFBundleVersion must be a monotonically increasing build number. Commit
# count is monotonic and reproducible; fall back to 1 outside a git checkout.
BUILD_NUMBER="$(git rev-list --count HEAD 2>/dev/null || echo 1)"
echo "→ Version ${VERSION} (build ${BUILD_NUMBER})"
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

# Copy SPM-generated resource bundles (one per target with resources) so
# Bundle.module can find files at runtime. SPM names them
# <PackageName>_<TargetName>.bundle.
for bundle in "$BIN_PATH"/*.bundle; do
  if [ -d "$bundle" ]; then
    echo "→ Bundling resources: $(basename "$bundle")"
    cp -R "$bundle" "$RESOURCES/"
  fi
done

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
  <key>CFBundleExecutable</key><string>${EXEC_NAME}</string>
  <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key><string>${BUILD_NUMBER}</string>
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
