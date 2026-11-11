#!/usr/bin/env bash
# Bluetooth: off, on, or the number of connected devices.
if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    echo "󰂲"
    exit 0
fi
CONNECTED=$(bluetoothctl devices Connected 2>/dev/null | grep -c '^Device')
[ "$CONNECTED" -gt 0 ] && echo "󰂱 $CONNECTED" || echo "󰂯"
