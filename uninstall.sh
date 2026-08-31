#!/usr/bin/env bash
#
# Put Omarchy's own look back. Config files are reset with `omarchy refresh`,
# which takes its own timestamped backup first, so nothing installed by this
# project is lost -- only deactivated.
#
# Packages (SF fonts, WhiteSur, the cursor, the dock) are left installed; they
# are inert once the theme is off. Remove them by hand if you want the disk back:
#   omarchy pkg drop apple-fonts macos-tahoe-cursor whitesur-gtk-theme whitesur-icon-theme nwg-dock-hyprland

set -euo pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%s)"
USERNAME="$(id -un)"

bold=$(tput bold 2>/dev/null || true); green=$(tput setaf 2 2>/dev/null || true)
yellow=$(tput setaf 3 2>/dev/null || true); reset=$(tput sgr0 2>/dev/null || true)
step() { echo; echo "${bold}==> $*${reset}"; }
ok()   { echo "    ${green}✓${reset} $*"; }
warn() { echo "    ${yellow}!${reset} $*"; }

read -r -p "Revert the macOS look and go back to stock Omarchy? [y/N] " reply
[[ "$reply" =~ ^[Yy]$ ]] || { echo "Nothing changed."; exit 0; }

step "Switching off the macOS theme"
# The theme-set hook's fallback branch restores Adwaita, the stock cursor and
# the Adwaita UI font, so do this while the hook is still installed.
omarchy theme set tokyo-night 2>/dev/null || warn "could not switch theme -- pick one with 'omarchy theme set'"

step "Removing this project's files"
for f in "$CONFIG/omarchy/hooks/theme-set.d/macos-appearance" \
         "$CONFIG/nwg-dock-hyprland/style-light.css" \
         "$CONFIG/nwg-dock-hyprland/style-dark.css"; do
  [[ -e "$f" ]] && mv "$f" "$f.removed.$STAMP" && ok "removed: ${f/#$HOME/\~}"
done
for theme in macos-light macos-dark; do
  d="$CONFIG/omarchy/themes/$theme"
  [[ -d "$d" ]] && mv "$d" "$d.removed.$STAMP" && ok "removed theme: $theme"
done

step "Resetting Omarchy config to defaults"
# Each of these backs the current file up on its own before overwriting.
# `refresh hyprland` covers every ~/.config/hypr/*.lua, hyprland.lua included.
omarchy refresh hyprland || warn "could not refresh the Hyprland config"
omarchy refresh shell    || warn "could not refresh the shell config"
omarchy refresh config omarchy/extensions/omarchy-menu.jsonc \
  || warn "could not refresh the menu -- the Apple menu labels may remain"

step "Restoring the terminal font"
for term_config in "$CONFIG/alacritty/alacritty.toml" "$CONFIG/foot/foot.ini" \
                   "$CONFIG/kitty/kitty.conf" "$CONFIG/ghostty/config"; do
  [[ -f "$term_config" ]] || continue
  grep -q "SF Mono" "$term_config" || continue
  cp "$term_config" "$term_config.bak.$STAMP"
  sed -i 's/SF Mono/JetBrainsMono Nerd Font/g' "$term_config"
  ok "JetBrainsMono: ${term_config/#$HOME/\~}"
done
[[ -f "$CONFIG/fontconfig/fonts.conf" ]] && grep -q "SF Mono" "$CONFIG/fontconfig/fonts.conf" \
  && mv "$CONFIG/fontconfig/fonts.conf" "$CONFIG/fontconfig/fonts.conf.removed.$STAMP" \
  && ok "removed the SF Mono fontconfig rule"

step "Disabling the Hyprland plugins"
hyprpm disable hyprbars 2>/dev/null || true
hyprpm disable hyprexpo 2>/dev/null || true
hyprpm reload -n 2>/dev/null || true

step "Cleaning up the cloned bar widgets"
warn "left in place: $CONFIG/omarchy/plugins/$USERNAME.{menu,workspaces}"
warn "delete them by hand if you want them gone -- the refreshed shell.json no longer loads them"

step "Done"
echo "    Log out and back in. Files this script displaced end in .removed.$STAMP;"
echo "    files 'omarchy refresh' replaced have their own backups alongside."
