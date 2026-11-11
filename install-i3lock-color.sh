#!/usr/bin/env bash
# Builds i3lock-color into /usr/local, which shadows Mint's stock i3lock on PATH.
# Mint/Ubuntu do not package it. Run as your user: ./install-i3lock-color.sh
set -euo pipefail

sudo apt-get install -y autoconf automake pkg-config gcc make libpam0g-dev libcairo2-dev \
    libxcb-xinerama0-dev libxcb-randr0-dev libev-dev libx11-xcb-dev libxkbcommon-dev \
    libxkbcommon-x11-dev libjpeg-turbo8-dev libxcb-util0-dev libxcb-image0-dev \
    libxcb-xkb-dev libxcb-xrm-dev libxcb-composite0-dev libgif-dev

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git clone --depth 1 https://github.com/Raymo111/i3lock-color.git "$tmp/i3lock-color"
cd "$tmp/i3lock-color"
autoreconf -fi
mkdir build && cd build
../configure --prefix=/usr/local --sysconfdir=/etc --disable-sanitizers
make -j"$(nproc)"
sudo make install
hash -r
i3lock --version
