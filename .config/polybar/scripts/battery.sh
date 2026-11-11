#!/usr/bin/env bash
# Usage: battery.sh toggle
#   Switches the battery between Standard charging and the firmware's conservation mode:
#   Long_Life where offered (Lenovo), else Custom (Dell, capped at its own end threshold).
#   Writing charge_types needs etc/udev/rules.d/90-charge-types.rules.
[ "$1" == "toggle" ] || { echo "Usage: battery.sh toggle" >&2; exit 2; }

DIR="/sys/class/power_supply/${BATTERY:-$(basename "$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)")}"
TYPES=$(cat "$DIR/charge_types" 2>/dev/null)

# charge_types looks like "Trickle Fast [Standard] Adaptive Custom"; the bracketed one is active
MODE=$(grep -oP '\[\K[^]]+' <<<"$TYPES")
CONSERVE=$(grep -owE 'Long_Life|Custom' <<<"${TYPES//[][]/}" | head -1)
if [ -z "$MODE" ] || [ -z "$CONSERVE" ]; then
    notify-send -a Battery "This battery has no conservation charge mode"
    exit 1
fi

[ "$MODE" == "$CONSERVE" ] && NEW=Standard || NEW=$CONSERVE
if ! echo "$NEW" > "$DIR/charge_types" 2>/dev/null; then
    notify-send -u critical -a Battery "Couldn't change the charge mode" \
        "$DIR/charge_types isn't writable. Is the udev rule installed?"
    exit 1
fi

case "$NEW" in
    Long_Life) notify-send -a Battery "Long Life on (holds ~60%)" ;;
    Custom) notify-send -a Battery "Conservation on (stops at $(cat "$DIR/charge_control_end_threshold")%)" ;;
    *) notify-send -a Battery "Conservation off (charges to 100%)" ;;
esac
