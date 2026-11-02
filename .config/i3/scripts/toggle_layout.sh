#!/usr/bin/env bash
#
# xrandr port of ~/.config/hypr/toggle_layout.sh.
#
# Usage: toggle_layout.sh [apply|hotplug|toggle|prev|laptop|docked|extend]
#   apply (default) - apply the remembered layout for the currently connected monitors
#   hotplug         - like apply, but only acts if the set of connected outputs changed
#   toggle / prev   - cycle forwards / backwards through the layouts
#   <layout>        - jump straight to that layout
#
# extend depends on the monitors connected:
#   one external  - laptop | monitor (home)
#   two externals - portrait | landscape | laptop (work)
# Its alignment and the work monitors' settings are in the block below LAYOUTS.
#
# The chosen layout is remembered per monitor setup (keyed on the external monitors'
# EDIDs), so e.g. the home and office monitors each keep their own layout.

STATEDIR="${XDG_STATE_HOME:-$HOME/.local/state}/i3/layouts"
RUNDIR="${XDG_RUNTIME_DIR:-/tmp}"
# LAPTOP_OUTPUT and LAPTOP_MODE are detected below (eDP/LVDS/DSI output, preferred
# mode) unless set in this optional machine-specific file
HOST_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles-host/host.sh"
[ -f "$HOST_CONF" ] && . "$HOST_CONF"
LAPTOP_MODE=${LAPTOP_MODE%@*}  # host.sh may give Hyprland's "WxH@rate"

# Add layouts here, in the order toggle cycles through them
LAYOUTS=(laptop docked extend)
DEFAULT_LAYOUT=extend # Used the first time a new monitor setup is seen

# extend positions: each monitor's top-left corner as XxY in pixels, origin at the
# top left of the whole desktop and y growing downwards. Nothing may be negative.
HOME_LAPTOP_POS=0x0            # size 1920x1200
HOME_MONITOR_POS=1920x0        # size 3840x2160
WORK_PORTRAIT_POS=0x0          # size 2160x3840 once rotated
WORK_LANDSCAPE_POS=2160x200   # size 3840x2160
WORK_LAPTOP_POS=6000x800      # size 1920x1200
WORK_PORTRAIT_OUTPUT=DP-1-1    # the hub's DP-to-HDMI port, which can't do 4K60
WORK_PORTRAIT_ROTATION=left    # right if it comes out upside down
WORK_PORTRAIT_MODE=3840x2160   # 30 Hz on that port; empty for its preferred 1080p60
WORK_LANDSCAPE_MODE=3840x2160  # empty for its preferred mode

mkdir -p "$STATEDIR"

# Keybind/hotplug runs have no terminal, so keep a log for debugging
exec > >(tee -a "$RUNDIR/i3_toggle_layout.log") 2>&1
echo "=== $(date '+%F %T') toggle_layout.sh $*"

# Serialise keybind and hotplug invocations
exec 9>"$RUNDIR/i3_toggle_layout.lock"
flock 9

# Let outputs settle after a plug/unplug (docks can bounce)
if [ "$1" == "hotplug" ]; then
    sleep 1
fi

# One line per connected output: name, preferred mode, EDID hash. --current reads
# the server's state without re-probing, which would make the screens flicker.
OUTPUTS_INFO=$(xrandr --verbose --current | awk '
    function flush() { if (name != "") print name, (mode == "" ? "none" : mode), (edid == "" ? "none" : edid) }
    /^[^ \t]/ { flush(); name = ""; mode = ""; edid = ""; in_edid = 0 }
    /^[^ \t]+ connected/ { name = $1; next }
    name == "" { next }
    /^\tEDID:/ { in_edid = 1; next }
    in_edid && /^\t\t[0-9a-f]+$/ { edid = edid $1; next }
    { in_edid = 0 }
    /^  [0-9]+x[0-9]+ .*\+preferred/ && mode == "" { mode = $1 }
    END { flush() }' |
    while read -r NAME MODE EDID; do
        echo "$NAME $MODE $(md5sum <<< "$EDID" | cut -c1-8)"
    done)

if [ -z "$LAPTOP_OUTPUT" ]; then
    LAPTOP_OUTPUT=$(awk '$1 ~ /^(eDP|LVDS|DSI)/ {print $1; exit}' <<< "$OUTPUTS_INFO")
    LAPTOP_OUTPUT=${LAPTOP_OUTPUT:-eDP-1}
fi
if [ -z "$LAPTOP_MODE" ]; then
    LAPTOP_MODE=$(awk -v laptop="$LAPTOP_OUTPUT" '$1 == laptop && $2 != "none" {print $2}' <<< "$OUTPUTS_INFO")
fi
EXTERNALS_INFO=$(awk -v laptop="$LAPTOP_OUTPUT" '$1 != laptop' <<< "$OUTPUTS_INFO")

mapfile -t EXTERNALS < <(awk '{print $1}' <<< "$EXTERNALS_INFO")
MONITOR=${EXTERNALS[0]}
PORTRAIT=""
if [ ${#EXTERNALS[@]} -ge 2 ]; then
    PORTRAIT=$(awk -v o="$WORK_PORTRAIT_OUTPUT" '$1 == o {print $1; exit}' <<< "$EXTERNALS_INFO")
    PORTRAIT=${PORTRAIT:-${EXTERNALS[1]}}
    # The landscape monitor is the main one, so docked uses it too
    for output in "${EXTERNALS[@]}"; do
        [ "$output" != "$PORTRAIT" ] && MONITOR=$output && break
    done
fi
SETUP=$(awk '{print $3}' <<< "$EXTERNALS_INFO" | sort | paste -sd+)

# Skip hotplug events that didn't change what's connected, e.g. the ones fired
# by this script enabling/disabling outputs. EDIDs count, so swapping monitors
# between ports re-applies the layout.
OUTPUTS=$(awk '{print $1 ":" $3}' <<< "$OUTPUTS_INFO" | sort | paste -sd,)
if [ "$1" == "hotplug" ] && [ "$OUTPUTS" == "$(cat "$RUNDIR/i3_layout_outputs" 2>/dev/null)" ]; then
    echo "Outputs unchanged ($OUTPUTS), nothing to do"
    exit 0
fi
echo "$OUTPUTS" > "$RUNDIR/i3_layout_outputs"

if [ -z "$MONITOR" ]; then
    # Nothing else is possible, and the remembered layouts are left untouched
    echo "No external monitor!"
    LAYOUT=laptop
else
    echo "Found external monitor(s): ${EXTERNALS[*]} (setup: $SETUP)"
    STATEFILE="$STATEDIR/$SETUP"
    LAYOUT=$(cat "$STATEFILE" 2>/dev/null)

    INDEX=-1
    for i in "${!LAYOUTS[@]}"; do
        [ "${LAYOUTS[$i]}" == "$LAYOUT" ] && INDEX=$i
    done
    if [ $INDEX -lt 0 ]; then
        LAYOUT=$DEFAULT_LAYOUT
        for i in "${!LAYOUTS[@]}"; do
            [ "${LAYOUTS[$i]}" == "$LAYOUT" ] && INDEX=$i
        done
    fi

    case "$1" in
        toggle)
            LAYOUT=${LAYOUTS[$(( (INDEX + 1) % ${#LAYOUTS[@]} ))]} ;;
        prev)
            LAYOUT=${LAYOUTS[$(( (INDEX - 1 + ${#LAYOUTS[@]}) % ${#LAYOUTS[@]} ))]} ;;
        laptop|docked|extend)
            LAYOUT=$1 ;;
    esac

    echo "$LAYOUT" > "$STATEFILE"

    # Use the external monitor's preferred mode rather than assuming 4K
    EXT_MODE=$(awk -v m="$MONITOR" '$1 == m {print $2}' <<< "$EXTERNALS_INFO")
    [ -n "$PORTRAIT" ] && [ -n "$WORK_LANDSCAPE_MODE" ] && EXT_MODE=$WORK_LANDSCAPE_MODE
    if [ -n "$PORTRAIT" ]; then
        PORTRAIT_MODE=${WORK_PORTRAIT_MODE:-$(awk -v m="$PORTRAIT" '$1 == m {print $2}' <<< "$EXTERNALS_INFO")}
    fi
fi
echo "Applying layout: $LAYOUT"

# mode_args <mode>: xrandr's arguments for a mode, or its preferred one
mode_args() {
    if [ -n "$1" ] && [ "$1" != "none" ]; then
        echo "--mode $1"
    else
        echo "--auto"
    fi
}

move_workspaces() { # one output per workspace, starting from workspace 1
    local ws=1
    for output in "$@"; do
        i3-msg -q "workspace number $ws; move workspace to output $output"
        ws=$((ws + 1))
    done
    i3-msg -q "workspace number 1"
}

# An unplugged output keeps its CRTC (and its share of the screen) until switched
# off, so this lists active outputs whether they're connected or not
mapfile -t ACTIVE < <(xrandr --current |
    awk '$2 ~ /connected$/ && / [0-9]+x[0-9]+\+[0-9]+\+[0-9]+ / {print $1}')

# off_args <output...>: xrandr's arguments to switch off every other active output
off_args() {
    local output keep
    for output in "${ACTIVE[@]}"; do
        for keep in "$@"; do
            [ "$output" == "$keep" ] && continue 2
        done
        echo "--output $output --off"
    done
}

# One xrandr call per layout, so outputs are switched on and off together and
# there is never a moment with no active output
case "$LAYOUT" in
    docked)
        xrandr --output "$MONITOR" $(mode_args "$EXT_MODE") --pos 0x0 --primary --output "$LAPTOP_OUTPUT" --off \
            $(off_args "$MONITOR" "$LAPTOP_OUTPUT")
        move_workspaces "$MONITOR" "$MONITOR" "$MONITOR" "$MONITOR" "$MONITOR" "$MONITOR"
        ;;
    extend)
        if [ -n "$PORTRAIT" ]; then
            # Work: portrait | landscape | laptop
            xrandr --output "$PORTRAIT" $(mode_args "$PORTRAIT_MODE") --rotate "$WORK_PORTRAIT_ROTATION" \
                --pos "$WORK_PORTRAIT_POS" \
                --output "$MONITOR" $(mode_args "$EXT_MODE") --rotate normal --primary --pos "$WORK_LANDSCAPE_POS" \
                --output "$LAPTOP_OUTPUT" $(mode_args "$LAPTOP_MODE") --pos "$WORK_LAPTOP_POS" \
                $(off_args "$PORTRAIT" "$MONITOR" "$LAPTOP_OUTPUT")
            move_workspaces "$MONITOR" "$MONITOR" "$MONITOR" "$PORTRAIT" "$LAPTOP_OUTPUT" "$LAPTOP_OUTPUT"
        else
            # Home: laptop | monitor
            xrandr --output "$LAPTOP_OUTPUT" $(mode_args "$LAPTOP_MODE") --pos "$HOME_LAPTOP_POS" \
                --output "$MONITOR" $(mode_args "$EXT_MODE") --rotate normal --primary --pos "$HOME_MONITOR_POS" \
                $(off_args "$MONITOR" "$LAPTOP_OUTPUT")
            move_workspaces "$MONITOR" "$LAPTOP_OUTPUT" "$MONITOR" "$LAPTOP_OUTPUT" "$MONITOR" "$LAPTOP_OUTPUT"
        fi
        ;;
    laptop)
        xrandr --output "$LAPTOP_OUTPUT" $(mode_args "$LAPTOP_MODE") --pos 0x0 --primary \
            $(off_args "$LAPTOP_OUTPUT")
        ;;
esac

# Bars are per-monitor and the wallpaper is per-output, so redo both.
# 9>&- so the bars don't inherit (and hold) the lock.
~/.config/polybar/launch.sh 9>&-
~/.config/i3/scripts/wallpaper.sh

if [ -n "$1" ] && [ "$1" != "apply" ]; then
    notify-send -a Display -t 1500 "Display layout: $LAYOUT"
fi
