#!/usr/bin/env bash
# Styled after hyprlock.conf in jozedash/dotfiles: blurred screenshot, clock and date top-right,
# Mint logo bottom-left and a password ring in the theme's pair. Extra args pass through to i3lock.
pgrep -x i3lock >/dev/null && exit 0

# Blank 10 min after locking, however it started: DPMS counts idle time, so reset it and shorten
# the timeout while locked, then restore idle.sh's timings once unlocked.
lock() {
    xset s reset +dpms dpms 0 0 600
    i3lock --nofork "$@"
    ~/.config/polybar/scripts/idle.sh apply
}

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

cache="${XDG_RUNTIME_DIR:-/tmp}"
background=~/.config/i3/scripts/lock_background.py

# Only i3lock-color (install-i3lock-color.sh) can draw a clock and recolour the indicator.
# A git build reports a bare commit hash, so also match its maintainer's copyright.
if i3lock --version 2>&1 | grep -qiE 'color|Raymond Li'; then
    # The blurred screenshot and logos as one raw image; failing that, i3lock-color's slower blur
    if size=$(python3 "$background" "$cache/lock.raw" "$primary" "$secondary" 2>/dev/null); then
        image_args=(--raw="$size:rgbx" --image="$cache/lock.raw")
    else
        image_args=(--blur 8)
    fi
    lock "$@" "${image_args[@]}" \
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
    exit
fi

# Stock i3lock fallback: bake blur, logo and clock into an image (the clock will not tick).
python3 "$background" "$cache/lock.png" "$primary" "$secondary" --clock "$(fc-match -f '%{file}' "$font")"
lock "$@" --image="$cache/lock.png" --show-failed-attempts
