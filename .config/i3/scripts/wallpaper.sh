#!/usr/bin/env bash
# First image in ~/Pictures/wallpaper.* wins, else a flat colour.
wallpaper=$(ls ~/Pictures/wallpaper.* 2>/dev/null | head -n1)
if [ -n "$wallpaper" ] && command -v feh >/dev/null; then
    feh --no-fehbg --bg-fill "$wallpaper"
else
    xsetroot -solid "#2b2b2b"
fi
