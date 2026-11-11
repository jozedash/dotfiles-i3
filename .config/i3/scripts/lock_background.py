#!/usr/bin/env python3
"""Builds the lock screen's background: a blurred screenshot with each output's logo.

Usage: lock_background.py <out.raw|out.png> <primary RRGGBB[AA]> <secondary RRGGBB[AA]> [--clock FONT_FILE]
A .raw output is RGBX pixels for i3lock-color's --raw and prints its "WxH"; .png is for stock i3lock.
--clock bakes in the time and date, for stock i3lock, which can't draw them.

Blurring here rather than with i3lock-color's --blur cuts ~4 s from a lock: its blur works at full
resolution across the whole root (7920x3840 docked), whereas this blurs a 1/SHRINK copy.
"""
import argparse
import os
import re
import subprocess
import time
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageGrab

# Shrinking by SHRINK then blurring by SIGMA approximates i3lock-color's --blur 8 at full size
SHRINK = 4
SIGMA = 2

# White on transparent; coloured with the theme's gradient at lock time
LOGO = Path(__file__).resolve().parent.parent / "lock" / "mint-logo.png"
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


def colour(value):
    """RRGGBB[AA] -> (r, g, b, a)."""
    return tuple(int(value[i:i + 2], 16) for i in range(0, 8, 2)) if len(value) == 8 \
        else (*(int(value[i:i + 2], 16) for i in range(0, 6, 2)), 255)


def coloured_logo(primary, secondary):
    """The logo in a primary top-left to secondary bottom-right gradient, as in hyprlock's."""
    mask = Image.open(LOGO).getchannel("A")
    vertical = Image.linear_gradient("L").resize(mask.size)
    horizontal = Image.linear_gradient("L").rotate(90).resize(mask.size)
    diagonal = ImageChops.add(horizontal, vertical, scale=2)
    logo = Image.composite(Image.new("RGBA", mask.size, colour(secondary)),
                           Image.new("RGBA", mask.size, colour(primary)), diagonal)
    logo.putalpha(ImageChops.multiply(logo.getchannel("A"), mask))
    return logo


def background(primary, secondary):
    shot = ImageGrab.grab()
    blurred = shot.reduce(SHRINK).filter(ImageFilter.GaussianBlur(SIGMA))
    img = blurred.resize(shot.size, Image.BILINEAR).convert("RGBA")
    try:
        logo = coloured_logo(primary, secondary)
    except OSError:
        return img
    # ImageGrab's image starts at the root origin, so output positions index it directly
    for width, height, x, y in outputs():
        size = round(logo.width * height * LOGO_HEIGHT / logo.height), round(height * LOGO_HEIGHT)
        img.alpha_composite(logo.resize(size, Image.LANCZOS),
                            (x + LOGO_MARGIN, y + height - LOGO_MARGIN - size[1]))
    return img


def draw_clock(img, font_file):
    draw = ImageDraw.Draw(img)
    right = img.width - 30
    draw.text((right, 20), time.strftime("%H:%M"),
              font=ImageFont.truetype(font_file, 110), fill="white", anchor="ra")
    draw.text((right, 150), time.strftime("%A, %d %B %Y"),
              font=ImageFont.truetype(font_file, 32), fill="white", anchor="ra")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("out")
    parser.add_argument("primary")
    parser.add_argument("secondary")
    parser.add_argument("--clock", metavar="FONT_FILE")
    args = parser.parse_args()

    img = background(args.primary, args.secondary)
    if args.clock:
        draw_clock(img, args.clock)

    # A screenshot, so readable by its owner only
    partial = f"{args.out}.tmp"
    with open(os.open(partial, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "wb") as file:
        if args.out.endswith(".raw"):
            # RGBA bytes are i3lock's rgbx layout: it ignores the fourth byte
            file.write(img.tobytes())
        else:
            img.save(file, "PNG", compress_level=1)
    os.replace(partial, args.out)
    if args.out.endswith(".raw"):
        print(f"{img.width}x{img.height}")


if __name__ == "__main__":
    main()
