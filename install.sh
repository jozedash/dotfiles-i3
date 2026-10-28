#!/usr/bin/env bash
# Installs the i3 setup on Linux Mint. Run as your user (not root): ./install.sh
# Safe to run again, e.g. after pulling changes.
set -euo pipefail

repo=$(cd "$(dirname "$0")" && pwd)

sudo apt-get update
packages=(
    # Desktop
    i3 i3lock xss-lock xautolock dex rofi dunst picom polybar feh kitty
    brightnessctl playerctl python3-i3ipc python3-xlib fonts-noto-color-emoji
    # Bar modules: drives, clipboard, colour picker, JSON, monitors
    udiskie copyq xclip jq curl htop btop
    # Theme (.config/theme): GTK for theme-apply and its popup, the icon theme,
    # and rsvg-convert for the fcitx5 theme's images
    python3-gi gir1.2-gtk-3.0 papirus-icon-theme librsvg2-bin
    # Chinese input
    fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-qt5 fcitx5-config-qt
    fonts-noto-cjk
    # Security scan
    debsums rkhunter
)
sudo apt-get install -y "${packages[@]}"

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
for dir in i3 polybar picom rofi dunst kitty fcitx5 fontconfig udiskie theme systemd/user; do
    target="$HOME/.config/$dir"
    mkdir -p "$(dirname "$target")"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mv "$target" "$target.bak_$stamp"
        echo "Backed up $target to $target.bak_$stamp"
    fi
    ln -sfn "$repo/.config/$dir" "$target"
done

# Write the colour files the configs include
"$repo/.config/theme/theme-apply" --no-reload

# Mint's im-config starts the chosen input method and sets GTK_IM_MODULE and friends at login
im-config -n fcitx5

# System files are copied, not linked: a root-run script that links back into your
# home could be edited by anything running as you. Run this script again after editing them.
sudo cp -rv "$repo/usr/." /usr/
sudo cp -rv "$repo/etc/." /etc/
# security-scan's "unowned" check skips the files installed from here
sudo mkdir -p /etc/security-scan
(cd "$repo" && find ./usr ./etc -type f | sed 's#^\.##' | sort) | sudo tee /etc/security-scan/expected > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable --now apt-download.timer security-scan.timer
systemctl --user daemon-reload
systemctl --user enable --now apt-updates-notify.path security-scan-notify.path

"$repo/install-i3lock-color.sh"

if pgrep -x i3 >/dev/null; then
    i3-msg restart
fi
echo "Done. Log out and choose i3 at the login screen (log out and back in if already on i3)."
