#!/usr/bin/env bash
# Builds menu-bar-by-display, copies it into a bin directory (default ~/.local/bin) and starts it at
# login as a LaunchAgent. Rerun it after changing the code to rebuild and restart it.
#
#   bash install.sh [target_bin_dir]
#
# MENU_BAR_BY_DISPLAY_PLIST_DIR and MENU_BAR_BY_DISPLAY_SKIP_LAUNCHCTL=1 exist for the install tests.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${1:-$HOME/.local/bin}"
plist_dir="${MENU_BAR_BY_DISPLAY_PLIST_DIR:-$HOME/Library/LaunchAgents}"
label="com.mikerosoft.menu-bar-by-display"
plist="$plist_dir/$label.plist"
log_file="$HOME/Library/Logs/menu-bar-by-display.log"

if [[ -n "${MENU_BAR_BY_DISPLAY_BINARY:-}" ]]; then
  built="$MENU_BAR_BY_DISPLAY_BINARY"
else
  (cd "$here" && swift build -c release)
  built="$here/.build/release/menu-bar-by-display"
fi

mkdir -p "$bin_dir" "$plist_dir"
# Copy rather than link, so cleaning the build folder doesn't stop it starting at login.
install -m 755 "$built" "$bin_dir/menu-bar-by-display"

cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array><string>$bin_dir/menu-bar-by-display</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ProcessType</key><string>Background</string>
  <key>StandardErrorPath</key><string>$log_file</string>
</dict>
</plist>
PLIST

if [[ "${MENU_BAR_BY_DISPLAY_SKIP_LAUNCHCTL:-}" != "1" ]]; then
  domain="gui/$(id -u)"
  launchctl bootout "$domain/$label" 2>/dev/null || true
  launchctl bootstrap "$domain" "$plist"
fi

echo "Installed $bin_dir/menu-bar-by-display and started $label."
echo "Check it with: menu-bar-by-display status"
