#!/usr/bin/env bash
# Port of the waybar powerdraw module; empty output hides it on AC.
for f in /sys/class/power_supply/BAT*/power_now; do
    [ -r "$f" ] && echo "󰠰 $(( $(cat "$f") / 1000000 ))W" && exit
done
echo ""
