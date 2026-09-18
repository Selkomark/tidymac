#!/bin/bash
# Delete cache files untouched for 30+ days, plus dev tool caches.
# Usage: tidymac.sh [--volumes]
#   --volumes  also prune unused Docker volumes (irreversible)

# launchd runs with a minimal PATH; make brew/docker/uv/etc. findable
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$HOME/.cargo/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

echo "== $(date '+%Y-%m-%d %H:%M:%S') tidymac start =="

find ~/Library/Caches -type f -atime +30 -delete 2>/dev/null
find ~/Library/Logs   -type f -mtime +30 -delete 2>/dev/null

command -v brew >/dev/null && brew cleanup --prune=all -q 2>/dev/null
command -v pip  >/dev/null && pip cache purge -q 2>/dev/null
command -v npm  >/dev/null && npm cache clean --force --silent 2>/dev/null
command -v uv   >/dev/null && uv cache clean -q 2>/dev/null

# Docker: only if the daemon is running
if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
  docker container prune -f 2>/dev/null
  docker builder prune -af 2>/dev/null
  docker image prune -af 2>/dev/null
  if [[ "$1" == "--volumes" ]]; then
    docker volume prune -af 2>/dev/null
  fi
  docker system df
fi

# Time Machine local snapshots need root. Under launchd there is no TTY for a
# password prompt, so this runs only if passwordless sudo is configured for it
# (install.sh --sudo sets that up) or the script is run interactively as root.
if sudo -n true 2>/dev/null; then
  sudo -n tmutil thinlocalsnapshots / 999999999999 4 2>/dev/null
elif [[ -t 0 ]]; then
  sudo tmutil thinlocalsnapshots / 999999999999 4 2>/dev/null
else
  echo "skip: tmutil thinlocalsnapshots (no passwordless sudo; run install.sh --sudo)"
fi

echo "== $(date '+%Y-%m-%d %H:%M:%S') tidymac done =="
