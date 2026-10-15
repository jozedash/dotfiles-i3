#!/usr/bin/env python3
"""Waybar-style workspaces for Polybar: 1-6 always shown, plus any higher ones in use."""
import os
import sys

try:
    from i3ipc import Connection, Event
except ImportError:
    sys.exit("python3-i3ipc is not installed")

PERSISTENT = range(1, 7)
ACTIVE, DEFAULT = "", ""
ACCENT, URGENT = "#ff00ff", "#ff0000"
MONITOR = os.environ.get("MONITOR", "")


def render(i3, _event=None):
    existing = {ws.num: ws for ws in i3.get_workspaces()}
    numbers = sorted(set(PERSISTENT) | {n for n in existing if n > 0})
    parts = []
    for n in numbers:
        ws = existing.get(n)
        # "visible" rather than "focused" so each monitor highlights the workspace it shows.
        if ws is not None and ws.visible and ws.output == MONITOR:
            icon = f"%{{F{ACCENT}}}{ACTIVE}%{{F-}}"
        elif ws is not None and ws.urgent:
            icon = f"%{{F{URGENT}}}{DEFAULT}%{{F-}}"
        else:
            icon = DEFAULT
        parts.append(f"%{{A1:i3-msg -q workspace number {n}:}} {icon} %{{A}}")
    print("".join(parts), flush=True)


i3 = Connection()
i3.on(Event.WORKSPACE, render)
i3.on(Event.OUTPUT, render)
render(i3)
i3.main()
