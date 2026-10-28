#!/usr/bin/env bash
# Usage: idle.sh [toggle]
#   No argument: print an open eye while staying awake, a closed one while idling is allowed
#   toggle:      switch between them. Staying awake stops the screen locking (xss-lock),
#                blanking (DPMS) and the 30-minute suspend (xautolock).
# The timings match the xset and xautolock lines in the i3 config.
STATE="${XDG_RUNTIME_DIR:-/tmp}/idle-inhibited"

if [ "$1" == "toggle" ]; then
    if [ -e "$STATE" ]; then
        rm -f "$STATE"
        xset s 360 360 dpms 0 0 420
        xautolock -enable
        notify-send -a Idle -t 1500 "Idle allowed"
    else
        touch "$STATE"
        xset s off -dpms
        xautolock -disable
        notify-send -a Idle -t 1500 "Staying awake"
    fi
    polybar-msg action idle hook 0 > /dev/null
    exit 0
fi
[ -e "$STATE" ] && echo "󰈈" || echo "󰈉"
