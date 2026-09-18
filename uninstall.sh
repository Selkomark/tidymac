#!/bin/bash
set -uo pipefail
LABEL="com.selkomark.tidymac"
UID_NUM="$(id -u)"
launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist" "$HOME/bin/tidymac.sh"
[[ -f /etc/sudoers.d/tidymac ]] && sudo rm -f /etc/sudoers.d/tidymac
echo "removed agent, script and sudoers rule (logs kept in ~/Library/Logs/tidymac)"
