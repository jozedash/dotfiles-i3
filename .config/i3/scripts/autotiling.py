#!/usr/bin/env python3
"""Approximates Hyprland's dwindle: split along the focused window's longer edge."""
import sys

try:
    from i3ipc import Connection, Event
except ImportError:
    sys.exit("python3-i3ipc is not installed")


def on_focus(i3, _event):
    focused = i3.get_tree().find_focused()
    if focused is None or focused.floating in ("auto_on", "user_on") or focused.fullscreen_mode:
        return
    if focused.parent is not None and focused.parent.layout in ("tabbed", "stacked"):
        return
    rect = focused.rect
    i3.command("split v" if rect.height > rect.width else "split h")


i3 = Connection()
i3.on(Event.WINDOW_FOCUS, on_focus)
i3.on(Event.WINDOW_NEW, on_focus)
# exec_always starts a fresh copy on every i3 restart, so quit with the old i3.
i3.on(Event.SHUTDOWN, lambda conn, _event: conn.main_quit())
i3.main()
