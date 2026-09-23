# TouchPane Release Guide

TouchPane's free binary release uses one stable self-signed code-signing
identity. It costs nothing, but it is not an Apple Developer ID certificate and
cannot be notarized. Every new user must manually approve the first launch in
System Settings.

## One-Time Maintainer Setup

Create the release identity once:

```bash
./scripts/setup_local_signing.sh
```

The identity is named `TouchPane Local Code Signing` and is stored in the login
Keychain. Use Keychain Access to export the certificate **and its private key**
as a password-protected `.p12`, then keep it in encrypted offline storage. Never
commit the `.p12`, its password, or any private key.

Losing or replacing this identity changes the app's signing requirement and
can cause existing users to lose Accessibility or Input Monitoring approval on
the next update.

## Build the Release

Start from a clean, reviewed commit. Then run:

```bash
./scripts/build_release.sh
```

The script:

1. Builds a Release app for Apple silicon and Intel.
2. Signs nested code and the app with the stable identity.
3. Verifies the signature and both architectures.
4. Creates and signs a DMG containing TouchPane, an Applications shortcut, and
   trilingual first-run instructions.
5. Writes a SHA-256 checksum next to the DMG.

Artifacts are written to `dist/`.

## Verify Before Publishing

```bash
codesign --verify --deep --strict --verbose=2 \
  dist/release/TouchPane.app
codesign -dv --verbose=4 dist/release/TouchPane.app
lipo -archs dist/release/TouchPane.app/Contents/MacOS/TouchPane
shasum -a 256 -c dist/TouchPane-*-macOS-universal.dmg.sha256
```

Mount the DMG, copy the app to `/Applications`, and complete one clean-machine
smoke test:

- First launch can be approved through Privacy & Security.
- Accessibility and Input Monitoring can both be granted.
- Touching the external display moves the pointer to that display.
- Portrait 90-degree coordinate mapping is correct.
- System, Light, and Dark appearance modes work.
- System, English, Simplified Chinese, and Traditional Chinese modes work.
- Settings sidebar rows respond across their full width.

## Publish

1. Push the reviewed commit and an annotated version tag.
2. Create a GitHub Release for that tag.
3. Upload both the `.dmg` and `.dmg.sha256` files.
4. State clearly that the release is self-signed and not Apple-notarized.
5. Include a link to the first-launch instructions in the README.

Do not rebuild an already published version with a different certificate.
