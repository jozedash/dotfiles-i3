#!/usr/bin/env bash
# Usage: notification.sh [toggle|history]
#   No argument: print the bell, crossed out while do not disturb is on
#   toggle:      switch do not disturb (dunst holds notifications until it's off)
#   history:     pick a past notification in rofi and show it again
if [ "$1" == "toggle" ]; then
    dunstctl set-paused toggle
    polybar-msg action notification hook 0 > /dev/null
    exit 0
fi
if [ "$1" == "history" ]; then
    # Newest first; the id column is hidden and read back to re-pop that notification
    ENTRIES=$(dunstctl history | jq -r '.data[0][] | "\(.id.data)\t\(.appname.data): \(.summary.data)"')
    if [ -z "$ENTRIES" ]; then
        notify-send -a Notifications "No notifications in the history"
        exit 0
    fi
    CHOICE=$(echo "$ENTRIES" | rofi -dmenu -i -no-show-icons -p Notifications \
        -display-columns 2 -display-column-separator '\t') || exit 0
    dunstctl history-pop "${CHOICE%%$'\t'*}"
    exit 0
fi
if [ "$(dunstctl is-paused 2>/dev/null)" == "true" ]; then
    # Held back until do not disturb is switched off
    WAITING=$(dunstctl count waiting 2>/dev/null)
    [ "${WAITING:-0}" -gt 0 ] && echo "󰂛 $WAITING" || echo "󰂛"
else
    echo "󰂚"
fi
