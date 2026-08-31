-- macOS-style trackpad and input.
--
-- Original Omarchy default is backed up alongside as input.lua.bak.<timestamp>.

hl.config({
  input = {
    touchpad = {
      -- macOS "natural" scrolling: content follows your fingers. This is the
      -- single most noticeable trackpad difference between the two systems.
      natural_scroll = true,

      -- Two-finger tap is right-click, the way it is on a Mac, rather than
      -- Linux's default lower-right corner zone.
      clickfinger_behavior = true,
    },
  },
})

-- Three-finger horizontal swipe moves between workspaces — the Mac's
-- swipe-between-Spaces gesture.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Four-finger swipe up opens Mission Control, matching the Mac trackpad
-- gesture. The three-finger horizontal swipe above still moves between Spaces.
hl.gesture({ fingers = 4, direction = "up", action = function() hl.plugin.hyprexpo.expo("toggle") end })
