#!/usr/bin/env bash
# Battery power draw in watts. Prints nothing (hiding the module) unless running on
# battery, or on a machine without a battery.
for dir in /sys/class/power_supply/BAT*; do
    [ "$(cat "$dir/status" 2>/dev/null)" == "Discharging" ] || continue
    # Some batteries (e.g. Dell) report current and voltage instead of power
    POWER=$(cat "$dir/power_now" 2>/dev/null ||
        awk -v i="$(cat "$dir/current_now")" -v v="$(cat "$dir/voltage_now")" 'BEGIN { printf "%d", i * v / 1000000 }')
    [ "${POWER:-0}" -gt 0 ] || continue
    awk -v p="$POWER" 'BEGIN { printf "󰠰 %.1fW\n", p / 1000000 }'
    exit
done
