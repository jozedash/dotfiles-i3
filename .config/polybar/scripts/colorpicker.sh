#!/usr/bin/env bash
# Usage: colorpicker.sh [-p|-l]
#   No argument: pick a colour from the screen, copy it and add it to the history
#   -p:          print the module: the picker icon and a swatch of the last colour
#   -l:          list the history, newest first

notify() {
    command -v notify-send >/dev/null && notify-send -a "Color Picker" "$@" || echo "$@"
}

loc="$HOME/.cache/colorpicker"
[ -d "$loc" ] || mkdir -p "$loc"
[ -f "$loc/colors" ] || touch "$loc/colors"

limit=10

if [ "$1" == "-l" ]; then
    cat "$loc/colors"
    exit
fi

if [ "$1" == "-p" ]; then
    last=$(head -n 1 "$loc/colors")
    [ -n "$last" ] && echo "󰈊 %{F$last}■%{F-}" || echo "󰈊"
    exit
fi

color=$("$(dirname "$0")/pick_pixel.py") || {
    notify "Colour picker failed"
    exit 1
}
[ -n "$color" ] || exit 0

# xclip stays running to serve the clipboard, so it mustn't hold the caller's output open
command -v xclip >/dev/null && printf '%s' "$color" | xclip -selection clipboard >/dev/null 2>&1
notify "$color copied"

prevColors=$(head -n $((limit - 1)) "$loc/colors")
echo "$color" >"$loc/colors"
echo "$prevColors" >>"$loc/colors"
sed -i '/^$/d' "$loc/colors"
polybar-msg action colorpicker hook 0 > /dev/null
