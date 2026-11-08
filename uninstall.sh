#!/usr/bin/env bash
# Stops menu-bar-by-display and removes its LaunchAgent and command. The menu bar keeps whatever
# setting it had last; change it in System Settings > Control Center if you want it different.
#
#   bash uninstall.sh [target_bin_dir]
set -euo pipefail

bin_dir="${1:-$HOME/.local/bin}"
plist_dir="${MENU_BAR_BY_DISPLAY_PLIST_DIR:-$HOME/Library/LaunchAgents}"
label="com.mikerosoft.menu-bar-by-display"

if [[ "${MENU_BAR_BY_DISPLAY_SKIP_LAUNCHCTL:-}" != "1" ]]; then
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
fi
rm -f "$plist_dir/$label.plist" "$bin_dir/menu-bar-by-display"
echo "Removed menu-bar-by-display."
