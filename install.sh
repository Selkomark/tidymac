#!/bin/bash
# Installs tidymac.sh to ~/bin and registers a launchd agent.
# Usage: ./install.sh [--schedule daily|weekly|every3h|every6h] [--hour H] [--minute M] [--weekday D] [--sudo]
#   --schedule   daily (default, at --hour:--minute), weekly (--weekday at --hour:--minute),
#                every3h, every6h (fixed interval; --hour/--minute/--weekday are ignored)
#   --weekday    0=Sunday .. 6=Saturday, weekly only (default 0)
#   --sudo       add a sudoers rule so tmutil thinlocalsnapshots can run without a password
set -euo pipefail

SCHEDULE=daily; HOUR=10; MINUTE=0; WEEKDAY=0; SETUP_SUDO=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --schedule) SCHEDULE="$2"; shift 2 ;;
    --hour)     HOUR="$2"; shift 2 ;;
    --minute)   MINUTE="$2"; shift 2 ;;
    --weekday)  WEEKDAY="$2"; shift 2 ;;
    --sudo)     SETUP_SUDO=1; shift ;;
    *) echo "unknown arg: $1"; exit 1 ;;
  esac
done

DAYS=(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
case "$SCHEDULE" in
  daily)
    SCHEDULE_XML="<key>StartCalendarInterval</key><dict><key>Hour</key><integer>$HOUR</integer><key>Minute</key><integer>$MINUTE</integer></dict>"
    SCHEDULE_DESC="daily at $(printf '%02d:%02d' "$HOUR" "$MINUTE")"
    ;;
  weekly)
    SCHEDULE_XML="<key>StartCalendarInterval</key><dict><key>Weekday</key><integer>$WEEKDAY</integer><key>Hour</key><integer>$HOUR</integer><key>Minute</key><integer>$MINUTE</integer></dict>"
    SCHEDULE_DESC="weekly on ${DAYS[$WEEKDAY]} at $(printf '%02d:%02d' "$HOUR" "$MINUTE")"
    ;;
  every3h)
    SCHEDULE_XML="<key>StartInterval</key><integer>10800</integer>"
    SCHEDULE_DESC="every 3 hours"
    ;;
  every6h)
    SCHEDULE_XML="<key>StartInterval</key><integer>21600</integer>"
    SCHEDULE_DESC="every 6 hours"
    ;;
  *)
    echo "unknown --schedule: $SCHEDULE (use daily, weekly, every3h, every6h)"; exit 1 ;;
esac

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
    -e "s|__SCHEDULE__|$SCHEDULE_XML|g" \
    -e "s|__LOG__|$LOG_DIR/tidymac.log|g" \
    -e "s|__ERR__|$LOG_DIR/tidymac.err|g" \
    "$SRC_DIR/com.selkomark.tidymac.plist.template" > "$PLIST"
plutil -lint "$PLIST" >/dev/null
echo "wrote $PLIST ($SCHEDULE_DESC)"

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
