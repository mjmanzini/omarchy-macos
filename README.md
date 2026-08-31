# omarchy-macos

A macOS look and feel for [Omarchy](https://omarchy.org), installed with one command.

Rounded corners with real drop shadows, frosted-glass panels, traffic-light
title bars on **every** window (not just the GTK ones), a bottom dock, Mission
Control, an Apple menu, SF Pro / SF Mono throughout, the macOS pointer, and
Cmd-key muscle memory.

```bash
git clone https://github.com/mjmanzini/omarchy-macos.git
cd omarchy-macos
./install.sh
```

Then log out and back in.

## What you get

| | |
|---|---|
| **Windows** | 12px rounded corners, hairline borders, soft wide shadows, inactive windows dimmed slightly |
| **Title bars** | Real bars via `hyprbars`, centred semibold title, red/yellow/green traffic lights on the left that show glyphs on hover |
| **Glass** | Blur with vibrancy on the bar, dock, launcher, menus and notifications |
| **Bar** | Apple logo menu at the far left, workspaces as page-control dots, clock on the right |
| **Dock** | `nwg-dock-hyprland` at the bottom, centred, auto-hiding, frosted, with running-app dots |
| **Mission Control** | `hyprexpo` grid on `CTRL+↑` or a four-finger swipe up |
| **Themes** | `macos-light`, `macos-dark` and `ironman`, with rendered gradient wallpapers |
| **Fonts** | SF Pro for UI, SF Mono for terminals |
| **Pointer** | macOS Tahoe cursor at its native 32px |
| **Trackpad** | Natural scrolling, two-finger right click, three-finger swipe between Spaces |

### Keys

| | | | |
|---|---|---|---|
| `SUPER+Q` | Close window (Cmd+Q) | `SUPER+TAB` | Cycle windows (Cmd+Tab) |
| `SUPER+M` | Minimise to scratchpad | `CTRL+←/→` | Move between Spaces |
| `CTRL+↑` | Mission Control | `SUPER+SPACE` | Launcher (Spotlight) |

Omarchy already ships `SUPER+C/V/X` as universal copy/paste/cut and `SUPER+W`
to close, so those come for free.

## Switching themes

```bash
omarchy theme set macos-light
omarchy theme set macos-dark
omarchy theme set ironman
```

A `theme-set` hook moves the GTK theme, cursor, UI font and dock styling in step
with the palette. Switch to any other Omarchy theme and the hook hands the
system back to the stock Adwaita look, so this project doesn't quietly restyle
every theme on the machine.

### Iron Man, Mark III

The armour reads as three things: hot rod red plate, gold trim, gunmetal
chassis. The arc reactor is the only cool colour anywhere on the suit, so it is
held back here for the things that should interrupt you.

| | |
|---|---|
| Title bars | Hot rod red `#b31217` on every window |
| Traffic lights | Red, gold, and arc-reactor cyan `#4fd8ff` |
| Focused border | Gold `#e8b33a` |
| Surfaces | Gunmetal `#14171c`, warm off-white text |
| GTK / icons | Adwaita-dark with Yaru-red-dark |
| Wallpapers | The reactor burning through the chassis, and light raking across a red plate into the gold trim |

Gold is the accent rather than red, and that is deliberate: `accent` becomes the
focused window border and every link in the shell, and `#b31217` at that size on
a dark surface is a muddy 2:1 against it. Gold clears 9:1 and still reads as the
suit. The plate colour goes on the title bars instead, where it has area to work
with. For the same reason the terminal red is `#e01b24`, not the plate's
`#b31217` -- it has to survive as body text on `#14171c`.

The window chrome is theme-driven, not hard-coded: `looknfeel.lua` reads
`titlebar`, `titlebar_text`, `button_close`, `button_min` and `button_max` from
the active theme's `colors.toml` and falls back to the macOS values for any a
theme leaves out. Omarchy ignores keys it doesn't recognise, so this costs the
`macos-*` themes nothing. A new theme gets its own window chrome by setting
those five keys.

## Requirements

Omarchy on Arch, with a working AUR (`omarchy pkg aur accessible`).

`install.sh` pulls in `nwg-dock-hyprland` and `imagemagick` from the official
repos and `apple-fonts`, `macos-tahoe-cursor`, `whitesur-gtk-theme` and
`whitesur-icon-theme` from the AUR, then builds `hyprbars` and `hyprexpo`
through `hyprpm`. `apple-fonts` fetches the real SF families from Apple and
takes a few minutes.

```bash
./install.sh --dry-run       # show what would change, touch nothing
./install.sh --no-packages   # config only, skip pacman/AUR/hyprpm
```

## Undoing it

```bash
./uninstall.sh
```

Switches to a stock theme, removes this project's files, and runs
`omarchy refresh` over the Hyprland and shell configs. Packages are left
installed; the script prints the one-liner to drop them.

## How it treats your machine

- **Every file it replaces is backed up first**, as `<name>.bak.<timestamp>`
  next to the original.
- **It never edits `hyprland.lua`**, Omarchy's entry point. All the macOS
  configuration lives in the files Omarchy set aside for you — `looknfeel.lua`,
  `input.lua`, `bindings.lua`, `autostart.lua`.
- **It never touches `/usr/share/omarchy/`**, which `omarchy update` owns.
- **It never touches `monitors.lua`**, which is specific to your displays.
- **Terminal configs are edited, not overwritten** — only the string
  `JetBrainsMono Nerd Font` is rewritten to `SF Mono`.
- **Re-running it is safe.** Nothing is applied twice, and `--dry-run` shows you
  the plan first.
- **Nothing is redistributed that isn't ours.** The SF fonts and the cursor art
  are Apple's, fetched from Apple by their AUR packages. The wallpapers are
  generated gradients.

### The wallpapers are rendered, not stored

Six 2560x1600 16-bit PNGs is ~15MB of permanent git history for what is, in the
end, a smooth blend between a few dozen colours. So each wallpaper is a 9x7 grid
of colours in `lib/generate-wallpapers.sh`, written into a tiny PPM and scaled up
with a Lanczos filter -- ordinary image interpolation:

```bash
./lib/generate-wallpapers.sh                       # into config/, to preview
./lib/generate-wallpapers.sh ~/.config/omarchy/themes   # what install.sh runs
```

On a field this smooth that reproduces the originals at 49-52dB PSNR, which is
effectively lossless. Output is 16-bit, because an 8-bit gradient stretched over
2560px bands badly. Rendering all six takes about 20 seconds.

To restyle a wallpaper, edit its grid. Rows run top to bottom, columns left to
right, and the four corner entries are the image's corners.

### The two bar widgets

The Apple-logo menu button and the page-control workspace dots are small edits
to two Omarchy widgets. Rather than vendoring 1,400 lines of QML that would go
stale on the next Omarchy release, `install.sh` runs `omarchy plugin clone` to
get a fresh copy from your installed Omarchy and applies the edits with
`lib/patch-plugins.py`. Each edit is anchored to an exact upstream string; if
Omarchy changes that code the patcher **fails loudly** rather than leaving a
half-applied widget, and the anchor in that file needs updating.

## Notes

- **Backups of the theme hook go to `~/.config/omarchy/hooks/.backups/`**, not
  next to the original. `omarchy-hook` runs *every* file in a `<event>.d/`
  directory -- it skips only `*.sample` and does not check the executable bit --
  so a `macos-appearance.bak.*` left in `theme-set.d/` runs alongside the real
  hook and, sorting after it, silently undoes whatever it just set. `install.sh`
  also sweeps out any stragglers left by earlier versions.

- The pointer is set to **32px**, not Omarchy's 24. The Tahoe theme ships art at
  32/48/64/96 with no 24px frame, so 24 renders the 32px bitmap scaled down and
  soft. If 32 feels oversized on a small panel, change both `hl.env` size lines
  near the top of `config/hypr/looknfeel.lua`.
- `XCURSOR_THEME` must be the theme's **directory** name (`macos-tahoe-cursor`),
  not the `Name=` field in its `index.theme` (`MacOS-Tahoe-Cursor`). libXcursor
  resolves by directory and silently falls back to Adwaita on a miss, so the
  wrong spelling looks like the theme simply not doing much.
- The dock auto-hides. Push the pointer to the bottom edge to reveal it, or drop
  the `-d` flag in `config/hypr/autostart.lua` to pin it.
- Hyprland has no minimise, so `SUPER+M` stashes a window in the scratchpad and
  `SUPER+S` brings it back.

## Credits

Built on [Omarchy](https://omarchy.org) by DHH and contributors. Uses
[WhiteSur](https://github.com/vinceliuice/WhiteSur-gtk-theme),
[hyprbars and hyprexpo](https://github.com/hyprwm/hyprland-plugins), and
[nwg-dock-hyprland](https://github.com/nwg-piotr/nwg-dock-hyprland). The SF
fonts and the cursor art are Apple's, fetched from Apple by their AUR packages
rather than redistributed here. The wallpapers are generated gradients, not
Apple artwork.

Not affiliated with or endorsed by Apple.

## Licence

MIT. See [LICENSE](LICENSE).
