#!/usr/bin/env bash
#
# xrandr port of ~/.config/hypr/toggle_layout.sh.
#
# Usage: toggle_layout.sh [apply|hotplug|toggle|prev|laptop|docked|extend|gaming]
#   apply (default) - apply the remembered layout for the currently connected monitors
#   hotplug         - like apply, but only acts if the set of connected outputs changed
#   toggle / prev   - cycle forwards / backwards through the layouts
#   <layout>        - jump straight to that layout
#
# The chosen layout is remembered per monitor setup (keyed on the external monitors'
# EDIDs), so e.g. the home and office monitors each keep their own layout.

STATEDIR="${XDG_STATE_HOME:-$HOME/.local/state}/i3/layouts"
RUNDIR="${XDG_RUNTIME_DIR:-/tmp}"
GAMING_MODE="1600x900"
# LAPTOP_OUTPUT and LAPTOP_MODE are detected below (eDP/LVDS/DSI output, preferred
# mode) unless set in this optional machine-specific file
HOST_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles-host/host.sh"
[ -f "$HOST_CONF" ] && . "$HOST_CONF"
LAPTOP_MODE=${LAPTOP_MODE%@*}  # host.sh may give Hyprland's "WxH@rate"

# Add layouts here, in the order toggle cycles through them
LAYOUTS=(laptop docked extend gaming)
DEFAULT_LAYOUT=extend # Used the first time a new monitor setup is seen

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
LAPTOP_H=$(grep -oP '^\d+x\K\d+' <<< "$LAPTOP_MODE")
EXTERNALS_INFO=$(awk -v laptop="$LAPTOP_OUTPUT" '$1 != laptop' <<< "$OUTPUTS_INFO")

mapfile -t EXTERNALS < <(awk '{print $1}' <<< "$EXTERNALS_INFO")
MONITOR=${EXTERNALS[0]}
SETUP=$(awk '{print $3}' <<< "$EXTERNALS_INFO" | sort | paste -sd+)

# Skip hotplug events that didn't change what's connected, e.g. the ones fired
# by this script enabling/disabling outputs
OUTPUTS=$(awk '{print $1}' <<< "$OUTPUTS_INFO" | sort | paste -sd,)
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
        laptop|docked|extend|gaming)
            LAYOUT=$1 ;;
    esac

    echo "$LAYOUT" > "$STATEFILE"

    # Use the external monitor's preferred mode rather than assuming 4K
    EXT_MODE=$(awk -v m="$MONITOR" '$1 == m {print $2}' <<< "$EXTERNALS_INFO")
    EXT_W=$(grep -oP '^\d+(?=x)' <<< "$EXT_MODE")
    EXT_H=$(grep -oP '^\d+x\K\d+' <<< "$EXT_MODE")
    if ! xrandr --current | awk -v m="$MONITOR" '/^[^ ]/ {on = ($1 == m)} on {print $1}' |
        grep -qx "$GAMING_MODE"; then
        GAMING_MODE=$EXT_MODE
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

# One xrandr call per layout, so outputs are switched on and off together and
# there is never a moment with no active output
case "$LAYOUT" in
    docked)
        xrandr --output "$MONITOR" $(mode_args "$EXT_MODE") --pos 0x0 --primary --output "$LAPTOP_OUTPUT" --off
        move_workspaces "$MONITOR" "$MONITOR" "$MONITOR" "$MONITOR" "$MONITOR" "$MONITOR"
        ;;
    gaming)
        # Lower resolution
        xrandr --output "$MONITOR" $(mode_args "$GAMING_MODE") --pos 0x0 --primary --output "$LAPTOP_OUTPUT" --off
        move_workspaces "$MONITOR" "$MONITOR" "$MONITOR" "$MONITOR" "$MONITOR" "$MONITOR"
        ;;
    extend)
        # Laptop sits bottom-right of the external monitor
        xrandr --output "$MONITOR" $(mode_args "$EXT_MODE") --pos 0x0 --primary \
            --output "$LAPTOP_OUTPUT" $(mode_args "$LAPTOP_MODE") \
            --pos "${EXT_W:-1920}x$(( ${EXT_H:-1080} - ${LAPTOP_H:-1080} ))"
        move_workspaces "$MONITOR" "$LAPTOP_OUTPUT" "$MONITOR" "$LAPTOP_OUTPUT" "$MONITOR" "$LAPTOP_OUTPUT"
        ;;
    laptop)
        OFF=()
        for output in "${EXTERNALS[@]}"; do
            OFF+=(--output "$output" --off)
        done
        xrandr --output "$LAPTOP_OUTPUT" $(mode_args "$LAPTOP_MODE") --pos 0x0 --primary "${OFF[@]}"
        ;;
esac

# Bars are per-monitor and the wallpaper is per-output, so redo both.
# 9>&- so the bars don't inherit (and hold) the lock.
~/.config/polybar/launch.sh 9>&-
~/.config/i3/scripts/wallpaper.sh

if [ -n "$1" ] && [ "$1" != "apply" ]; then
    notify-send -a Display -t 1500 "Display layout: $LAYOUT"
fi
