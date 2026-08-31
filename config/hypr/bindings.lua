-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- ---------------------------------------------------------------------------
-- macOS muscle memory
-- ---------------------------------------------------------------------------
-- Omarchy already ships most of it: SUPER+C/V/X are universal copy/paste/cut,
-- SUPER+W closes a window, and SUPER+SPACE is the Spotlight-style launcher.
-- These fill the remaining Cmd-key gaps.

-- Cmd+Q quits. Hyprland has no separate "quit app", so this closes the window
-- like SUPER+W does — which is what Cmd+Q does for single-window apps anyway.
o.bind("SUPER + Q", "Close window (Cmd+Q)", hl.dsp.window.close())

-- Cmd+M minimises. Hyprland has no minimise, so this stashes the window in the
-- scratchpad; SUPER+S brings it back, the way clicking a Dock icon would.
o.bind("SUPER + M", "Minimise to scratchpad (Cmd+M)", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- Cmd+Tab cycles windows on a Mac, not Spaces.
-- NOTE: this replaces Omarchy's SUPER+TAB, which was "Next workspace".
-- Spaces move to CTRL+LEFT/RIGHT below, matching macOS.
hl.unbind("SUPER + TAB")
o.bind("SUPER + TAB", "Focus next window (Cmd+Tab)", hl.dsp.window.cycle_next())

-- Ctrl+Left/Right moves between Spaces, exactly as on macOS.
o.bind("CTRL + LEFT", "Previous workspace (Spaces)", hl.dsp.focus({ workspace = "e-1" }))
o.bind("CTRL + RIGHT", "Next workspace (Spaces)", hl.dsp.focus({ workspace = "e+1" }))

-- Mission Control. macOS uses CTRL+Up; the four-finger swipe up lives in
-- input.lua. Inside the overview: arrows move, Return picks, Escape cancels.
o.bind("CTRL + UP", "Mission Control", function() hl.plugin.hyprexpo.expo("toggle") end)
