#!/usr/bin/env bash
#
# omarchy-macos -- turn a stock Omarchy desktop into a macOS-alike.
#
# Idempotent: safe to re-run after an Omarchy update. Every file it replaces is
# backed up next to the original as <name>.bak.<timestamp> first.
#
#   ./install.sh              full install
#   ./install.sh --no-packages   skip pacman/AUR/hyprpm, config only
#   ./install.sh --dry-run    print what would happen, change nothing

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%s)"
USERNAME="$(id -un)"

DRY_RUN=false
DO_PACKAGES=true
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --no-packages) DO_PACKAGES=false ;;
    -h|--help) sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

# --- output helpers ---------------------------------------------------------
bold=$(tput bold 2>/dev/null || true); dim=$(tput dim 2>/dev/null || true)
red=$(tput setaf 1 2>/dev/null || true); green=$(tput setaf 2 2>/dev/null || true)
yellow=$(tput setaf 3 2>/dev/null || true); reset=$(tput sgr0 2>/dev/null || true)

step() { echo; echo "${bold}==> $*${reset}"; }
info() { echo "    $*"; }
ok()   { echo "    ${green}✓${reset} $*"; }
warn() { echo "    ${yellow}!${reset} $*"; }
die()  { echo "${red}error:${reset} $*" >&2; exit 1; }
run()  { if $DRY_RUN; then echo "    ${dim}would run: $*${reset}"; else "$@"; fi; }

# Copy a repo file into place, backing up anything already there that differs.
install_file() {
  local src="$1" dest="$2"
  [[ -f "$src" ]] || die "missing repo file: $src"
  if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
    info "unchanged: ${dest/#$HOME/\~}"
    return
  fi
  if $DRY_RUN; then
    echo "    ${dim}would install: ${dest/#$HOME/\~}${reset}"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  [[ -f "$dest" ]] && cp "$dest" "$dest.bak.$STAMP" && info "backed up: ${dest/#$HOME/\~}.bak.$STAMP"
  cp "$src" "$dest"
  ok "installed: ${dest/#$HOME/\~}"
}

# --- preflight --------------------------------------------------------------
step "Checking the system"
[[ $EUID -eq 0 ]] && die "run this as your normal user, not root"
command -v omarchy >/dev/null || die "this needs Omarchy (https://omarchy.org)"
command -v pacman  >/dev/null || die "this needs an Arch-based system"
ok "Omarchy $(omarchy version 2>/dev/null || echo '(version unknown)') as $USERNAME"
$DRY_RUN && warn "dry run -- nothing will be changed"

# --- packages ---------------------------------------------------------------
PACMAN_PKGS=(nwg-dock-hyprland imagemagick)
AUR_PKGS=(apple-fonts macos-tahoe-cursor whitesur-gtk-theme whitesur-icon-theme)

if $DO_PACKAGES; then
  step "Installing packages"
  info "official: ${PACMAN_PKGS[*]}"
  run omarchy pkg add "${PACMAN_PKGS[@]}"
  info "AUR:      ${AUR_PKGS[*]}"
  info "${dim}(apple-fonts builds from Apple's own SF Pro / SF Mono downloads --"
  info "${dim} it is a large download and takes a few minutes)${reset}"
  run omarchy pkg aur add "${AUR_PKGS[@]}"
  ok "packages present"

  step "Building the Hyprland plugins (hyprbars, hyprexpo)"
  info "hyprbars draws the real macOS title bars with traffic lights;"
  info "hyprexpo is Mission Control. Both compile against your Hyprland."
  # `hyprpm add` on an already-added repo exits non-zero; that is fine.
  run hyprpm add https://github.com/hyprwm/hyprland-plugins || true
  run hyprpm add https://github.com/sandwichfarm/hyprexpo   || true
  run hyprpm enable hyprbars || warn "could not enable hyprbars -- title bars will be missing"
  run hyprpm enable hyprexpo || warn "could not enable hyprexpo -- Mission Control will be missing"
  ok "plugins built"
else
  step "Skipping packages (--no-packages)"
fi

# --- Hyprland configuration -------------------------------------------------
step "Installing Hyprland configuration"
for f in looknfeel.lua input.lua bindings.lua autostart.lua; do
  install_file "$REPO/config/hypr/$f" "$CONFIG/hypr/$f"
done

# Earlier versions of this project put the cursor env in hyprland.lua. It now
# lives in looknfeel.lua, so strip the old copy rather than letting the two
# disagree. hyprland.lua is otherwise never touched -- it is Omarchy's entry
# point and yours to own.
HYPRLAND_LUA="$CONFIG/hypr/hyprland.lua"
if [[ -f "$HYPRLAND_LUA" ]] && grep -q 'XCURSOR_THEME' "$HYPRLAND_LUA"; then
  if $DRY_RUN; then
    warn "would strip the legacy XCURSOR_* block from hyprland.lua"
  else
    cp "$HYPRLAND_LUA" "$HYPRLAND_LUA.bak.$STAMP"
    python3 - "$HYPRLAND_LUA" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p).read()
# Drop any hl.env("XCURSOR_*"/"HYPRCURSOR_*", ...) line and the comment block
# immediately above it, which is what previous versions of this installer wrote.
s = re.sub(r'\n*(?:^--[^\n]*\n)*^hl\.env\("(?:X|HYPR)CURSOR_[A-Z]+",[^\n]*\n',
           '\n', s, flags=re.M)
open(p, 'w').write(s.rstrip() + "\n")
PY
    ok "stripped the legacy cursor block from hyprland.lua (backed up)"
  fi
fi

# --- fonts ------------------------------------------------------------------
step "Switching the UI and terminal fonts to SF"
install_file "$REPO/config/fontconfig/fonts.conf" "$CONFIG/fontconfig/fonts.conf"

# Omarchy ships JetBrainsMono Nerd Font in four terminal configs. Rewrite only
# that exact family name, so any other change you have made is preserved.
declare -A TERMINALS=(
  ["$CONFIG/alacritty/alacritty.toml"]=1
  ["$CONFIG/foot/foot.ini"]=1
  ["$CONFIG/kitty/kitty.conf"]=1
  ["$CONFIG/ghostty/config"]=1
)
for term_config in "${!TERMINALS[@]}"; do
  [[ -f "$term_config" ]] || continue
  grep -q "JetBrainsMono Nerd Font" "$term_config" || { info "already SF Mono: ${term_config/#$HOME/\~}"; continue; }
  if $DRY_RUN; then
    echo "    ${dim}would set SF Mono in ${term_config/#$HOME/\~}${reset}"
    continue
  fi
  cp "$term_config" "$term_config.bak.$STAMP"
  sed -i 's/JetBrainsMono Nerd Font/SF Mono/g' "$term_config"
  ok "SF Mono: ${term_config/#$HOME/\~}"
done

# --- Omarchy themes, menu, dock, hook ---------------------------------------
step "Installing the macOS themes"
for theme in macos-light macos-dark; do
  if $DRY_RUN; then
    echo "    ${dim}would install theme $theme${reset}"
    continue
  fi
  dest="$CONFIG/omarchy/themes/$theme"
  [[ -d "$dest" ]] && mv "$dest" "$dest.bak.$STAMP" && info "backed up existing $theme"
  mkdir -p "$dest"
  cp -r "$REPO/config/omarchy/themes/$theme/." "$dest/"
  # backgrounds/.gitkeep only exists to keep the empty dir in git.
  rm -f "$dest/backgrounds/.gitkeep"
  ok "installed theme: $theme"
done

# The wallpapers are rendered, not stored -- see lib/generate-wallpapers.sh.
# Four 2560x1600 16-bit PNGs would be 10MB of git history for what is a blend
# between 42 colours.
step "Rendering the wallpapers"
if $DRY_RUN; then
  echo "    ${dim}would render 4 wallpapers into ~/.config/omarchy/themes${reset}"
elif ! command -v magick >/dev/null; then
  warn "ImageMagick is missing, so the wallpapers were not rendered."
  warn "Install it and run: ./lib/generate-wallpapers.sh \"$CONFIG/omarchy/themes\""
else
  info "${dim}takes about 20 seconds${reset}"
  "$REPO/lib/generate-wallpapers.sh" "$CONFIG/omarchy/themes"
  ok "wallpapers rendered"
fi

step "Installing the dock, menu and theme hook"
install_file "$REPO/config/nwg-dock-hyprland/style-light.css" "$CONFIG/nwg-dock-hyprland/style-light.css"
install_file "$REPO/config/nwg-dock-hyprland/style-dark.css"  "$CONFIG/nwg-dock-hyprland/style-dark.css"
install_file "$REPO/config/omarchy/extensions/omarchy-menu.jsonc" "$CONFIG/omarchy/extensions/omarchy-menu.jsonc"
install_file "$REPO/config/omarchy/hooks/theme-set.d/macos-appearance" "$CONFIG/omarchy/hooks/theme-set.d/macos-appearance"
run chmod +x "$CONFIG/omarchy/hooks/theme-set.d/macos-appearance"

# --- shell plugins ----------------------------------------------------------
# The Apple-logo menu button and the page-control workspace dots are edits to
# two Omarchy widgets. `omarchy plugin clone` makes a private copy named after
# you (<user>.menu), which is what shell.json then points at.
step "Cloning and patching the bar widgets"
for plugin in menu workspaces; do
  if [[ -d "$CONFIG/omarchy/plugins/$USERNAME.$plugin" ]]; then
    info "already cloned: $USERNAME.$plugin"
  else
    run omarchy plugin clone "omarchy.$plugin"
  fi
done
run python3 "$REPO/lib/patch-plugins.py" "$USERNAME"

step "Installing the bar layout"
if $DRY_RUN; then
  echo "    ${dim}would render shell.json for user '$USERNAME'${reset}"
else
  rendered="$(mktemp)"
  sed "s/__USER__/$USERNAME/g" "$REPO/config/omarchy/shell.json.in" > "$rendered"
  install_file "$rendered" "$CONFIG/omarchy/shell.json"
  rm -f "$rendered"
fi

# --- apply ------------------------------------------------------------------
step "Applying"
run omarchy theme set macos-light
run hyprctl reload

if ! $DRY_RUN; then
  # hl.env only reaches apps launched after a fresh login, so push the cursor
  # into the running session too -- otherwise the pointer stays Adwaita until
  # you log out.
  export XCURSOR_THEME=macos-tahoe-cursor XCURSOR_SIZE=32 HYPRCURSOR_SIZE=32
  systemctl --user set-environment XCURSOR_THEME=macos-tahoe-cursor XCURSOR_SIZE=32 HYPRCURSOR_SIZE=32 2>/dev/null || true
  dbus-update-activation-environment --systemd XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_SIZE 2>/dev/null || true
  hyprctl setcursor macos-tahoe-cursor 32 >/dev/null 2>&1 || true

  omarchy restart shell >/dev/null 2>&1 || warn "could not restart the shell -- run 'omarchy restart shell'"

  if errors="$(hyprctl configerrors 2>/dev/null)" && [[ -n "$errors" ]]; then
    warn "Hyprland reported config errors:"
    echo "$errors" | sed 's/^/      /'
  else
    ok "Hyprland config is clean"
  fi
fi

step "Done"
cat <<EOF
    Log out and back in once. The plugins (title bars, Mission Control) and the
    cursor only reach every app after a fresh session.

    ${bold}Switching appearance${reset}
      omarchy theme set macos-dark      dark mode
      omarchy theme set macos-light     light mode

    ${bold}Keys${reset}
      SUPER+Q          close window (Cmd+Q)      SUPER+TAB    cycle windows (Cmd+Tab)
      SUPER+M          minimise to scratchpad    CTRL+←/→     move between Spaces
      CTRL+↑           Mission Control           3-finger ←/→ move between Spaces
                                                 4-finger ↑   Mission Control

    Everything replaced was backed up as <file>.bak.$STAMP.
    Run ./uninstall.sh to put the Omarchy defaults back.
EOF
