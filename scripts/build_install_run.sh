#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/TouchPane.xcodeproj"
SCHEME="TouchPane"
CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/TouchPaneDerivedData}"
APP_NAME="TouchPane"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-TouchPane Local Code Signing}"
SIGN_SCRIPT="$ROOT_DIR/scripts/sign_app.sh"

usage() {
  cat <<EOF
Usage:
  $(basename "$0") [--app-dir /Applications] [--configuration Debug|Release]

Env vars:
  DERIVED_DATA_PATH=...  (default: $DERIVED_DATA_PATH)
  CONFIGURATION=...      (default: $CONFIGURATION)
  SIGNING_IDENTITY=...   (default: $SIGNING_IDENTITY)
EOF
}

APP_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-dir)
      APP_DIR="${2:-}"
      shift 2
      ;;
    --configuration)
      CONFIGURATION="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$APP_DIR" ]]; then
  APP_DIR="/Applications"
fi

TARGET_APP_PATH="$APP_DIR/$APP_NAME.app"
STAGED_APP_PATH="$APP_DIR/.$APP_NAME.installing.$$"
BACKUP_APP_PATH="$APP_DIR/.$APP_NAME.previous.$$"

NEED_SUDO=0
if [[ ! -w "$APP_DIR" ]]; then
  echo "==> Note: $APP_DIR is not writable; will use sudo for install/remove." >&2
  NEED_SUDO=1
fi

run_install_cmd() {
  if [[ "$NEED_SUDO" -eq 1 ]]; then
    sudo "$@"
  else
    "$@"
  fi
}

echo "==> Building ($CONFIGURATION)…"
rm -rf "$DERIVED_DATA_PATH"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk macosx \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

BUILT_APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME.app"
if [[ ! -d "$BUILT_APP_PATH" ]]; then
  echo "Build succeeded but app not found at: $BUILT_APP_PATH" >&2
  exit 1
fi

echo "==> Signing with stable identity: $SIGNING_IDENTITY"
SIGNING_IDENTITY="$SIGNING_IDENTITY" "$SIGN_SCRIPT" "$BUILT_APP_PATH"

echo "==> Staging verified app…"
run_install_cmd mkdir -p "$APP_DIR"
run_install_cmd rm -rf "$STAGED_APP_PATH" "$BACKUP_APP_PATH"
run_install_cmd ditto "$BUILT_APP_PATH" "$STAGED_APP_PATH"
codesign --verify --deep --strict --verbose=2 "$STAGED_APP_PATH"

echo "==> Quitting running app (if any)…"
osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

echo "==> Installing to: $TARGET_APP_PATH"
if [[ -e "$TARGET_APP_PATH" ]]; then
  run_install_cmd mv "$TARGET_APP_PATH" "$BACKUP_APP_PATH"
fi

if ! run_install_cmd mv "$STAGED_APP_PATH" "$TARGET_APP_PATH"; then
  echo "Install failed; restoring the previous app." >&2
  if [[ -e "$BACKUP_APP_PATH" ]]; then
    run_install_cmd mv "$BACKUP_APP_PATH" "$TARGET_APP_PATH"
  fi
  exit 1
fi

if [[ -e "$BACKUP_APP_PATH" ]]; then
  run_install_cmd rm -rf "$BACKUP_APP_PATH"
fi

codesign --verify --deep --strict --verbose=2 "$TARGET_APP_PATH"

echo "==> Launching…"
open "$TARGET_APP_PATH"

echo "==> Done."
