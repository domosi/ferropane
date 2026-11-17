#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# Build release FerroPane.app bundle
./scripts/run_macos_no_xcode.sh --ci

APP_BUNDLE="$ROOT_DIR/build/FerroPane.app"
DIST_DIR="$ROOT_DIR/build/dist"
DMG_STAGING="$ROOT_DIR/build/dmg_staging"

rm -rf "$DIST_DIR" "$DMG_STAGING"
mkdir -p "$DIST_DIR" "$DMG_STAGING"

echo "==> Creating FerroPane-macos-arm64.zip..."
ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$DIST_DIR/FerroPane-macos-arm64.zip"

echo "==> Creating FerroPane-macos-arm64.dmg..."
cp -R "$APP_BUNDLE" "$DMG_STAGING/FerroPane.app"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create \
  -volname "FerroPane" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DIST_DIR/FerroPane-macos-arm64.dmg"

rm -rf "$DMG_STAGING"

echo "==> Generating SHA256SUMS.txt..."
(cd "$DIST_DIR" && shasum -a 256 FerroPane-macos-arm64.dmg FerroPane-macos-arm64.zip > SHA256SUMS.txt)

echo "==> Release artifacts ready in $DIST_DIR:"
ls -lh "$DIST_DIR"
