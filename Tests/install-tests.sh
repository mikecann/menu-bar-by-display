#!/usr/bin/env bash
# Checks install.sh and uninstall.sh in a temp folder with a stub binary, without building,
# touching launchd or changing the real menu bar setting.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

printf '#!/bin/sh\necho stub\n' > "$tmp/stub"
chmod +x "$tmp/stub"
export MENU_BAR_BY_DISPLAY_BINARY="$tmp/stub"
export MENU_BAR_BY_DISPLAY_PLIST_DIR="$tmp/agents"
export MENU_BAR_BY_DISPLAY_SKIP_LAUNCHCTL=1

fail() { echo "FAIL: $*" >&2; exit 1; }

bash "$here/install.sh" "$tmp/bin" > /dev/null
[[ -x "$tmp/bin/menu-bar-by-display" ]] || fail "binary not installed"
plist="$tmp/agents/com.mikerosoft.menu-bar-by-display.plist"
plutil -lint "$plist" > /dev/null || fail "plist is not valid"
grep -q "<string>$tmp/bin/menu-bar-by-display</string>" "$plist" || fail "plist doesn't run the installed binary"
grep -q "<key>KeepAlive</key><true/>" "$plist" || fail "plist doesn't keep it running"

bash "$here/uninstall.sh" "$tmp/bin" > /dev/null
[[ ! -e "$tmp/bin/menu-bar-by-display" ]] || fail "binary not removed"
[[ ! -e "$plist" ]] || fail "plist not removed"

echo "install tests passed"
