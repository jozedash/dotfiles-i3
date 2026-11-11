#!/usr/bin/env bash
# Run by apt-updates-notify.path after the weekly download finishes or fails
STATE=/var/lib/apt-download
# The repo, through the ~/.config symlink this script is run from
DOCS=$(readlink -f "$(dirname "$0")/../../..")/docs

if [ -s "$STATE/error" ]; then
    notify-send -u critical -a Updates "Update download failed" \
        "$(tail -3 "$STATE/error")"$'\n\n'"See $DOCS/apt-download-failures.md"
    exit 0
fi

COUNT=$(grep -c . "$STATE/pending" 2>/dev/null)
[ "${COUNT:-0}" -gt 0 ] || exit 0
notify-send -a Updates "$COUNT updates downloaded" "Click the updates icon or press Super+U to install"
