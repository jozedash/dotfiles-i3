#!/usr/bin/env bash
# Restarts dunst so it re-reads dunstrc.d/colors.conf after a theme change. dunst 1.9
# (Mint 22) has no "dunstctl reload"; a restart loses do not disturb, so it's restored.
paused=$(dunstctl is-paused 2>/dev/null)
pkill -x dunst
while pgrep -x dunst >/dev/null; do sleep 0.1; done
# Detached with no open pipes, so theme-apply doesn't wait on the daemon
setsid -f dunst >/dev/null 2>&1 < /dev/null
if [ "$paused" == "true" ]; then
    for _ in {1..20}; do
        dunstctl set-paused true 2>/dev/null && break
        sleep 0.1
    done
fi
polybar-msg action notification hook 0 >/dev/null 2>&1
exit 0
