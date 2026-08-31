-- macOS-style look'n'feel.
--
-- Paired with the macos-light / macos-dark themes. Border and accent colours
-- come from the active theme, so this file only shapes geometry, depth and
-- motion — the things that actually read as "Mac" once the colours are right.
--
-- The original (all-commented) Omarchy default is backed up alongside this
-- file as looknfeel.lua.bak.<timestamp>.

-- ---------------------------------------------------------------------------
-- Pointer  (omarchy-macos:cursor)
-- ---------------------------------------------------------------------------
-- HYPRCURSOR_THEME is deliberately left unset: there is no hyprcursor build of
-- this theme, and Hyprland falls back to XCURSOR_THEME.
--
-- The value MUST be the theme's DIRECTORY name (/usr/share/icons/macos-tahoe-cursor),
-- not the Name= field in its index.theme ("MacOS-Tahoe-Cursor"). libXcursor
-- resolves themes by directory, and when it can't find one it silently falls
-- back to Adwaita instead of reporting an error -- so the wrong spelling looks
-- like "the theme just doesn't do much".
hl.env("XCURSOR_THEME", "macos-tahoe-cursor")

-- This theme ships art at 32/48/64/96 only -- there is no 24px frame. Omarchy's
-- default of 24 therefore renders the 32px bitmap scaled down, which softens
-- every edge. 32 is pixel-exact. Drop both to 24 if the pointer feels too big
-- on your panel; it costs some crispness.
hl.env("XCURSOR_SIZE", "32")
hl.env("HYPRCURSOR_SIZE", "32")

hl.config({
  general = {
    -- Roomier than Omarchy's default 5/10. macOS leaves real air around
    -- windows, and the rounding below needs the space to read properly.
    gaps_in = 6,
    gaps_out = 14,

    -- macOS window edges are a hairline, not a 2px frame. The colour still
    -- comes from the theme, so the focused window stays obvious.
    border_size = 1,
  },

  decoration = {
    -- The single biggest "Mac" cue. macOS window corners sit around 10-12px.
    rounding = 12,

    -- macOS very slightly recedes the window you aren't working in. Kept low
    -- on purpose: above ~0.1 it stops looking like depth and starts looking
    -- like a dimmed screen.
    dim_inactive = true,
    dim_strength = 0.06,

    -- Soft, wide, low-opacity shadow — the floating-pane look. render_power 3
    -- gives the gentle falloff; a harder shadow reads as Windows, not macOS.
    shadow = {
      enabled = true,
      range = 28,
      render_power = 3,
      color = "rgba(00000055)",
      color_inactive = "rgba(00000028)",
    },

    -- Frosted-glass vibrancy. This is what makes the bar, launcher, menus and
    -- notifications look like macOS panels rather than flat rectangles.
    --
    -- size/passes are deliberately modest: this is a 1366x768 laptop and blur
    -- cost scales with both. Raise passes to 3 if it still feels crisp enough
    -- and the fans stay quiet.
    blur = {
      enabled = true,
      size = 6,
      passes = 2,
      new_optimizations = true,
      ignore_opacity = true,
      xray = false,
      -- vibrancy is the saturation boost behind glass — Apple's panels pull
      -- colour through rather than greying it out.
      vibrancy = 0.1696,
      noise = 0.015,
      popups = true,
      popups_ignorealpha = 0.2,
    },
  },
})

-- Motion. macOS eases out fast and settles — it never bounces, and it never
-- runs long. These two curves cover everything.
hl.curve("macEase", { type = "bezier", points = { { 0.32, 0.72 }, { 0, 1 } } })
hl.curve("macSettle", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 4.5, bezier = "macEase" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "macSettle", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "macEase", style = "popin 92%" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "macEase" })
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "macEase" })
hl.animation({ leaf = "layers", enabled = true, speed = 4.5, bezier = "macEase" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 5, bezier = "macSettle", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 4, bezier = "macEase", style = "fade" })

-- Workspaces slide horizontally, the way Spaces do on a Mac. Omarchy ships
-- this disabled; the slide is a large part of why Spaces feel physical.
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "macEase", style = "slide" })

-- Frost the panels. Window blur alone doesn't touch layer-shell surfaces, so
-- the bar and dock need explicit layer rules to pick up the glass effect.
-- ignore_alpha keeps fully-transparent pixels from being blurred into a haze.
hl.layer_rule({ match = { namespace = "omarchy-bar" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = "nwg-dock" }, blur = true, ignore_alpha = 0.2 })

-- Frost the Omarchy panels too — menu/launcher, emoji picker, clipboard and
-- the keyboard panel. Without this they render as flat opaque cards while the
-- bar and dock behind them are glass, which reads as inconsistent.
hl.layer_rule({ match = { namespace = "^(omarchy-menu|omarchy-image-selector|omarchy-emojis|omarchy-clipboard|omarchy-keyboard-panel)$" }, blur = true, ignore_alpha = 0.2 })

-- ---------------------------------------------------------------------------
-- macOS window chrome (hyprbars)
-- ---------------------------------------------------------------------------
-- Real title bars with traffic-light buttons on EVERY window, not just the
-- GTK apps WhiteSur can reach. This is what closes the gap on Alacritty,
-- Chromium and anything else that draws its own chrome.
--
-- Bar colours are read from the active theme's colors.toml at config load, so
-- they follow macos-light / macos-dark instead of being pinned to one palette.
-- Applying a theme rewrites the theme's hyprland.lua, which reloads Hyprland,
-- which re-runs this file.
local function theme_color(key, fallback)
  local path = (os.getenv("HOME") or "") .. "/.local/state/omarchy/current/theme/colors.toml"
  local file = io.open(path, "r")
  if not file then return fallback end

  local found = fallback
  for line in file:lines() do
    local k, v = line:match('^%s*([%w_]+)%s*=%s*"(#%x+)"')
    if k == key then
      found = v
      break
    end
  end

  file:close()
  return found
end

-- "#rrggbb" -> "rgba(rrggbbAA)". Translucent so the bar picks up the global
-- blur the way macOS title bars pick up vibrancy.
local function rgba(hex, alpha)
  return "rgba(" .. hex:gsub("#", "") .. alpha .. ")"
end

local function rgb(hex)
  return "rgb(" .. hex:gsub("#", "") .. ")"
end

-- A theme can override the window chrome with custom keys in its colors.toml.
-- Omarchy ignores keys it doesn't recognise, and anything a theme leaves out
-- falls back to the macOS value -- so the macos-* themes are unaffected by
-- these lines existing. The ironman theme uses them to put a red plate and
-- arc-reactor buttons on every window.
local theme_bg = theme_color("background", "#f2f2f7")
local bar_bg = theme_color("titlebar", theme_bg)
local bar_fg = theme_color("titlebar_text", theme_color("foreground", "#1d1d1f"))

local btn_close = theme_color("button_close", "#ff5f57")
local btn_min   = theme_color("button_min", "#febc2e")
local btn_max   = theme_color("button_max", "#28c840")

-- Everything below needs the hyprbars/hyprexpo plugins, which hyprpm loads
-- from autostart.lua — i.e. AFTER Hyprland has already parsed this file once.
-- On that first pass hl.plugin is still empty. Without this guard the
-- add_button calls below raise "attempt to index a nil value (field
-- 'hyprbars')", which aborts the rest of the file — taking the hyprexpo
-- (Mission Control) settings down with it. hyprpm reloads the config once the
-- plugins are up, and this file is re-run with the guard satisfied.
if not (hl.plugin and hl.plugin.hyprbars) then return end

hl.config({
  plugin = {
    hyprbars = {
      bar_height = 26,
      bar_color = rgba(bar_bg, "cc"),
      col = { text = rgb(bar_fg) },

      -- macOS centres the window title in a semibold system face.
      bar_title_enabled = true,
      bar_text_align = "center",
      bar_text_font = "SF Pro Text",
      bar_text_size = 11,
      bar_text_weight = "semibold",

      -- Traffic lights sit at the LEFT on a Mac. This is the whole point.
      bar_buttons_alignment = "left",
      bar_padding = 10,
      bar_button_padding = 8,

      -- Plain coloured dots until you hover, then the glyphs appear —
      -- exactly how macOS behaves.
      icon_on_hover = true,

      -- Unfocused windows grey their buttons out, again like macOS.
      inactive_button_color = "rgb(8e8e93)",

      bar_blur = true,
      bar_part_of_window = true,
      bar_precedence_over_border = true,

      on_double_click = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\" })'",
    },
  },
})

-- With left alignment, buttons render LEFT to RIGHT in definition order, so
-- red-yellow-green is simply defined in that order — same as a Mac.
hl.plugin.hyprbars.add_button({
  bg_color = rgb(btn_close),
  fg_color = "rgb(1a1a1a)",
  size = 11,
  icon = "x",
  action = "hyprctl dispatch 'hl.dsp.window.close()'",
})

hl.plugin.hyprbars.add_button({
  bg_color = rgb(btn_min),
  fg_color = "rgb(1a1a1a)",
  size = 11,
  icon = "-",
  -- Hyprland has no minimise; the scratchpad is where SUPER+M sends windows too.
  action = "hyprctl dispatch 'hl.dsp.window.move({ workspace = \"special:scratchpad\", follow = false })'",
})

hl.plugin.hyprbars.add_button({
  bg_color = rgb(btn_max),
  fg_color = "rgb(1a1a1a)",
  size = 11,
  icon = "+",
  action = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\" })'",
})

-- ---------------------------------------------------------------------------
-- Mission Control (hyprexpo)
-- ---------------------------------------------------------------------------
-- Workspace overview grid. bg_col reuses the theme background read above, so
-- the overview backdrop matches macos-light / macos-dark like everything else.
-- Bound to CTRL+UP in bindings.lua and a four-finger swipe up in input.lua.
hl.config({
  plugin = {
    hyprexpo = {
      columns = 3,
      gaps_in = 5,
      gaps_out = 0,
      bg_col = rgb(theme_bg),
      -- Keep the current workspace centred in the grid, as Mission Control does.
      workspace_method = "center current",
      gesture_distance = 200,
      cancel_key = "escape",
      show_cursor = 1,
      -- Clicking a tile should just switch to it; dragging windows between
      -- tiles is easy to trigger by accident with a shaky pointer.
      drag_drop_enable = 0,
      -- Arrow keys + Return to pick a workspace without the mouse.
      keynav_enable = 1,
    },
  },
})
