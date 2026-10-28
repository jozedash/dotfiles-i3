#!/usr/bin/env bash
# One left/centre/right set per connected monitor; tray only on the primary.
command -v polybar >/dev/null || exit 0

# i3's exec_always and toggle_layout.sh can both launch at startup
exec 8>"${XDG_RUNTIME_DIR:-/tmp}/polybar_launch.lock"
flock 8

polybar-msg cmd quit >/dev/null 2>&1
killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.1; done

# Battery, charger and backlight are detected unless set in this optional
# machine-specific file; Polybar drops a module whose device is missing
HOST_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles-host/host.sh"
[ -f "$HOST_CONF" ] && . "$HOST_CONF"
BATTERY=${BATTERY:-$(basename "$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)")}
ADAPTER=${ADAPTER:-$(basename "$(ls -d /sys/class/power_supply/{AC,ADP}* 2>/dev/null | head -1)")}
BACKLIGHT=${BACKLIGHT:-$(basename "$(ls -d /sys/class/backlight/* 2>/dev/null | head -1)")}
export BATTERY ADAPTER BACKLIGHT

for m in $(polybar --list-monitors | cut -d: -f1); do
    # 8>&- so the bars don't hold the lock
    MONITOR=$m polybar --reload left >/dev/null 2>&1 8>&- &
    MONITOR=$m polybar --reload centre >/dev/null 2>&1 8>&- &
    MONITOR=$m polybar --reload right >/dev/null 2>&1 8>&- &
done
