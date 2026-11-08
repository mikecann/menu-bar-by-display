# Agent guidance for menu-bar-by-display

This repo is a macOS 13+ Swift command-line tool that runs as a LaunchAgent. It keeps the menu bar always shown when the laptop's built-in display is the only one active, and auto-hidden when any external display is active.

## Rules

- Use test-first development for non-trivial behaviour changes. The display rule lives in `Sources/MenuBarByDisplayCore/Policy.swift` so it can be tested without real displays.
- Test before committing: `swift test`, `bash Tests/install-tests.sh`, and `bash -n` on every shell script. Then run `bash install.sh` and `menu-bar-by-display status` when the environment permits it. Say which display setups you couldn't try (for example no external monitor plugged in).
- Keep build output out of Git. Swift output belongs in `.build/`.
- Write plain, friendly documentation without em dashes or en dashes. PR descriptions start with `## Why` and explain what prompted the change.

## Contracts

- Keep the LaunchAgent label `com.mikerosoft.menu-bar-by-display` and the log path `~/Library/Logs/menu-bar-by-display.log` so existing installs upgrade in place.
- Only write the two keys System Settings uses (`_HIHideMenuBar`, `AppleMenuBarVisibleInFullscreen`) and post `AppleInterfaceMenuBarHidingChangedNotification` after changing them. Don't write when the setting already matches, and don't change anything when no displays are active.
- `install.sh` and `uninstall.sh` must work from this clone alone, and keep honouring `MENU_BAR_BY_DISPLAY_BINARY`, `MENU_BAR_BY_DISPLAY_PLIST_DIR` and `MENU_BAR_BY_DISPLAY_SKIP_LAUNCHCTL` so the install tests never touch launchd or the real setting.
- CI must not need a display, signing certificate or login session.
