#!/usr/bin/env bash
# Install updates in a terminal (Polybar updates icon, Super+U), then wait for a
# key so the result can be read before the window closes.

# The repo, through the ~/.config symlink this script is run from
DOCS=$(readlink -f "$(dirname "$0")/../../..")/docs

sudo apt update && sudo apt full-upgrade
STATUS=$?

echo
if [ $STATUS -eq 0 ]; then
    echo "Upgrade finished."
    MERGES=$(find /etc \( -name '*.dpkg-dist' -o -name '*.dpkg-new' \) 2>/dev/null)
    [ -n "$MERGES" ] && echo -e "Some config files need merging:\n$MERGES"
    [ -e /var/run/reboot-required ] && echo "A reboot is needed to finish the upgrade."
else
    echo "Upgrade FAILED (exit code $STATUS), see the output above."
    echo "Help: $DOCS/apt-download-failures.md"
fi
read -n 1 -s -r -p "Press any key to close"
