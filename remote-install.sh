#!/bin/bash
# Fetches tidymac and installs it without cloning the repo.
# Usage: curl -fsSL https://raw.githubusercontent.com/Selkomark/tidymac/main/remote-install.sh | bash -s -- [install.sh args]
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/Selkomark/tidymac/main"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for f in tidymac.sh install.sh com.selkomark.tidymac.plist.template; do
  curl -fsSL "$REPO_RAW/$f" -o "$TMP/$f"
done
chmod +x "$TMP/tidymac.sh" "$TMP/install.sh"

"$TMP/install.sh" "$@"

echo "(the Uninstall path above won't exist after this script exits — to uninstall, run:"
echo "  curl -fsSL $REPO_RAW/uninstall.sh | bash)"
