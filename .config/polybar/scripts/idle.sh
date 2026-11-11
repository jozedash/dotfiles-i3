#!/usr/bin/env bash
# Usage: idle.sh [toggle|apply]
#   No argument: print an open eye while staying awake, a closed one while idling is allowed
#   toggle:      switch between them. Staying awake stops the screen locking (xss-lock),
#                blanking (DPMS) and the 30-minute suspend (xautolock).
#   apply:       set the screen saver and DPMS for the current state (i3 start-up, after unlocking)
# Lock at 10 min idle and blank 10 min later; the suspend is xautolock's line in the i3 config.
STATE="${XDG_RUNTIME_DIR:-/tmp}/idle-inhibited"

apply() {
    if [ -e "$STATE" ]; then
        xset s off -dpms
    else
        xset s 600 600 +dpms dpms 0 0 1200
    fi
}

if [ "$1" == "apply" ]; then
    apply
    exit 0
fi

if [ "$1" == "toggle" ]; then
    if [ -e "$STATE" ]; then
        rm -f "$STATE"
        apply
        xautolock -enable
        notify-send -a Idle -t 1500 "Idle allowed"
    else
        touch "$STATE"
        apply
        xautolock -disable
        notify-send -a Idle -t 1500 "Staying awake"
    fi
    polybar-msg action idle hook 0 > /dev/null
    exit 0
fi
[ -e "$STATE" ] && echo "󰈈" || echo "󰈉"
