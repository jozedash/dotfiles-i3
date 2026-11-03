#!/usr/bin/env python3
"""Draws the lock screen's logo as one transparent, root-sized PNG for i3lock --image.

Usage: lock_overlay.py <primary RRGGBB[AA]> <secondary RRGGBB[AA]>
Prints the PNG's path. It's cached per layout and colours: encoding takes about a second.

Per output, in hyprlock.conf's layout: the Linux Mint logo bottom-left, in a
primary -> secondary gradient. i3lock-color draws the image once at the root origin
over its blurred screenshot, so each output's logo sits at that output's root position.
"""
import hashlib
import os
import re
import subprocess
import sys
from pathlib import Path

# The logo is read from mint-artwork (GPL-3+) at lock time rather than copied into this repo
LOGO = Path("/usr/share/icons/hicolor/scalable/apps/linuxmint-logo-simple-symbolic.svg")
# The bounds of LOGO's path in its own units; the icon's group transform is dropped
LOGO_BOX = (80, 104, 224, 208)

# hyprlock.conf values: margin, and logo height as a fraction of the output's
LOGO_MARGIN = 30
LOGO_HEIGHT = 0.25

MONITOR = re.compile(r"(\d+)/\d+x(\d+)/\d+\+(\d+)\+(\d+)")


def outputs():
    """(width, height, x, y) of every active output."""
    # --current skips the output re-probe, which takes seconds with docked monitors
    text = subprocess.run(["xrandr", "--current", "--listmonitors"],
                          capture_output=True, text=True, check=True).stdout
    return [tuple(map(int, m.groups())) for m in MONITOR.finditer(text)]


def logo_path():
    """The logo's path data, or None when mint-artwork isn't installed."""
    try:
        match = re.search(r'\sd="([^"]+)"', LOGO.read_text())
    except OSError:
        return None
    return match.group(1) if match else None


def colour(value):
    """RRGGBB[AA] -> (#RRGGBB, opacity)."""
    alpha = int(value[6:8], 16) / 255 if len(value) == 8 else 1
    return f"#{value[:6]}", f"{alpha:.3f}"


def gradient(name, primary, secondary):
    (p, pa), (s, sa) = colour(primary), colour(secondary)
    return (f'<linearGradient id="{name}" x1="0" y1="0" x2="1" y2="1">'
            f'<stop offset="0" stop-color="{p}" stop-opacity="{pa}"/>'
            f'<stop offset="1" stop-color="{s}" stop-opacity="{sa}"/></linearGradient>')


def svg(monitors, logo, primary, secondary):
    # Primary top-left to secondary bottom-right, as in hyprlock's
    parts = ['<defs>', gradient("logo", primary, secondary), '</defs>']
    lx, ly, lw, lh = LOGO_BOX
    for width, height, x, y in monitors:
        scale = height * LOGO_HEIGHT / lh
        top = y + height - LOGO_MARGIN - lh * scale
        parts.append(f'<path fill="url(#logo)" transform="translate({x + LOGO_MARGIN} {top}) '
                     f'scale({scale}) translate({-lx} {-ly})" d="{logo}"/>')
    # Only as big as the outputs reach: i3lock draws it from the root origin
    width = max(x + w for w, _, x, _ in monitors)
    height = max(y + h for _, h, _, y in monitors)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}">'
            + "".join(parts) + "</svg>")


def main():
    primary, secondary = sys.argv[1:3]
    logo = logo_path()
    if not logo:
        sys.exit("lock_overlay.py: no Mint logo (is mint-artwork installed?)")
    image = svg(outputs(), logo, primary, secondary).encode()
    cache = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
    out = cache / f"lock-overlay-{hashlib.sha1(image).hexdigest()[:12]}.png"
    if not out.exists():
        for old in cache.glob("lock-overlay-*.png"):
            old.unlink(missing_ok=True)
        png = subprocess.run(["rsvg-convert", "--format", "png"], input=image,
                             capture_output=True, check=True).stdout
        partial = out.with_suffix(".tmp")
        partial.write_bytes(png)
        partial.replace(out)
    print(out)


if __name__ == "__main__":
    main()
