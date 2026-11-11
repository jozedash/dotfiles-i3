#!/usr/bin/env python3
"""Crosshair until a click, then print the clicked pixel as #rrggbb (nothing on
Escape or right-click). Reads the root window, which holds what picom actually
composited: grabc reads the client window under the pointer instead, and gets
garbage from translucent (32-bit) windows."""
import sys

try:
    from Xlib import X, Xcursorfont, display
except ImportError:
    sys.exit("python3-xlib is not installed")

d = display.Display()
root = d.screen().root
font = d.open_font("cursor")
cursor = font.create_glyph_cursor(font, Xcursorfont.crosshair, Xcursorfont.crosshair + 1,
                                  (0, 0, 0), (65535, 65535, 65535))
grab = root.grab_pointer(False, X.ButtonPressMask, X.GrabModeAsync, X.GrabModeAsync,
                         X.NONE, cursor, X.CurrentTime)
if grab != X.GrabSuccess:
    sys.exit("couldn't grab the pointer")
root.grab_keyboard(False, X.GrabModeAsync, X.GrabModeAsync, X.CurrentTime)

colour = None
while True:
    event = d.next_event()
    if event.type == X.KeyPress and d.keycode_to_keysym(event.detail, 0) == 0xff1b:  # Escape
        break
    if event.type == X.ButtonPress:
        if event.detail == 1:
            pixel = root.get_image(event.root_x, event.root_y, 1, 1, X.ZPixmap, 0xffffffff).data
            # ZPixmap on a 24/32-bit visual is little-endian BGRx
            colour = f"#{pixel[2]:02x}{pixel[1]:02x}{pixel[0]:02x}"
        break

d.ungrab_pointer(X.CurrentTime)
d.ungrab_keyboard(X.CurrentTime)
d.flush()
if colour:
    print(colour)
