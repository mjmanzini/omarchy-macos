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

BACKUP_DIR="$CONFIG/omarchy/.backups"

step "Removing this project's files"
# The hook cannot be renamed in place: omarchy-hook runs every file in
# theme-set.d/, so a macos-appearance.removed.* would keep running.
HOOK="$CONFIG/omarchy/hooks/theme-set.d/macos-appearance"
if [[ -e "$HOOK" ]]; then
  mkdir -p "$BACKUP_DIR"
  mv "$HOOK" "$BACKUP_DIR/macos-appearance.removed.$STAMP"
  ok "removed: ${HOOK/#$HOME/\~}"
fi
for f in "$CONFIG/nwg-dock-hyprland/style-light.css" \
         "$CONFIG/nwg-dock-hyprland/style-dark.css"; do
  [[ -e "$f" ]] && mv "$f" "$f.removed.$STAMP" && ok "removed: ${f/#$HOME/\~}"
done
# Themes move out of themes/ entirely: omarchy-theme-list treats every directory
# in there as a theme, so a <name>.removed.* would just become a broken entry in
# the picker.
for theme in macos-light macos-dark ironman; do
  d="$CONFIG/omarchy/themes/$theme"
  if [[ -d "$d" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$d" "$BACKUP_DIR/$theme.removed.$STAMP"
    ok "removed theme: $theme"
  fi
done

step "Resetting Omarchy config to defaults"
# Each of these backs the current file up on its own before overwriting.
# Refresh ONLY the four files install.sh overwrites. `omarchy refresh hyprland`
# would be shorter, but it resets every ~/.config/hypr/*.lua -- including
# monitors.lua, which is specific to your displays and which this project never
# touches, and hyprland.lua, where your own configuration lives. Blowing away a
# multi-monitor setup on uninstall is not an acceptable way to tidy up.
for config in looknfeel input bindings autostart; do
  omarchy refresh config "hypr/$config.lua" \
    || warn "could not refresh hypr/$config.lua"
done
omarchy refresh shell || warn "could not refresh the shell config"
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
if compgen -G "$CONFIG/omarchy/plugins/$USERNAME.*" >/dev/null; then
  warn "left in place: $CONFIG/omarchy/plugins/$USERNAME.{menu,workspaces}"
  warn "delete them by hand if you want them gone -- the refreshed shell.json no longer loads them"
else
  ok "none to clean up"
fi

step "Done"
echo "    Log out and back in. Files this script displaced end in .removed.$STAMP;"
echo "    files 'omarchy refresh' replaced have their own backups alongside."
