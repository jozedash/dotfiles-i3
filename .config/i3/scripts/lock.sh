#!/usr/bin/env bash
# Styled after ~/.config/hypr/hyprlock.conf: blurred screenshot, clock and date top-right,
# magenta/purple input indicator. Extra args (e.g. --nofork from xss-lock) pass through.
pgrep -x i3lock >/dev/null && exit 0

font=Monospace

# Only i3lock-color (install-i3lock-color.sh) can blur, draw a clock and recolour the indicator.
if i3lock --version 2>&1 | grep -qi color; then
    exec i3lock "$@" \
        --blur 8 \
        --clock --force-clock \
        --time-str="%H:%M" --time-font="$font" --time-size=90 --time-color=ffffffff \
        --time-align=2 --time-pos="x+w-30:y+110" \
        --date-str="%A, %d %B %Y" --date-font="$font" --date-size=25 --date-color=ffffffff \
        --date-align=2 --date-pos="x+w-30:y+160" \
        --ind-pos="x+w/2:y+h/2+20" --radius=60 --ring-width=3 \
        --inside-color=00000000 --ring-color=ff00ffee --line-color=00000000 --separator-color=00000000 \
        --keyhl-color=8800ffee --bshl-color=ff6633ee \
        --insidever-color=00000000 --ringver-color=00ff99ee \
        --insidewrong-color=00000000 --ringwrong-color=ff0066ee \
        --verif-text="" --wrong-text="" --noinput-text="" \
        --greeter-text="Input password..." --greeter-font="$font" --greeter-size=16 \
        --greeter-color=8f8f8fff --greeter-pos="x+w/2:y+h/2+120" \
        --pass-media-keys --pass-volume-keys
fi

# Stock i3lock fallback: bake blur and clock into an image (the clock will not tick).
image="${XDG_RUNTIME_DIR:-/tmp}/lock.png"
python3 - "$image" "$(fc-match -f '%{file}' "$font")" <<'PYEOF'
import sys
import time
from PIL import ImageDraw, ImageFilter, ImageFont, ImageGrab

path, font_file = sys.argv[1], sys.argv[2]
img = ImageGrab.grab().filter(ImageFilter.GaussianBlur(12))
draw = ImageDraw.Draw(img)
right = img.width - 30
draw.text((right, 20), time.strftime("%H:%M"), font=ImageFont.truetype(font_file, 110), fill="white", anchor="ra")
draw.text((right, 150), time.strftime("%A, %d %B %Y"), font=ImageFont.truetype(font_file, 32), fill="white", anchor="ra")
img.save(path)
PYEOF

exec i3lock "$@" --image="$image" --show-failed-attempts
