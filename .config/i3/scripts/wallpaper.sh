#!/usr/bin/env bash
# The theme mode's wallpaper, else a flat colour.
# Usage: wallpaper.sh [dark|light]   (default: the saved theme mode)
#   photo: the photos in ~/.config/i3/wallpapers/ (credits in CREDITS.md)
#   plain: the gradients in the repo's Pictures/ (wallpaper.jpg, and its
#          pink-to-white wallpaper-light.jpg for light mode)
STYLE=photo

state="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-theme/state.json"
mode=${1:-$(jq -r '.mode // "dark"' "$state" 2>/dev/null)}
mode=${mode:-dark}
if [ "$STYLE" == "plain" ]; then
    # The repo, through the ~/.config/i3 symlink this script is run from
    pictures=$(readlink -f "$(dirname "$0")/../../..")/Pictures
    [ "$mode" == "light" ] && wallpaper="$pictures/wallpaper-light.jpg" || wallpaper="$pictures/wallpaper.jpg"
else
    wallpaper="$HOME/.config/i3/wallpapers/$mode.jpg"
fi
if [ -f "$wallpaper" ] && command -v feh >/dev/null; then
    feh --no-fehbg --bg-fill "$wallpaper"
else
    xsetroot -solid "#2b2b2b"
fi
