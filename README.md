# dotfiles-i3

AI converted arch hyprland config for mint i3.

i3 on Linux Mint 22 (X11), ported from [jozedash/dotfiles](https://github.com/jozedash/dotfiles): the same keybindings, gaps, theme switcher, Waybar-style Polybar, Wofi-style rofi, dock/monitor layout toggle, Chinese input, update download and security scan.

## Install

```sh
git clone https://github.com/jozedash/dotfiles-i3 ~/dotfiles-i3
~/dotfiles-i3/install.sh
```

The script installs the packages and JetBrainsMono Nerd Font, then symlinks `i3`, `polybar`, `picom`, `rofi`, `dunst`, `kitty`, `fcitx5`, `fontconfig`, `udiskie`, `theme` and `systemd/user` into `~/.config`. Any existing configs are moved to `*.bak_<date>`. It then renders the theme, switches the input method to fcitx5, copies `usr/` and `etc/` into the system and enables the timers. It also builds [i3lock-color](https://github.com/Raymo111/i3lock-color) into `/usr/local` with `install-i3lock-color.sh`, because Mint doesn't package it. Stock i3lock still works, but the lock screen loses its live clock and coloured indicator. Choose **i3** at the login screen afterwards. Cinnamon stays installed and selectable.

It's safe to run again, e.g. after pulling changes.

| Component | Replaces (Hyprland setup) |
|---|---|
| i3 | Hyprland |
| picom | Hyprland rounding, blur, shadows and inactive opacity |
| Polybar | Waybar |
| rofi | Wofi |
| dunst | swaync |
| i3lock-color + xss-lock + xautolock | hyprlock + hypridle |
| feh | hyprpaper |
| CopyQ | cliphist |
| `pick_pixel.py` (python-xlib) | hyprpicker |
| `outputs_watch.py` (RandR events) | Hyprland's `monitor.added`/`monitor.removed` |
| `apt-download.timer` | `pacman-download.timer` |

## Keybindings

| Keys | Action |
|---|---|
| Super+Q / B / E / Shift+C | Terminal (kitty) / Brave / Thunderbird / VS Code |
| Super+F | File manager (Nemo) |
| Super+R | App launcher |
| Super+C | Close window |
| Super+V | Toggle floating |
| Super+L | Lock |
| Super+M | Exit i3 (no confirmation) |
| Super+P / Shift+P | Next / previous monitor layout (laptop → docked → extend → gaming) |
| Super+J / Shift+J | Toggle split direction / toggle tabbed |
| Super+U | Install downloaded updates |
| Super+Shift+U | Unmount all USB drives |
| Super+Shift+T | Toggle dark/light theme |
| Super+Arrows | Move focus |
| Super+Shift+Arrows | Move window |
| Super+Ctrl+Arrows | Resize |
| Super+1–0 / Shift+1–0 | Switch workspace / move window there and follow |
| Super+S | Timesheet utility |
| Super+Ctrl+S / Super+Shift+S | Show scratchpad / send window to scratchpad |
| Super+Shift+F | Fullscreen |
| Super+Shift+R | Restart i3 |
| Print / Super+Shift+Print | Screenshot area to clipboard / to file |
| Ctrl+Space | Switch between the gb keyboard and pinyin |

## Theme

All colours come from one theme: an accent pair (primary + secondary) and a dark or light mode. GTK builds on stock Adwaita.

* Click the palette icon on the bar for the picker: click one square for the primary, then another for the secondary. Up to 3 favourite pairs (star the current pair; right-click a favourite to remove it). Escape or focusing another window closes it.
* Right-click the icon for the next favourite; middle-click, or Super+Shift+T, toggles dark/light.
* From a terminal: `~/.config/theme/theme-apply --pair '#ff00ff' '#8800ff'`, `--mode light`, `--toggle-mode`, ... (`--help` lists them).
* For plain gradients instead of the photos, set `STYLE=plain` in `.config/i3/scripts/wallpaper.sh`: `Pictures/wallpaper.jpg` in dark mode, its pink-to-white `Pictures/wallpaper-light.jpg` in light.

Everything follows live: i3 borders, i3lock, Polybar, rofi, dunst, fcitx5, kitty, the wallpaper (cherry blossoms at Jiming Temple in light mode, Hongya Cave at night in dark; credits in `.config/i3/wallpapers/CREDITS.md`), GTK apps (Nemo, file pickers), libadwaita apps, Firefox and Brave (dark/light) and the Papirus icons (dark/light).

The GTK and icon themes are set in Cinnamon's GSettings, which its xsettings daemon (started by the i3 config) serves to running apps. Cinnamon reads the same settings, so it follows the theme too.

How it works: the choice is saved in `~/.local/state/dotfiles-theme/state.json`. `.config/theme/theme-apply` renders each program's colour file from `.config/theme/templates/` and tells running programs to reload. `theme.py`, `palette.json` and the GTK, kitty and fcitx5 templates are kept identical to the Arch repo; `theme-apply` and `theme-popup` differ only in their X11 targets, reloads and window placement.

## Polybar

| Module | Click | Right-click |
|---|---|---|
| Weather (wttr.in) | Open wttr.in | |
| Memory / CPU / temperature | htop / htop / btop | |
| Updates (count; restart icon when a reboot is needed; shield when only config files need merging) | Install them | |
| USB drives mounted by udiskie | Open in Nemo | Unmount all |
| Notifications | Show the last one again | Do not disturb |
| Clipboard | CopyQ history menu | |
| Eye | Stay awake (no lock, blanking or suspend) | |
| Colour picker (swatch of the last colour) | Pick and copy a colour | |
| Palette | Theme picker | Next favourite (middle: dark/light) |
| Bluetooth | Blueman | |

## Idle

Lock at 6 minutes, screen off at 7, suspend at 30. The eye icon switches all three off and back on.

## Chinese input (fcitx5)

Ctrl+Space switches between the gb keyboard and pinyin. The candidate window's font is Noto Sans CJK SC 11 (Mint's name for Source Han Sans). `install.sh` makes fcitx5 the input method with `im-config`, which starts it and sets `GTK_IM_MODULE` and friends at login, so log out once afterwards.

fcitx5 rewrites the files in `.config/fcitx5/` when you change settings in fcitx5-configtool (and on its autosave), replacing any comments with its own. After changing input settings, review `git diff .config/fcitx5` and commit or revert.

## Updates

Updates are downloaded automatically but installed by hand:

* `apt-download.timer` runs weekly (catching up after the laptop was off). It refreshes the package lists and downloads pending updates into apt's cache without installing anything.
* You then get a notification, and the Polybar updates icon shows how many are waiting.
* Click the icon or press Super+U to run `sudo apt full-upgrade`. Mint's Update Manager also installs from the same cache.
* If a download fails, the notification points to [docs/apt-download-failures.md](docs/apt-download-failures.md).

To download now: `sudo systemctl start apt-download.service`.

## Security scan

`security-scan.timer` runs `/usr/local/bin/security-scan` as root once a week (catching up after the laptop was off). It takes a few minutes at low priority. Each check writes one line per finding:

| Finding | Meaning | What to do |
|---|---|---|
| `firewall:` | ufw isn't active | `sudo ufw enable` |
| `port:` | Something listens on a non-loopback address | Find it with `sudo ss -tulpn`; stop or firewall it if you don't need it |
| `security:` | An installed package has a security update waiting | Update |
| `altered:` | A package file differs from the package (`debsums`) | Reinstall the package (`sudo apt install --reinstall <pkg>`); if you didn't change it, investigate |
| `unowned:` | An executable or systemd unit no package installed | Expected for this repo's files in `/usr/local/bin` and `/etc/systemd/system`; anything else, find out where it came from |
| `foreign:` | A package no repository has (installed from a `.deb`) | Gets no updates from apt; remove it if unneeded |
| `rkhunter:` | rkhunter warning | Details in `/var/log/rkhunter.log` |

* You get a critical notification (`security-scan-notify.path`) listing findings that weren't in the previous scan, so each one only alerts once. The first scan reports everything.
* `/var/lib/security-scan/report` has every current finding plus the full output of each check.
* The script and units are copied into `/usr` and `/etc` by `install.sh`, not linked. After editing them, run `./install.sh` again.

To scan now: `sudo systemctl start security-scan.service`, then `cat /var/lib/security-scan/report`.

## Monitor layouts

`toggle_layout.sh` remembers the chosen layout per monitor setup (keyed on the external monitors' EDIDs), so home and office monitors each keep their own; a new setup starts in extend. Plugging or unplugging a monitor re-applies the remembered layout, falling back to the laptop screen. It logs to `$XDG_RUNTIME_DIR/i3_toggle_layout.log`.

## Machine-specific values

The laptop screen (`eDP`/`LVDS`/`DSI`), its mode, the battery, charger and backlight are detected. To override any of them, create `~/.config/dotfiles-host/host.sh` with any of `LAPTOP_OUTPUT`, `LAPTOP_MODE`, `BATTERY`, `ADAPTER` or `BACKLIGHT`. The CPU temperature uses the `x86_pkg_temp` zone (Intel); change `zone-type` in `.config/polybar/config.ini` on AMD.

## What isn't in git

| Item | Why | Source |
|---|---|---|
| `~/.local/state/dotfiles-theme/state.json` | Chosen accent pair, mode and favourites | `theme-apply` |
| Colour files (`i3/colors.conf`, `polybar/colors.ini`, `rofi/colors.rasi`, ...), `~/.local/share/fcitx5/themes/hypr/`, the GTK3 theme `~/.local/share/themes/Hypr-*`, `~/.config/gtk-{3,4}.0/` settings and CSS | Generated from `.config/theme/templates/` for the current theme | `theme-apply` (`.gitignore`) |
| `~/.local/state/i3/layouts/` | Remembered layout per monitor setup | `toggle_layout.sh` |
| `fcitx5/conf/cached_layouts`, pinyin user dictionary | Generated cache, personal typing history | fcitx5 (`.gitignore`) |
| `/var/lib/apt-download/`, `/var/lib/security-scan/` | Runtime state | Timers |
