#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# Build release FerroPane.app bundle (signed with Developer ID if available)
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

SIGN_IDENTITY="${APPLE_SIGNING_IDENTITY:-$(security find-identity -v -p codesigning | grep -o '"Developer ID Application:[^"]*"' | head -n 1 | tr -d '"' || true)}"

if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "==> Signing FerroPane-macos-arm64.dmg with Developer ID: $SIGN_IDENTITY..."
  codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DIST_DIR/FerroPane-macos-arm64.dmg"

  if [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
    echo "==> Submitting FerroPane-macos-arm64.dmg to Apple Notary Service (CI env credentials)..."
    xcrun notarytool submit "$DIST_DIR/FerroPane-macos-arm64.dmg" \
      --apple-id "$APPLE_ID" \
      --team-id "$APPLE_TEAM_ID" \
      --password "$APPLE_APP_SPECIFIC_PASSWORD" \
      --wait
    echo "==> Stapling notarization ticket to FerroPane-macos-arm64.dmg..."
    xcrun stapler staple "$DIST_DIR/FerroPane-macos-arm64.dmg"
    xcrun stapler validate "$DIST_DIR/FerroPane-macos-arm64.dmg"
  elif xcrun notarytool history --keychain-profile "ferropane-notary" >/dev/null 2>&1; then
    echo "==> Submitting FerroPane-macos-arm64.dmg to Apple Notary Service (Keychain profile: ferropane-notary)..."
    xcrun notarytool submit "$DIST_DIR/FerroPane-macos-arm64.dmg" \
      --keychain-profile "ferropane-notary" \
      --wait
    echo "==> Stapling notarization ticket to FerroPane-macos-arm64.dmg..."
    xcrun stapler staple "$DIST_DIR/FerroPane-macos-arm64.dmg"
    xcrun stapler validate "$DIST_DIR/FerroPane-macos-arm64.dmg"
  fi
fi

echo "==> Generating SHA256SUMS.txt..."
(cd "$DIST_DIR" && shasum -a 256 FerroPane-macos-arm64.dmg FerroPane-macos-arm64.zip > SHA256SUMS.txt)

echo "==> Release artifacts ready in $DIST_DIR:"
ls -lh "$DIST_DIR"
