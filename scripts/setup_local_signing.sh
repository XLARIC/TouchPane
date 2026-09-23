#!/usr/bin/env bash
set -euo pipefail

IDENTITY_NAME="${SIGNING_IDENTITY:-TouchPane Local Code Signing}"
DEFAULT_KEYCHAIN_PATH="$(
  security default-keychain -d user |
    sed -E 's/^[[:space:]]*\"//; s/\"[[:space:]]*$//'
)"
KEYCHAIN_PATH="${KEYCHAIN_PATH:-$DEFAULT_KEYCHAIN_PATH}"

if [[ "$IDENTITY_NAME" == *"/"* ]]; then
  echo "SIGNING_IDENTITY cannot contain '/'." >&2
  exit 2
fi

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/touchpane-signing.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT

PRIVATE_KEY="$TEMP_DIR/local-signing.key"
CERTIFICATE="$TEMP_DIR/local-signing.cer"
PKCS12_FILE="$TEMP_DIR/local-signing.p12"
PKCS12_PASSWORD="$(openssl rand -hex 24)"

trust_certificate() {
  echo "==> Trusting it for code signing on this Mac…"
  echo "    Approve the Keychain prompt if macOS displays one."
  security add-trusted-cert \
    -r trustRoot \
    -p codeSign \
    -k "$KEYCHAIN_PATH" \
    "$CERTIFICATE"
}

if security find-identity -v -p codesigning "$KEYCHAIN_PATH" | grep -Fq "\"$IDENTITY_NAME\""; then
  echo "Stable signing identity already exists: $IDENTITY_NAME"
  exit 0
fi

if security find-certificate -c "$IDENTITY_NAME" "$KEYCHAIN_PATH" >/dev/null 2>&1; then
  echo "==> Found the certificate; repairing its code-signing trust…"
  security find-certificate \
    -c "$IDENTITY_NAME" \
    -p "$KEYCHAIN_PATH" > "$CERTIFICATE"
  trust_certificate
  if security find-identity -v -p codesigning "$KEYCHAIN_PATH" | grep -Fq "\"$IDENTITY_NAME\""; then
    echo "Stable local signing identity is ready: $IDENTITY_NAME"
    exit 0
  fi
  echo "The certificate is trusted, but its private key is missing or unavailable." >&2
  echo "Repair the identity in Keychain Access, then run this script again." >&2
  exit 1
fi

echo "==> Creating a local code-signing certificate…"
openssl req \
  -x509 \
  -newkey rsa:2048 \
  -sha256 \
  -days 3650 \
  -nodes \
  -subj "/CN=$IDENTITY_NAME/O=TouchPane Local Development/OU=Local Code Signing" \
  -addext "basicConstraints=critical,CA:TRUE,pathlen:0" \
  -addext "keyUsage=critical,digitalSignature,keyCertSign" \
  -addext "extendedKeyUsage=codeSigning" \
  -addext "subjectKeyIdentifier=hash" \
  -addext "authorityKeyIdentifier=keyid:always" \
  -keyout "$PRIVATE_KEY" \
  -out "$CERTIFICATE" >/dev/null 2>&1

openssl pkcs12 \
  -export \
  -legacy \
  -name "$IDENTITY_NAME" \
  -inkey "$PRIVATE_KEY" \
  -in "$CERTIFICATE" \
  -passout "pass:$PKCS12_PASSWORD" \
  -out "$PKCS12_FILE"

echo "==> Importing the identity into: $KEYCHAIN_PATH"
security import "$PKCS12_FILE" \
  -k "$KEYCHAIN_PATH" \
  -P "$PKCS12_PASSWORD" \
  -T /usr/bin/codesign \
  -T /usr/bin/security >/dev/null

trust_certificate

if ! security find-identity -v -p codesigning "$KEYCHAIN_PATH" | grep -Fq "\"$IDENTITY_NAME\""; then
  echo "The certificate was imported, but macOS does not consider it a valid signing identity." >&2
  exit 1
fi

echo "Stable local signing identity is ready: $IDENTITY_NAME"
echo "Keep this identity in Keychain Access. Deleting it will change the app identity."
