#!/usr/bin/env bash
# Keeps picom running: noble's 10.2 aborts on a win_bind_mask assertion when
# some windows close (e.g. VS Code), leaving Polybar's corners black.
# Replaces any earlier supervisor, so i3 reloads don't stack loops.
pgrep -f "$0" | grep -vx $$ | xargs -r kill
pkill -x picom
while pgrep -x picom >/dev/null; do sleep 0.1; done
while true; do
    picom --config ~/.config/picom/picom.conf
    sleep 1
done
