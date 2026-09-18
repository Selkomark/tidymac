#!/bin/bash
# Installs tidymac.sh to ~/bin and registers a daily launchd agent.
# Usage: ./install.sh [--hour H] [--minute M] [--sudo]
#   --sudo   add a sudoers rule so tmutil thinlocalsnapshots can run without a password
set -euo pipefail

HOUR=10; MINUTE=0; SETUP_SUDO=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --hour)   HOUR="$2"; shift 2 ;;
    --minute) MINUTE="$2"; shift 2 ;;
    --sudo)   SETUP_SUDO=1; shift ;;
    *) echo "unknown arg: $1"; exit 1 ;;
  esac
done

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABEL="com.selkomark.tidymac"
BIN_DIR="$HOME/bin"
SCRIPT="$BIN_DIR/tidymac.sh"
AGENT_DIR="$HOME/Library/LaunchAgents"
PLIST="$AGENT_DIR/$LABEL.plist"
LOG_DIR="$HOME/Library/Logs/tidymac"
UID_NUM="$(id -u)"

mkdir -p "$BIN_DIR" "$AGENT_DIR" "$LOG_DIR"

install -m 755 "$SRC_DIR/tidymac.sh" "$SCRIPT"
echo "installed $SCRIPT"

sed -e "s|__LABEL__|$LABEL|g" \
    -e "s|__SCRIPT__|$SCRIPT|g" \
    -e "s|__HOUR__|$HOUR|g" \
    -e "s|__MINUTE__|$MINUTE|g" \
    -e "s|__LOG__|$LOG_DIR/tidymac.log|g" \
    -e "s|__ERR__|$LOG_DIR/tidymac.err|g" \
    "$SRC_DIR/com.selkomark.tidymac.plist.template" > "$PLIST"
plutil -lint "$PLIST" >/dev/null
echo "wrote $PLIST (daily at $(printf '%02d:%02d' "$HOUR" "$MINUTE"))"

if [[ $SETUP_SUDO -eq 1 ]]; then
  RULE="$USER ALL=(root) NOPASSWD: /usr/bin/tmutil thinlocalsnapshots *"
  echo "$RULE" | sudo tee /etc/sudoers.d/tidymac >/dev/null
  sudo chmod 440 /etc/sudoers.d/tidymac
  sudo visudo -cf /etc/sudoers.d/tidymac >/dev/null
  echo "sudoers rule added for tmutil"
fi

# (Re)load the agent
launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID_NUM" "$PLIST"
launchctl enable "gui/$UID_NUM/$LABEL"
echo "agent loaded: $(launchctl print "gui/$UID_NUM/$LABEL" | grep -E 'state =' | xargs)"

echo
echo "Run now:   launchctl kickstart gui/$UID_NUM/$LABEL"
echo "Logs:      $LOG_DIR/"
echo "Uninstall: $SRC_DIR/uninstall.sh"
