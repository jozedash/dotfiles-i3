#!/usr/bin/env bash
# One left/centre/right set per connected monitor; tray only on the primary.
command -v polybar >/dev/null || exit 0
polybar-msg cmd quit >/dev/null 2>&1
killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.1; done

primary=$(xrandr --query | awk '/ connected primary/ {print $1}')
for m in $(polybar --list-monitors | cut -d: -f1); do
    MONITOR=$m polybar --reload left >/dev/null 2>&1 &
    MONITOR=$m polybar --reload centre >/dev/null 2>&1 &
    MONITOR=$m polybar --reload right >/dev/null 2>&1 &
done
