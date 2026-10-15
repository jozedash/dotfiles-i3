# dotfiles-i3

AI converted arch hyprland config for mint i3.

i3 on Linux Mint 22 (X11), ported from [jozedash/dotfiles](https://github.com/jozedash/dotfiles): the same keybindings, gaps, magenta borders, Waybar-style Polybar, Wofi-style rofi and the dock/monitor layout toggle.

## Install

```sh
git clone https://github.com/jozedash/dotfiles-i3 ~/dotfiles-i3
~/dotfiles-i3/install.sh
```

The script installs the packages and JetBrainsMono Nerd Font, then symlinks `i3`, `polybar`, `picom`, `rofi` and `dunst` into `~/.config`. Any existing configs are moved to `*.bak_<date>`. Choose **i3** at the login screen afterwards. Cinnamon stays installed and selectable.

| Component | Replaces (Hyprland setup) |
|---|---|
| i3 | Hyprland |
| picom | Hyprland rounding, blur, shadows and inactive opacity |
| Polybar | Waybar |
| rofi | Wofi |
| dunst | swaync |
| i3lock + xss-lock | hyprlock + hypridle |

## Keybindings

| Keys | Action |
|---|---|
| Super+Q / B / E / Shift+C | Terminal (kitty) / Firefox / Thunderbird / VS Code |
| Super+F | File manager (Nemo) |
| Super+R | App launcher |
| Super+C | Close window |
| Super+V | Toggle floating |
| Super+L | Lock |
| Super+M | Exit i3 (no confirmation) |
| Super+P / Shift+P | Cycle monitor layout (laptop → docked → extended → gaming) / reset to laptop |
| Super+J / Shift+J | Toggle split direction / toggle tabbed |
| Super+Arrows | Move focus |
| Super+Shift+Arrows | Move window |
| Super+Ctrl+Arrows | Resize |
| Super+1–0 / Shift+1–0 | Switch workspace / move window there and follow |
| Super+S / Shift+S | Show scratchpad / send window to scratchpad |
| Super+Shift+F | Fullscreen |
| Super+Shift+R | Restart i3 (applies config changes) |
| Print / Super+Shift+Print | Screenshot area to clipboard / to file |

## Machine-specific values

These match the laptop the config was written on. Change them if your hardware differs:

- `.config/i3/scripts/toggle_layout.sh` sets the internal panel to `eDP-1` and uses 3840×2160 and 1600×900 modes for the external monitor.
- `.config/polybar/config.ini` sets the backlight to `intel_backlight` and the battery to `BAT0`/`AC`.

## Wallpaper

`wallpaper.sh` shows the first `~/Pictures/wallpaper.*` it finds. The installer copies `Pictures/wallpaper.jpg` there if there isn't one already.
