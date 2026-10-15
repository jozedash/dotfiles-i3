#!/usr/bin/env bash
# Cinnamon applies tap-to-click itself; under i3 libinput defaults to off.
xinput list --name-only | grep -i touchpad | while read -r device; do
    xinput set-prop "$device" "libinput Tapping Enabled" 1
    xinput set-prop "$device" "libinput Natural Scrolling Enabled" 0
done
