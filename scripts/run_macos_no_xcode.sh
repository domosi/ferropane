#!/usr/bin/env zsh
set -euo pipefail

export PATH="$HOME/.cargo/bin:/opt/homebrew/bin:$PATH"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> [1/4] Building Rust Core (libtc_core.dylib)..."
(cd "$ROOT_DIR/rust" && cargo build --release)

echo "==> [2/4] Assembling Flutter macOS AOT Frameworks (no Xcode.app required)..."
flutter assemble \
  --output=build/macos_standalone \
  -dTargetPlatform=darwin \
  -dTrackWidgetCreation=true \
  -dBuildMode=release \
  -dDarwinArchs=arm64 \
  -dTreeShakeIcons=false \
  release_macos_bundle_flutter_assets

FLUTTER_ROOT="$(cd "$(dirname "$(realpath "$(which flutter)")")/.." && pwd)"
ENGINE_FW="$FLUTTER_ROOT/bin/cache/artifacts/engine/darwin-x64-release/FlutterMacOS.xcframework/macos-arm64_x86_64/FlutterMacOS.framework"
if [[ ! -d "$ROOT_DIR/build/macos_standalone/FlutterMacOS.framework" ]]; then
  cp -R "$ENGINE_FW" "$ROOT_DIR/build/macos_standalone/FlutterMacOS.framework"
fi

APP_BUNDLE="$ROOT_DIR/build/FerroPane.app"
rm -rf "$APP_BUNDLE" "$ROOT_DIR/build/TC-Mac.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Frameworks"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "==> [3/4] Compiling macOS AppKit Runner with CommandLineTools swiftc..."
SDK_PATH="$(xcrun --show-sdk-path)"
swiftc \
  -target arm64-apple-macosx14.0 \
  -sdk "$SDK_PATH" \
  -F "$ROOT_DIR/build/macos_standalone" \
  -framework FlutterMacOS \
  -framework Cocoa \
  -framework Quartz \
  -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
  "$ROOT_DIR/macos/Runner/AppDelegate.swift" \
  "$ROOT_DIR/macos/Runner/MainFlutterWindow.swift" \
  "$ROOT_DIR/macos/Flutter/GeneratedPluginRegistrant.swift" \
  -o "$APP_BUNDLE/Contents/MacOS/FerroPane"

echo "==> [4/4] Bundling Frameworks, Icon, Rust dylib, and signing FerroPane.app..."
cp -R "$ROOT_DIR/build/macos_standalone/App.framework" "$APP_BUNDLE/Contents/Frameworks/"
cp -R "$ROOT_DIR/build/macos_standalone/FlutterMacOS.framework" "$APP_BUNDLE/Contents/Frameworks/"
cp "$ROOT_DIR/rust/target/release/libtc_core.dylib" "$APP_BUNDLE/Contents/Frameworks/libtc_core.dylib"
if [[ -f "$ROOT_DIR/macos/Runner/AppIcon.icns" ]]; then
  cp "$ROOT_DIR/macos/Runner/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>FerroPane</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>com.domosi.ferropane</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>FerroPane</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.2.0</string>
	<key>CFBundleVersion</key>
	<string>3</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
EOF

SIGN_IDENTITY="${APPLE_SIGNING_IDENTITY:-$(security find-identity -v -p codesigning | grep -o '"Developer ID Application:[^"]*"' | head -n 1 | tr -d '"' || true)}"

if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "==> Signing FerroPane.app with Developer ID: $SIGN_IDENTITY (Hardened Runtime)..."
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_BUNDLE/Contents/Frameworks/libtc_core.dylib"
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_BUNDLE/Contents/Frameworks/FlutterMacOS.framework"
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_BUNDLE/Contents/Frameworks/App.framework"
  codesign --force --options runtime --timestamp --entitlements "$ROOT_DIR/macos/Runner/Release.entitlements" --sign "$SIGN_IDENTITY" "$APP_BUNDLE"
  codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
else
  echo "==> No Developer ID certificate found; ad-hoc signing FerroPane.app..."
  codesign --force --deep --sign - "$APP_BUNDLE"
fi

if [[ "${1:-}" == "--ci" ]]; then
  echo "==> Built app bundle at $APP_BUNDLE"
  exit 0
fi

echo "==> Installing to /Applications/FerroPane.app..."
rm -rf "/Applications/TC-Mac.app" "/Applications/FerroPane.app"
cp -R "$APP_BUNDLE" "/Applications/FerroPane.app"

if [[ "${1:-}" != "--no-launch" ]]; then
  echo "==> Launching /Applications/FerroPane.app..."
  open "/Applications/FerroPane.app"
fi
