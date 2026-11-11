#!/usr/bin/env bash
# Restarts the tray apps that only read the icon theme when they start, so their
# icons follow a dark/light switch (theme-apply runs this when the icon theme changes).
# nm-applet and fcitx5 follow it live, so they're left alone.

restart() { # process-name command...
    pgrep -x "$1" >/dev/null || return 0
    pkill -x "$1"
    for _ in {1..20}; do
        pgrep -x "$1" >/dev/null || break
        sleep 0.1
    done
    setsid -f "${@:2}" >/dev/null 2>&1 < /dev/null
}

restart blueman-tray blueman-tray
restart mintreport-tray mintreport-tray
# Not mintupdate-launcher: that also refreshes Cinnamon spices and Flatpaks first
restart mintUpdate /usr/lib/linuxmint/mintUpdate/mintUpdate.py
