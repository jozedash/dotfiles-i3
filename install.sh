#!/usr/bin/env bash
# Installs the i3 setup on Linux Mint. Run as your user (not root): ./install.sh
set -euo pipefail

repo=$(cd "$(dirname "$0")" && pwd)

sudo apt-get update
sudo apt-get install -y i3 i3lock xss-lock dex rofi dunst picom polybar feh kitty \
    brightnessctl playerctl python3-i3ipc fonts-noto-color-emoji

# Nerd Font is not packaged for Mint; installed per-user so no root needed.
font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerd"
if [ ! -d "$font_dir" ]; then
    mkdir -p "$font_dir"
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/font.tar.xz" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
    tar -xf "$tmp/font.tar.xz" -C "$font_dir"
    curl -fsSL -o "$tmp/sym.tar.xz" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz
    tar -xf "$tmp/sym.tar.xz" -C "$font_dir"
    rm -rf "$tmp"
    fc-cache -f
fi

# Symlink so edits made in ~/.config land in this repo; existing configs are kept as backups.
stamp=$(date '+%Y-%m-%d_%H%M%S')
mkdir -p "$HOME/.config"
for dir in i3 polybar picom rofi dunst; do
    target="$HOME/.config/$dir"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mv "$target" "$target.bak_$stamp"
        echo "Backed up $target to $target.bak_$stamp"
    fi
    ln -sfn "$repo/.config/$dir" "$target"
done

mkdir -p "$HOME/Pictures"
if ! ls "$HOME"/Pictures/wallpaper.* >/dev/null 2>&1; then
    cp "$repo/Pictures/wallpaper.jpg" "$HOME/Pictures/wallpaper.jpg"
fi

if pgrep -x i3 >/dev/null; then
    i3-msg restart
fi
echo "Done. Log out and choose i3 at the login screen (log out and back in if already on i3)."
