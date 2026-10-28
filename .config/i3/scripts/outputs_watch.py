#!/usr/bin/env python3
"""Runs toggle_layout.sh hotplug whenever RandR reports an output change, so
unplugging in docked/gaming mode falls back to the laptop screen instead of a
black screen. Stands in for Hyprland's monitor.added/removed events."""
import subprocess
import sys
from pathlib import Path

try:
    from Xlib import display
    from Xlib.ext import randr
except ImportError:
    sys.exit("python3-xlib is not installed")

TOGGLE = Path.home() / ".config/i3/scripts/toggle_layout.sh"

d = display.Display()
if not d.has_extension("RANDR"):
    sys.exit("X server has no RandR")
d.screen().root.xrandr_select_input(randr.RROutputChangeNotifyMask)
# All RRNotify events share one type; the sub-code tells them apart
OUTPUT_CHANGE = d.extension_event.OutputChangeNotify

while True:
    event = d.next_event()
    # One plug fires several events; the script waits for them to settle and
    # skips runs where the connected outputs didn't change.
    if (event.type, getattr(event, "sub_code", None)) == OUTPUT_CHANGE:
        subprocess.Popen([str(TOGGLE), "hotplug"])
