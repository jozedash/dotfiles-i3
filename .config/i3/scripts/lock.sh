#!/usr/bin/env bash
# Styled after hyprlock.conf in jozedash/dotfiles: blurred screenshot, clock and date top-right,
# Mint logo bottom-left and a password ring in the theme's pair. Extra args (e.g. --nofork
# from xss-lock) pass through.
pgrep -x i3lock >/dev/null && exit 0

font="JetBrainsMono Nerd Font"
# Indicator colours follow the theme (written by ~/.config/theme/theme-apply); dark defaults.
primary=ff00ffee
inside=191a1bb2
secondary=8800ffee
backspace=ffd68aee
verify=a8e68aee
wrong=f53c3cee
greeter=969696ff
[ -f ~/.config/i3/lock-colors.sh ] && . ~/.config/i3/lock-colors.sh

# The logo; without it the screen still locks
overlay=$(python3 ~/.config/i3/scripts/lock_overlay.py "$primary" "$secondary" 2>/dev/null) || overlay=
image_args=()
[ -n "$overlay" ] && image_args=(--image="$overlay")

# Only i3lock-color (install-i3lock-color.sh) can blur, draw a clock and recolour the indicator.
# A git build reports a bare commit hash, so also match its maintainer's copyright.
if i3lock --version 2>&1 | grep -qiE 'color|Raymond Li'; then
    exec i3lock "$@" "${image_args[@]}" \
        --blur 8 \
        --clock --force-clock \
        --time-str="%H:%M" --time-font="$font" --time-size=90 --time-color=ffffffff \
        --time-align=2 --time-pos="x+w-30:y+110" \
        --date-str="%A, %d %B %Y" --date-font="$font" --date-size=25 --date-color=ffffffff \
        --date-align=2 --date-pos="x+w-30:y+160" \
        --indicator --ind-pos="x+w/2:y+h/2+20" --radius=60 --ring-width=6 \
        --ring-color="$primary" --inside-color="$inside" \
        --keyhl-color="$secondary" --bshl-color="$backspace" \
        --line-color=00000000 --separator-color=00000000 \
        --ringver-color="$verify" --insidever-color="$inside" \
        --ringwrong-color="$wrong" --insidewrong-color="$inside" \
        --verif-text="Verifying" --wrong-text="Wrong" --noinput-text="" \
        --verif-font="$font" --wrong-font="$font" --verif-size=14 --wrong-size=14 \
        --verif-color="$verify" --wrong-color="$wrong" \
        --greeter-text="Input password..." --greeter-font="$font" --greeter-size=16 \
        --greeter-color="$greeter" --greeter-pos="x+w/2:y+h/2+130" \
        --pass-media-keys --pass-volume-keys
fi

# Stock i3lock fallback: bake blur, overlay and clock into an image (the clock will not tick).
image="${XDG_RUNTIME_DIR:-/tmp}/lock.png"
python3 - "$image" "$(fc-match -f '%{file}' "$font")" "$overlay" <<'PYEOF'
import sys
import time
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageGrab

path, font_file, overlay = sys.argv[1:4]
img = ImageGrab.grab().filter(ImageFilter.GaussianBlur(12)).convert("RGBA")
if overlay:
    art = Image.open(overlay)
    img.alpha_composite(art.crop((0, 0, *img.size)))
draw = ImageDraw.Draw(img)
right = img.width - 30
draw.text((right, 20), time.strftime("%H:%M"), font=ImageFont.truetype(font_file, 110), fill="white", anchor="ra")
draw.text((right, 150), time.strftime("%A, %d %B %Y"), font=ImageFont.truetype(font_file, 32), fill="white", anchor="ra")
img.save(path)
PYEOF

exec i3lock "$@" --image="$image" --show-failed-attempts
