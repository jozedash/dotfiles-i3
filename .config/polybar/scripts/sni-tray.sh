#!/usr/bin/env bash
# Tray window for StatusNotifierItem apps (Avalonia, Electron), which polybar's XEmbed tray can't show.
# The watcher they register with is started by launch.sh.
# Usage: sni-tray.sh [--watch]
#   No argument: open or close the window
#   --watch:     polybar tail; shows the icon and opens the window while GunLink.Applets has tray icons

is_open() { pgrep -u "$UID" -x gtk-sni-tray-st >/dev/null; }
close() { pkill -u "$UID" -x gtk-sni-tray-st; }

open() {
    is_open && return
    # Polybar colours are #AARRGGBB; GTK wants rgba()
    local bg color a r g b
    bg=$(sed -n 's/^background *= *#\(..\)\(..\)\(..\)\(..\)$/\1 \2 \3 \4/p' ~/.config/polybar/colors.ini)
    if [ -n "$bg" ]; then
        read -r a r g b <<<"$bg"
        color="rgba($((16#$r)),$((16#$g)),$((16#$b)),$(awk "BEGIN { print $((16#$a)) / 255 }"))"
    fi
    # Via i3, not as our child: a child inherits polybar's pipes, holds them open after the bar exits and deadlocks it
    # Quoted for i3, which would otherwise split the rgba() at its commas
    i3-msg -q -- "exec --no-startup-id \"gtk-sni-tray-standalone --bottom --end --size 32 ${color:+--color '$color'}\""
}

bus() { dbus-send --session --print-reply "$@" 2>/dev/null; }

# Items are bus names, optionally followed by an object path; the owning process identifies the app
gunlink_present() {
    local item pid
    for item in $(bus --dest=org.kde.StatusNotifierWatcher /StatusNotifierWatcher \
        org.freedesktop.DBus.Properties.Get string:org.kde.StatusNotifierWatcher \
        string:RegisteredStatusNotifierItems | sed -n 's/^ *string "\([^"/]*\).*/\1/p'); do
        pid=$(bus --dest=org.freedesktop.DBus /org/freedesktop/DBus \
            org.freedesktop.DBus.GetConnectionUnixProcessID string:"$item" | awk '/uint32/ { print $2 }')
        [ -n "$pid" ] && tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null | grep -q 'GunLink\.Applets' && return 0
    done
    return 1
}

watch() {
    # Polybar kills only this shell; take dbus-monitor down too
    trap 'pkill -P $$' EXIT
    # Unknown at start, so the first update applies whichever state is current
    local present=unknown now
    update() {
        gunlink_present && now=1 || now=
        # Act only on transitions, so a manual close sticks until the applets restart
        [ "$now" = "$present" ] && return
        present=$now
        if [ -n "$present" ]; then
            echo "󰀻"
            open
        else
            echo ""
            close
        fi
    }
    update
    dbus-monitor --session "type='signal',interface='org.kde.StatusNotifierWatcher'" 2>/dev/null |
        while read -r line; do
            case $line in
                *member=StatusNotifierItem*Registered*) update ;;
            esac
        done
}

case $1 in
    --watch) watch ;;
    *) is_open && close || open ;;
esac
