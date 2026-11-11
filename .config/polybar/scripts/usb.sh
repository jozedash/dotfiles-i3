#!/usr/bin/env bash
# Drives udiskie has mounted under /media/$USER. Prints nothing (hiding the
# module) when there are none. udiskie's event_hook refreshes it.
COUNT=$(findmnt -rn -o TARGET | grep -c "^/media/$USER/")
[ "$COUNT" -gt 0 ] || exit 0
[ "$COUNT" -gt 1 ] && echo "󰕓 $COUNT" || echo "󰕓"
