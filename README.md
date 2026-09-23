# TouchPane

[English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md)

Native-feeling touch control for external displays on macOS.

TouchPane translates USB HID touchscreen input into pointer movement, clicks,
scrolling, dragging, gestures, keyboard shortcuts, and an optional floating
keyboard. It is a renamed and extended fork of
[touchMyMac](https://github.com/jinghuichen/touchMyMac), which is based on
[Touch-Up](https://github.com/shueber/Touch-Up) and TouchUpCore by Sebastian
Hueber.

## What This Fork Adds

TouchPane 1.2.0 contains the following changes and additions:

- Added WingCool/ASM-156UCT absolute-mouse HID support for USB device
  `VID 27c0`, `PID 0858`.
- Fixed multi-display behavior so touching the external touchscreen moves the
  pointer to that display, even when the pointer was on another display.
- Fixed touch coordinates on displays rotated by 90 degrees.
- Added **System**, **Light**, and **Dark** appearance options. The default is
  **System**.
- Added **System**, **English**, **Simplified Chinese**, and **Traditional
  Chinese** language options. The default is **System**, with English as the
  fallback for unsupported system languages.
- Fixed the Settings sidebar so the complete row is clickable, not only its
  text.
- Added a stable self-signed build and installation workflow to help macOS keep
  Accessibility and Input Monitoring permissions across matching upgrades.
- Added live HID, touch, gesture, action, and permission diagnostics.
- Improved touch liftoff handling, noisy-panel tolerance, gesture recognition,
  configurable shortcut actions, and the floating keyboard workflow.
- Renamed the application and bundle identifiers from TouchMyMac to TouchPane.

## Features

- Single-finger tap to click
- Single-finger drag scrolling with adjustable speed and inertia
- Hold then move to drag
- Two-finger secondary click
- Two-finger pinch magnification
- Three-finger swipe up for Mission Control
- Four-finger swipe up/down to show or hide the floating keyboard
- Four-finger swipe left to trigger a configurable shortcut sequence
- Five-finger hold to keep a key or key chord pressed
- Automatic or manual touchscreen-to-display assignment
- Live input and gesture diagnostics
- System-following appearance and language

## Tested Hardware

- ASM-156UCT external touch display
- WingCool USB HID touchscreen (`VID 27c0`, `PID 0858`)
- LG Smart Monitor Swing (tested by the upstream fork)

Other USB HID touchscreens may work, but their report formats and noise levels
vary.

## Requirements

- macOS 12 or later
- A USB HID touchscreen
- Accessibility permission
- Input Monitoring permission for touch controllers that expose input through
  a mouse-class HID interface

## Download and First Launch

Download the latest `.dmg` and its `.sha256` file from
[GitHub Releases](https://github.com/XLARIC/TouchPane/releases).

The free release is signed with the project's stable self-signed certificate.
It is **not Apple-notarized**, so macOS will not trust it automatically.

### If macOS says it cannot verify the DMG

You may see an alert saying Apple cannot verify
`TouchPane-1.2.0-macOS-universal.dmg` for malicious software, with only
**Done** and **Move to Trash** buttons. This is expected for the current
self-signed release, but only continue if you downloaded it from this
repository and its SHA-256 checksum matches:

1. Click **Done**. Do not move the DMG to the Trash.
2. Open **System Settings → Privacy & Security**.
3. Scroll down to **Security**, find the message that the TouchPane DMG was
   blocked, and click **Open Anyway**.
4. Authenticate with your Mac password or Touch ID, then confirm **Open**.
5. After the DMG opens, drag `TouchPane.app` to `Applications`.
6. Open TouchPane. If macOS blocks the app itself, repeat the same
   **Privacy & Security → Open Anyway** steps for `TouchPane.app`.
7. Grant TouchPane access under **Accessibility** and **Input Monitoring**,
   then quit and reopen it.

Apple notes that **Open Anyway** is available for about one hour after an
attempted launch. See
[Apple's official instructions](https://support.apple.com/102445). Do not
disable Gatekeeper globally.

In short, the complete first-launch sequence is:

1. Verify the downloaded DMG checksum.
2. Approve and open the DMG using **Privacy & Security → Open Anyway** if
   necessary.
3. Drag `TouchPane.app` to `Applications`.
4. Approve TouchPane itself the same way if macOS asks again.
5. Grant Accessibility and Input Monitoring, then reopen TouchPane.

You normally need to approve the permissions only once. They are preserved
only when later releases keep the same app name, bundle identifier, install
path, and signing certificate.

Verify a release from Terminal:

```bash
cd ~/Downloads
shasum -a 256 -c TouchPane-1.2.0-macOS-universal.dmg.sha256
```

## Build from Source

Open the project in Xcode:

```bash
open TouchPane.xcodeproj
```

Or create a stable local signing identity, build, install, and launch:

```bash
./scripts/setup_local_signing.sh
./scripts/build_install_run.sh --configuration Release
```

The setup script creates `TouchPane Local Code Signing` in the login Keychain.
It does not write the certificate or private key into the repository. The first
switch to this identity still requires Accessibility and Input Monitoring to be
approved once.

Create a universal release DMG:

```bash
./scripts/build_release.sh
```

Release files are written to `dist/`. See [RELEASING.md](RELEASING.md) before
publishing an official build.

## Project Structure

- `TouchPane/` — app UI, settings, status item, diagnostics, and floating
  keyboard
- `Core/` — HID parsing, touch tracking, gesture recognition, and event
  injection
- `scripts/` — signing, local installation, and release packaging

## Security and Privacy

TouchPane runs locally and does not need a network connection for touch input.
Accessibility is required because the app posts mouse and keyboard events.
Input Monitoring is required for some touchscreen HID interfaces.

Never commit signing certificates, private keys, `.p12` files, or their
passwords. Contributors should use their own signing identity; official release
artifacts must always use the maintainer's unchanged release identity.

## Acknowledgements

TouchPane derives from
[jinghuichen/touchMyMac](https://github.com/jinghuichen/touchMyMac), which builds
on [shueber/Touch-Up](https://github.com/shueber/Touch-Up) and TouchUpCore by
Sebastian Hueber. Their copyright notices remain in the source and license.

## License

[MIT](LICENSE)
