-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- macOS-style dock: bottom, centred, auto-hide. The launcher button on the
-- left opens the Omarchy menu, standing in for Finder/Launchpad.
-- Auto-hide is deliberate on a 768px-tall screen — a permanent dock would eat
-- most of an already short display. Reveal it by pushing the pointer to the
-- bottom edge; drop the -d flag to keep it always visible.
o.launch_on_start("nwg-dock-hyprland -d -i 40 -p bottom -a center -mb 10 -c omarchy-menu -lp start")

-- Load the hyprbars/hyprexpo plugins that the macOS look'n'feel depends on.
-- hyprpm has them built and enabled, but nothing loaded them at login, so the
-- title bars and Mission Control silently never appeared. Not wrapped in
-- o.launch(): this is a one-shot command, not a session app. The follow-up
-- reload re-runs the config now that hl.plugin is populated.
o.exec_on_start("hyprpm reload -n && hyprctl reload")
