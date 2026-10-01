# Changelog

All notable TouchPane changes are documented in this file.

## 1.3.1

- Fixed the menu bar gesture icon's vertical alignment by drawing the complete
  symbol into a centered template image without SF Symbols text-baseline
  metadata.

## 1.3.0

- Added an optional native macOS Launch at Login setting with approval status
  and a shortcut to Login Items in System Settings.
- Rebuilt Settings around the native macOS split-view sidebar and unified
  toolbar so macOS 27 supplies its current System Settings/Finder appearance;
  sidebar explanatory subtitles remain visible and the complete row is
  clickable.
- Changed the menu bar status item to use the hand-tap gesture symbol and
  corrected its size and alignment.
- Preserved macOS 12 compatibility; Launch at Login is available on macOS 13
  and later.

## 1.2.0

- Renamed the application from TouchMyMac to TouchPane and adopted the
  `io.github.xlaric.TouchPane` bundle identifier.
- Added WingCool/ASM-156UCT absolute-mouse HID support (`27c0:0858`).
- Fixed pointer movement to the touched external display in multi-display
  setups.
- Fixed coordinate mapping for touch displays rotated by 90 degrees.
- Added System, Light, and Dark appearance modes; System is the default.
- Added System, English, Simplified Chinese, and Traditional Chinese language
  modes; System is the default and English is the fallback.
- Made the complete Settings sidebar row clickable.
- Added live HID, touch, gesture, action, and permission diagnostics.
- Improved touch liftoff recovery, gesture handling, shortcut mapping, and the
  floating keyboard.
- Added stable self-signed local installation and universal DMG release tools.
- Added English, Simplified Chinese, and Traditional Chinese documentation.

## 1.1.0

- Upstream touchMyMac release used as the base for this fork.
