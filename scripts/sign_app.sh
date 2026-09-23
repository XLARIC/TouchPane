#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${1:-}"
IDENTITY_NAME="${SIGNING_IDENTITY:-TouchPane Local Code Signing}"
ENTITLEMENTS_PATH="${ENTITLEMENTS_PATH:-$ROOT_DIR/TouchPane/TouchPane.entitlements}"

if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "Usage: SIGNING_IDENTITY='certificate name' $(basename "$0") /path/to/TouchPane.app" >&2
  exit 2
fi

IDENTITY_HASH="$(security find-identity -v -p codesigning | awk -v name="\"$IDENTITY_NAME\"" 'index($0, name) { print $2; exit }')"
if [[ -z "$IDENTITY_HASH" ]]; then
  echo "Code-signing identity not found: $IDENTITY_NAME" >&2
  if [[ "$IDENTITY_NAME" == "TouchPane Local Code Signing" ]]; then
    echo "Run ./scripts/setup_local_signing.sh once, then retry." >&2
  fi
  exit 1
fi

if [[ "$IDENTITY_NAME" == Developer\ ID\ Application:* ]]; then
  TIMESTAMP_ARGUMENT="--timestamp"
else
  TIMESTAMP_ARGUMENT="--timestamp=none"
fi

SIGN_ARGUMENTS=(
  --force
  --options runtime
  "$TIMESTAMP_ARGUMENT"
  --sign "$IDENTITY_HASH"
)

FRAMEWORKS_PATH="$APP_PATH/Contents/Frameworks"
if [[ -d "$FRAMEWORKS_PATH" ]]; then
  while IFS= read -r -d '' NESTED_CODE; do
    codesign "${SIGN_ARGUMENTS[@]}" "$NESTED_CODE"
  done < <(
    find "$FRAMEWORKS_PATH" -depth \
      \( -type d -name '*.framework' \
      -o -type d -name '*.xpc' \
      -o -type d -name '*.appex' \
      -o -type f -name '*.dylib' \) \
      -print0
  )
fi

codesign \
  "${SIGN_ARGUMENTS[@]}" \
  --entitlements "$ENTITLEMENTS_PATH" \
  "$APP_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign -d -r- "$APP_PATH" 2>&1
