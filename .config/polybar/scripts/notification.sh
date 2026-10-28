#!/usr/bin/env bash
# Usage: notification.sh [toggle]
#   No argument: print the bell, crossed out while do not disturb is on
#   toggle:      switch do not disturb (dunst holds notifications until it's off)
if [ "$1" == "toggle" ]; then
    dunstctl set-paused toggle
    polybar-msg action notification hook 0 > /dev/null
    exit 0
fi
if [ "$(dunstctl is-paused 2>/dev/null)" == "true" ]; then
    # Held back until do not disturb is switched off
    WAITING=$(dunstctl count waiting 2>/dev/null)
    [ "${WAITING:-0}" -gt 0 ] && echo "󰂛 $WAITING" || echo "󰂛"
else
    echo "󰂚"
fi
