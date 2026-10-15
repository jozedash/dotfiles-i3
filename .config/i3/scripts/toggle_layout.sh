#!/usr/bin/env bash
# xrandr port of ~/.config/hypr/toggle_layout.sh: cycles LAPTOP -> DOCKED -> EXTEND -> GAMING.
STATEFILE="$HOME/.config/i3/layout_state"
LAPTOP=0
DOCKED=1
EXTEND=2
GAMING=3
MODE_COUNT=4

INTERNAL=eDP-1
[ -f "$STATEFILE" ] || echo $LAPTOP > "$STATEFILE"
STATE=$(cat "$STATEFILE")

EXTERNAL=$(xrandr --query | awk '/ connected/ && $1 != "'$INTERNAL'" {print $1; exit}')

if [ "$1" == "reset" ] || [ -z "$EXTERNAL" ]; then
    STATE=$LAPTOP
elif [ "$1" == "toggle" ]; then
    STATE=$(( (STATE + 1) % MODE_COUNT ))
fi

move_workspaces() {
    # Odd workspaces to $1, even to $2.
    for ws in 1 2 3 4 5 6; do
        target=$1
        (( ws % 2 == 0 )) && target=$2
        i3-msg -q "workspace number $ws; move workspace to output $target"
    done
    i3-msg -q "workspace number 1"
}

case $STATE in
    $DOCKED)
        xrandr --output "$EXTERNAL" --mode 3840x2160 --rate 60 --pos 0x0 --primary --output $INTERNAL --off
        move_workspaces "$EXTERNAL" "$EXTERNAL" ;;
    $GAMING)
        xrandr --output "$EXTERNAL" --mode 1600x900 --rate 60 --pos 0x0 --primary --output $INTERNAL --off
        move_workspaces "$EXTERNAL" "$EXTERNAL" ;;
    $EXTEND)
        xrandr --output "$EXTERNAL" --mode 3840x2160 --rate 60 --pos 0x0 --primary \
               --output $INTERNAL --auto --pos 3840x1080
        move_workspaces "$EXTERNAL" $INTERNAL ;;
    *)
        STATE=$LAPTOP
        xrandr --output $INTERNAL --auto --pos 0x0 --primary ${EXTERNAL:+--output "$EXTERNAL" --off}
        ;;
esac

echo $STATE > "$STATEFILE"
# Bars are per-monitor, so relaunch after the output set changes.
~/.config/polybar/launch.sh
~/.config/i3/scripts/wallpaper.sh
