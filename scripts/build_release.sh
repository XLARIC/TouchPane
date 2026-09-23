#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/TouchPane.xcodeproj"
SCHEME="TouchPane"
APP_NAME="TouchPane"
CONFIGURATION="Release"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/TouchPaneReleaseDerivedData}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
RELEASE_DIR="$DIST_DIR/release"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-TouchPane Local Code Signing}"
SIGN_SCRIPT="$ROOT_DIR/scripts/sign_app.sh"

echo "==> Building universal Release app…"
rm -rf "$DERIVED_DATA_PATH" "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk macosx \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

BUILT_APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME.app"
RELEASE_APP_PATH="$RELEASE_DIR/$APP_NAME.app"
if [[ ! -d "$BUILT_APP_PATH" ]]; then
  echo "Build succeeded but app was not found at: $BUILT_APP_PATH" >&2
  exit 1
fi

ditto "$BUILT_APP_PATH" "$RELEASE_APP_PATH"
echo "==> Signing app with: $SIGNING_IDENTITY"
SIGNING_IDENTITY="$SIGNING_IDENTITY" "$SIGN_SCRIPT" "$RELEASE_APP_PATH"

APP_EXECUTABLE="$RELEASE_APP_PATH/Contents/MacOS/$APP_NAME"
ARCHITECTURES="$(lipo -archs "$APP_EXECUTABLE")"
if [[ "$ARCHITECTURES" != *arm64* || "$ARCHITECTURES" != *x86_64* ]]; then
  echo "Expected arm64 and x86_64, found: $ARCHITECTURES" >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$RELEASE_APP_PATH/Contents/Info.plist")"
DMG_BASENAME="$APP_NAME-$VERSION-macOS-universal.dmg"
DMG_PATH="$DIST_DIR/$DMG_BASENAME"
CHECKSUM_PATH="$DMG_PATH.sha256"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/touchpane-release.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT

ditto "$RELEASE_APP_PATH" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"
cp "$ROOT_DIR/FIRST_RUN.txt" "$STAGING_DIR/FIRST_RUN.txt"

rm -f "$DMG_PATH" "$CHECKSUM_PATH"
echo "==> Creating DMG…"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -format UDZO \
  -ov \
  "$DMG_PATH"

IDENTITY_HASH="$(security find-identity -v -p codesigning | awk -v name="\"$SIGNING_IDENTITY\"" 'index($0, name) { print $2; exit }')"
if [[ -z "$IDENTITY_HASH" ]]; then
  echo "Code-signing identity not found: $SIGNING_IDENTITY" >&2
  exit 1
fi

if [[ "$SIGNING_IDENTITY" == Developer\ ID\ Application:* ]]; then
  codesign --force --timestamp --sign "$IDENTITY_HASH" "$DMG_PATH"
else
  codesign --force --timestamp=none --sign "$IDENTITY_HASH" "$DMG_PATH"
fi

codesign --verify --deep --strict --verbose=2 "$RELEASE_APP_PATH"
codesign --verify --verbose=2 "$DMG_PATH"

(
  cd "$DIST_DIR"
  shasum -a 256 "$DMG_BASENAME" > "$DMG_BASENAME.sha256"
)

echo "==> Release ready"
echo "App:      $RELEASE_APP_PATH"
echo "DMG:      $DMG_PATH"
echo "Checksum: $CHECKSUM_PATH"
echo "Architectures: $ARCHITECTURES"
