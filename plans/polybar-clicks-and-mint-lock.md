# Polybar click parity, Mint lock screen, neofetch terminal and wofi-style rofi

## 1. Context

1. The waybar config in jozedash/dotfiles binds clicks and scrolls on most modules. Polybar matches some of them already, gets some wrong and is missing others.
2. The i3 lock (`.config/i3/scripts/lock.sh`) uses i3lock-color (`e6c0caf`, built by `install-i3lock-color.sh`). It already has the blurred screenshot, clock and date in hyprlock's layout. It still lacks two things:
   1. hyprlock's logo: the Arch logo, drawn bottom-left at 1/4 of the screen height with a primary→secondary gradient, rendered by `theme-apply` from `templates/hyprlock-logo.svg.in`.
   2. A themed password indicator. The ring has no fill and only coloured key highlights; a hyprlock-style text box was tried and dropped in favour of a filled ring.
3. Hyprland's `$mainMod + Q` opens `kitty --hold -e fastfetch`: system info with the distro logo, then a shell (kitty ≥ 0.28's `--hold` drops to a shell prompt once the child exits). i3's `$mod+q` opens a plain kitty. fastfetch isn't in Mint 22's apt repos; neofetch is, and is already installed.
4. `.config/rofi/config.rasi` is a loose port of upstream's wofi (`wofi/config` + `wofi/base.css`, coloured by `gtk3-colors.css`). Colours, width, radius and icon size match; the structure doesn't:

| # | Wofi | Rofi today |
|---|---|---|
| 1 | window: 2 px primary border, radius 10, `muted` at 50 %, margin 0 | same, plus 5 px padding |
| 2 | outer-box: a second `muted` 30 % layer, margin 5, wrapping input and list | missing; input and list sit on the window colour |
| 3 | input: GtkSearchEntry, `bg_opaque` 80 %, margin 5; magnifier icon left; the GTK theme's `entry:focus` draws a 1 px primary inset ring (the input is always focused); Adwaita radius 5 | `bg-inner`, padding 8, radius 5; no icon, no ring |
| 4 | gap input→list 10 px (two 5 px margins); list (inner-box) `bg_opaque` 80 %, no radius | spacing 5; list radius 5 |
| 5 | rows: text margin 5; selected `bg_opaque` 70 %, 1 px fg border, radius 5; icons 25 px | same |
| 6 | font: the GTK font (no `gtk-font-name`, so the system's) | JetBrainsMono Nerd Font 11 |
| 7 | Hyprland layer surface: no blur, no shadow, no inactive dimming | picom blurs it, shadows it, rounds it and may apply the 0.9 inactive opacity |

### 1.1 Click mapping (waybar → polybar today)

| # | Module | Waybar | Polybar today | Gap |
|---|---|---|---|---|
| 1 | logo | none | left: `rofi -show drun` | extra, kept (Decision 2.14) |
| 2 | clock | none (calendar tooltip) | left: toggles date | extra, kept (Decision 2.14) |
| 3 | weather | left: `firefox https://wttr.in` | left: `xdg-open https://wttr.in` | ✓ (opens the default browser) |
| 4 | memory, cpu | left: `kitty -e htop` | same | ✓ |
| 5 | temperature | left: `kitty btop` | same | ✓ |
| 6 | workspaces | left: switch; scroll: next/prev | same | ✓ |
| 7 | updates | left: `kitty -e upgrade.sh` | same | ✓ |
| 8 | usb | left: `kitty -e yazi /run/media/$USER`; right: `udiskie-umount --all` | left: `nemo /media/$USER`; right: same | yazi isn't installed (see Decision 2.4) |
| 9 | notification | left: toggle the swaync panel; right: toggle DND | left: `dunstctl history-pop`; right: DND | no notification centre |
| 10 | clipboard | left: history picker (cliphist + wofi) | left: `copyq menu` | ✓ |
| 11 | backlight | scroll: `brightnessctl set 5%±` | polybar's built-in scroll | **broken**: polybar writes `/sys/class/backlight/*/brightness` directly, which is `root:video 664`, and the user isn't in `video` |
| 12 | idle | left: toggle | same | ✓ |
| 13 | colorpicker | left: `sleep 1 && colorpicker.sh` | left: picks immediately | missing the 1 s delay |
| 14 | theme | left/right/middle: popup / next favourite / dark-light | same | ✓ |
| 15 | bluetooth | left: `blueman-manager` | same | ✓ |
| 16 | pulseaudio | left: `pavucontrol`; scroll: volume ±1 % (waybar's default `scroll-step`) | left: mute (built-in); right: `pavucontrol`; scroll ±5 % | wrong buttons and step |
| 17 | network | left: `kitty -e impala` | left: `nm-connection-editor` | not a terminal TUI |
| 18 | battery | left: `battery.sh toggle` (switches `charge_types` to/from `Long_Life`) | none | missing |

## 2. Decisions

1. **Clicks that call a command use explicit action tags.** Built-in modules (backlight, pulseaudio) get `%{A1:…:}`/`%{A4:…:}`/`%{A5:…:}` wrapped round their `format-*`, like memory and cpu already are. Polybar fires the innermost action tag, so this overrides the built-in handlers without needing a custom script module.
2. **Backlight scrolls through `brightnessctl set 5%+/-`**, as waybar does, and `enable-scroll = false`. brightnessctl goes through logind, so it works without `video` membership or a udev rule.
3. **Pulseaudio: left opens `pavucontrol`, scroll steps 1 %, right/middle unbound.** Matches waybar exactly; this drops polybar's left-click mute, which waybar doesn't have. The step comes from the built-in `interval = 1`.
4. **USB left click keeps `nemo /media/$USER`.** yazi isn't in Mint 22's apt repos, and Mint mounts under `/media`, not `/run/media`. The behaviour (open a file manager on the mounts) matches.
5. **Network opens `kitty -e nmtui`.** impala needs iwd; Mint runs NetworkManager, and nmtui is its terminal UI.
6. **Notification left click opens a rofi notification history.** dunst has no panel. `notification.sh history` lists `dunstctl history` (via `jq`) in rofi; picking one runs `dunstctl history-pop <id>` to redisplay it. Closest to toggling swaync's panel.
7. **Colorpicker: `sleep 1 && colorpicker.sh`**, matching waybar.
8. **Battery: left click runs `battery.sh toggle`.** This Dell Precision 5690 offers `Trickle Fast [Standard] Adaptive Custom`, with no `Long_Life`. The toggle switches between `Standard` and the conservation mode the firmware offers: `Long_Life` when listed, else `Custom` (closest to Long Life's fixed cap; `Adaptive` lets the firmware decide). `Custom` uses the firmware's own `charge_control_end_threshold` (90 today); the script doesn't change it. Writing needs a udev rule giving the `sudo` group write access (Mint has no `wheel`).
9. **Lock logo: Mint's `linuxmint-logo-simple-symbolic.svg`, read from `mint-artwork` at lock time and recoloured with hyprlock's gradient.** Not vendored into a theme template: the icon is GPL-3+ and this repo is Apache-2.0. Without `mint-artwork` the lock shows no logo.
10. **Lock overlay: one transparent PNG laid over i3lock-color's blur, holding only the logo.** i3lock-color draws `--image` at the root origin, unscaled, over the `--blur` screenshot, so one root-sized PNG can hold per-output art. At lock time `lock_overlay.py` reads the outputs and builds an SVG with each output's logo (bottom-left, 30 px margins, height/4), then rasterises it with `rsvg-convert`. Encoding the ~8k×4k PNG takes ~1 s, so it's cached in `$XDG_RUNTIME_DIR` by a hash of the SVG (layout + colours); a cached lock costs ~0.4 s, mostly `xrandr --current --listmonitors` (without `--current`, xrandr re-probes outputs for ~3.5 s).
11. **Password indicator: i3lock-color's ring, always shown, 20 px below centre.** Ring (radius 60, width 6) in the primary, filled with the mode's panel background (`bg_opaque` at `bg_alpha`, as on the bar). Each key flashes an arc of the ring in the secondary (`--keyhl-color`; i3lock-color can't flash the whole ring), backspace in `backspace`. Verifying turns the ring green with "Verifying" inside, a wrong password red with "Wrong". i3lock-color can't echo characters, so there's no per-character count.
12. **Placeholder: "Input password..." as i3lock-color's greeter text, below the ring.** The greeter can't hide while typing, so it isn't put inside the ring.
13. **neofetch instead of fastfetch, bound as upstream does.** Only packages from Mint's default repos: no PPA and no manual `.deb`. neofetch's config is a bash script sourced after its functions are defined, so the theme's template redefines `color()` to accept `#RRGGBB` (24-bit escapes) and the pair is used exactly; colours as upstream's fastfetch template (logo primary/secondary, title secondary, keys primary). `$mod+q` runs `kitty --hold -e neofetch`, with the gnome-terminal fallback kept as plain `gnome-terminal`. The fastfetch template and target are removed. neofetch is unmaintained upstream but still packaged.
14. **Polybar's extra clicks stay** (logo → rofi, clock → date toggle). Waybar binds nothing there, so nothing conflicts.
15. **Rofi copies wofi's box structure, not just its colours.** `mainbox` becomes outer-box (`bg-outer` = `muted` at 30 %, 5 px margin from the window via window padding, 5 px padding); `spacing: 10px`; listview radius 0. New `bg-outer` token in `rofi-colors.rasi.in`.
16. **Search icon as a Nerd Font glyph (``) in a `textbox-search`, not `edit-find-symbolic`.** Rofi doesn't recolour symbolic icons, so the GTK icon would stay dark grey in dark mode; a glyph takes `@fg`.
17. **Input ring: `border: 1px; border-color: @accent;` on the inputbar**, standing in for GTK's focus inset shadow.
18. **Font: `Ubuntu 10`**, the GTK font on this machine (`org.gnome.desktop.interface font-name`), as wofi uses the GTK font. Hardcoded rather than read from gsettings; the theme doesn't change fonts. The mono font stays in the bar and terminal.
19. **picom leaves rofi alone** (`class_g = 'Rofi'` in `blur-background-exclude`, `shadow-exclude`, `rounded-corners-exclude`, and `100:class_g = 'Rofi'` in `opacity-rule`). Hyprland applies none of these to wofi's layer surface, and picom's rounding would clip rofi's own 10 px border.
20. **Every rofi use gets the style**: drun (`$mod+r`, the polybar logo) and `-dmenu` for the new notification history. Modes stay `drun,run,window` (wofi shows drun only, but the extra modes cost nothing until switched to).
21. **Rejected: xsecurelock.** It shows a real per-character prompt, but it can't draw the box, the outline gradient, the logo or hyprlock's layout. Rejected: switching to Mint's LightDM greeter (`dm-tool lock`), which is system-wide and can't follow the theme.

## 3. Changes by file

### 3.1 Polybar

1. `.config/polybar/config.ini`:
   1. `backlight`: `enable-scroll = false`; wrap `format` in `%{A4:brightnessctl -q set 5%+:}%{A5:brightnessctl -q set 5%-:}…%{A}%{A}`.
   2. `pulseaudio`: `interval = 1`; wrap `format-volume` and `format-muted` in `%{A1:pavucontrol &:}…%{A}`; drop `click-right`.
   3. `network`: `click-left = kitty -e nmtui &`.
   4. `notification`: `click-left = ~/.config/polybar/scripts/notification.sh history &`.
   5. `colorpicker`: `click-left = sleep 1 && ~/.config/polybar/scripts/colorpicker.sh &`.
   6. `battery`: wrap every `format-*` in `%{A1:~/.config/polybar/scripts/battery.sh toggle &:}…%{A}`.
2. `.config/polybar/scripts/notification.sh`: add `history`: `dunstctl history | jq` → `<id>\t<app>: <summary>` lines → `rofi -dmenu` → `dunstctl history-pop <id>`. Nothing in history shows a notification saying so.
3. `.config/polybar/scripts/battery.sh` (new): `toggle` only, ported from waybar's script with the `Long_Life`/`Custom` choice from Decision 2.8. Notifies on success, unsupported battery, or an unwritable `charge_types`.
4. `etc/udev/rules.d/90-charge-types.rules` (new): `SUBSYSTEM=="power_supply", KERNEL=="BAT*", RUN+="/usr/bin/chgrp sudo /sys%p/charge_types", RUN+="/usr/bin/chmod g+w /sys%p/charge_types"`.
5. `install.sh`: install the udev rule and reload udev; add `brightnessctl` to the apt list (already installed here, but not listed).

### 3.2 Lock screen

1. `.config/i3/scripts/lock_overlay.py` (new): `lock_overlay.py <primary> <secondary>`, printing the cached PNG's path. Reads outputs from `xrandr --current --listmonitors` and the logo path from the `mint-artwork` icon, and writes the per-output SVG from Decision 2.10.
4. `.config/i3/scripts/lock.sh`, i3lock-color branch:
   1. Run `lock_overlay.py`; pass `--image=<its output>` alongside `--blur 8`.
   2. Ring flags from Decision 2.11: `--indicator`, `--ring-color`, `--inside*-color` = `$inside`, `--keyhl-color`, `--ringver-color`, `--ringwrong-color`; line and separator transparent.
   3. Greeter below the ring; short verify/wrong texts inside it.
   4. If the overlay script fails, lock without `--image` rather than not locking.
5. `.config/theme/templates/lock-colors.sh.in`: add `inside=@bg_opaque_hex@@bg_alpha_hex@` (the ring's fill) and `verify=@color10_hex@ee` (the ANSI bright green; hyprlock hardcodes `00ff99`).
6. The stock-i3lock fallback (no i3lock-color) also pastes the overlay PNG onto its blurred image, so it gets the logo. One extra `Image.alpha_composite` call.

### 3.3 neofetch terminal

1. `.config/i3/config`: `$terminal` stays for other uses; `bindsym $mod+q` runs `sh -c 'command -v kitty >/dev/null && exec kitty --hold -e neofetch || exec gnome-terminal'`.
2. `install.sh`: add `neofetch` to the apt list. `.config/theme/templates/neofetch.conf.in` (new) → `~/.config/neofetch/config.conf` via a `theme-apply` target, replacing the fastfetch template and target.
3. `README.md`: mention `$mod+q` and neofetch.

### 3.4 Rofi

1. `.config/rofi/config.rasi`: `font: "Ubuntu 10"`; `mainbox { background-color: @bg-outer; padding: 5px; spacing: 10px; }`; `inputbar { children: [textbox-search, entry]; border: 1px; border-color: @accent; }` with `textbox-search { str: ""; expand: false; }`; `listview { border-radius: 0; }`. Header comment updated to say it mirrors wofi's box structure.
   Also `listview { border: 0; }` (rofi's built-in dashed separator) and row colours on rofi's own `element normal.normal`/`selected.normal`/… selectors, which otherwise override the plain `element` rules with the built-in theme's.
2. `.config/theme/templates/rofi-colors.rasi.in`: add `bg-outer: #@muted_hex@4d;`.
3. `.config/picom/picom.conf`: the four `Rofi` rules from Decision 2.19.

## 4. Tests

No test harness in this repo. `bash -n` and `shellcheck` on the changed scripts; `python3 -m py_compile` on `lock_overlay.py`.

## 5. Delivery order

1. Polybar clicks (independent of the lock).
2. Battery script, udev rule, install.sh.
3. Overlay script, then lock.sh.
4. neofetch template and binding (independent of the rest).
5. Rofi style and picom rules (independent of the rest).

## 6. Estimate

| File | Lines |
|---|---|
| `polybar/config.ini` | ~20 changed |
| `polybar/scripts/notification.sh` | ~20 added |
| `polybar/scripts/battery.sh` (new) | ~30 |
| `etc/udev/rules.d/90-charge-types.rules` (new) | 2 |
| `install.sh` | ~5 |
| `theme/templates/neofetch.conf.in` (new), `theme/theme-apply`, fastfetch template (deleted) | ~25 |
| `theme/templates/lock-colors.sh.in` | ~3 |
| `i3/scripts/lock_overlay.py` (new) | ~70 |
| `i3/scripts/lock.sh` | ~30 changed |
| `i3/config` | ~2 |
| `README.md` | ~3 |
| `rofi/config.rasi` | ~12 |
| `theme/templates/rofi-colors.rasi.in` | 1 |
| `picom/picom.conf` | 4 |

16 files, ~270 lines.

## 7. Verification

1. Click every module in table 1.1 on each bar and check it does what the waybar column says: scroll the backlight on eDP-1, scroll volume (1 % steps), left-click pulseaudio for pavucontrol, the battery toggle (check `charge_types` brackets move and a notification shows), the notification history.
2. `theme-apply --toggle-mode` and a favourite change: the next lock's logo and ring change colour, and the ring's fill follows dark/light.
3. Lock (`$mod+l`) on the 3-monitor layout (rotated DP-1-1, 4K DP-1-3, eDP-1) and laptop-only: the logo sits bottom-left on every output and the ring below centre; each key flashes a secondary arc; a wrong password turns the ring red with "Wrong"; the right one unlocks.
4. Suspend → resume through xss-lock still locks (`--nofork` path).
5. Rename `lock_overlay.py` temporarily: the screen still locks.
6. `$mod+q`: kitty opens with neofetch's Mint logo in the theme's primary/secondary, then a prompt. Toggle dark/light and press it again: the colours follow.
7. Rofi (`$mod+r`, the logo click, the notification history) side by side with a screenshot of upstream's wofi, in dark and light: two muted layers, magnifier, primary ring on the input, square list, no blur or shadow behind it, Ubuntu font.

## 8. Risks

1. If this i3lock-color build places `--image` per screen rather than once at the root origin, the per-output art lands in the wrong place. Verification 3 checks this first. The fallback is to bake blur and overlay together in Python, as the stock-i3lock path already does, and pass the result without `--blur`.
2. The overlay is built at lock time. On suspend, xss-lock's `--transfer-sleep-lock` holds the sleep until i3lock maps, so the ~0.4 s (cached) delays suspend slightly. That's acceptable.
3. The key flash is an arc of the ring, not the whole ring, and there's no per-character count.

## 9. Out of scope

1. Tooltips (waybar's calendar, network SSID): polybar has none.
2. Installing yazi or impala.
3. Sizing the polybar bars to their content: polybar's `width` is fixed at start, so it would mean one transparent bar with glyph-drawn pills; the fixed widths stay.
4. Opening the neofetch terminal at login: upstream does, but here it's manual (`$mod+q`) only.
