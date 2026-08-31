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

-- Cmd+M minimises. Hyprland has no minimise, so a minimised window is parked on
-- the scratchpad special workspace.
--
-- The scratchpad alone is a one-way trip, and that is the trap this closes:
-- SUPER+S only toggles whether the scratchpad is *shown*, and nothing in
-- Omarchy moves a window back out of it. Minimised windows therefore pile up
-- in there and can only be recovered by knowing to press SUPER+SHIFT+<number>.
local SCRATCHPAD = "scratchpad"

-- Pull a window out of the scratchpad onto the workspace you are looking at,
-- then drop the scratchpad overlay so you land back on the desktop instead of
-- inside it.
--
-- Restoring to the current workspace, rather than the one the window was
-- minimised from, is deliberate: it needs no per-window bookkeeping, and it is
-- what you actually want when you hit restore while looking at a given Space.
local function unminimise(window)
  local workspace = hl.get_active_workspace()
  if not (window and workspace) then return end

  hl.dispatch(hl.dsp.window.move({
    workspace = tostring(workspace.id),
    window = "address:" .. window.address,
  }))

  if hl.get_active_special_workspace() then
    hl.dispatch(hl.dsp.workspace.toggle_special(SCRATCHPAD))
  end
end

-- Minimise, or restore if the focused window is one you already minimised.
-- Peek at the scratchpad with SUPER+S, focus a window, press this to bring it
-- back -- the keyboard version of clicking a Dock icon.
local function minimise_toggle()
  local window = hl.get_active_window()
  if not window then return end

  if window.workspace and window.workspace.special then
    unminimise(window)
  else
    hl.dispatch(hl.dsp.window.move({ workspace = "special:" .. SCRATCHPAD, follow = false }))
  end
end

o.bind("SUPER + M", "Minimise / restore (Cmd+M)", minimise_toggle)

-- Bring back the last thing you minimised without peeking first. Among windows
-- sitting in the scratchpad, the lowest focus_history_id is the most recently
-- focused, which is the one most recently sent there.
--
-- SUPER+CTRL+M rather than SUPER+SHIFT+M: the latter is Omarchy's Music.
local function restore_last()
  local newest
  for _, window in ipairs(hl.get_workspace_windows("special:" .. SCRATCHPAD)) do
    if not newest or window.focus_history_id < newest.focus_history_id then
      newest = window
    end
  end
  unminimise(newest)
end

o.bind("SUPER + CTRL + M", "Restore last minimised", restore_last)

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
