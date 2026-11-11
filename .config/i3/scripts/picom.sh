#!/usr/bin/env bash
# Keeps picom running: noble's 10.2 aborts on a win_bind_mask assertion when
# some windows close (e.g. VS Code), leaving Polybar's corners black.
# Replaces any earlier supervisor, so i3 reloads don't stack loops.
pgrep -f "$0" | grep -vx $$ | xargs -r kill
# A picom started while the login layout resizes the screen keeps the old size and
# draws everything offset, so wait (up to 10 s) for this i3 session's first layout.
marker="${XDG_RUNTIME_DIR:-/tmp}/i3_layout_applied"
session="${I3SOCK:-$(i3 --get-socketpath)}"
for _ in $(seq 100); do
    [ "$(cat "$marker" 2>/dev/null)" == "$session" ] && break
    sleep 0.1
done
pkill -x picom
while pgrep -x picom >/dev/null; do sleep 0.1; done
while true; do
    picom --config ~/.config/picom/picom.conf
    sleep 1
done
