#!/usr/bin/env bash
#
# Polybar module for the weekly apt-download timer. Shows the number of
# downloaded updates that still aren't installed, a restart icon when a reboot is
# needed, and a shield when only config files are left to merge. Prints nothing
# (hiding the module) when there's nothing to do.

STATE=/var/lib/apt-download

# pending lines look like "linux-generic 6.8.0.85.85 -> 6.8.0.86.86"
UPDATES=0
while read -r PKG _ _ NEW; do
    [ -n "$NEW" ] || continue
    INSTALLED=$(dpkg-query -W -f '${Version}' "$PKG" 2>/dev/null)
    if [ -z "$INSTALLED" ] || dpkg --compare-versions "$INSTALLED" lt "$NEW"; then
        UPDATES=$((UPDATES + 1))
    fi
done < <(cat "$STATE/pending" 2>/dev/null)

# A package's new config file, kept aside because the local copy was edited
MERGES=$(find /etc \( -name '*.dpkg-dist' -o -name '*.dpkg-new' \) 2>/dev/null | wc -l)

if [ -e /var/run/reboot-required ]; then
    [ "$UPDATES" -gt 0 ] && echo "󰜉 $UPDATES" || echo "󰜉"
elif [ "$UPDATES" -gt 0 ]; then
    echo "󰚰 $UPDATES"
elif [ "$MERGES" -gt 0 ]; then
    echo "󰒘 $MERGES"
fi
