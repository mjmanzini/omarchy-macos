#!/usr/bin/env python3
"""Apply the macOS edits to the two cloned Omarchy shell plugins.

These plugins are NOT vendored into this repo. `omarchy plugin clone` produces
a fresh copy from whatever Omarchy version is installed, and this script then
makes two small, surgical edits to it. That way an Omarchy update that improves
the upstream widget still lands -- vendoring 1400 lines of QML would freeze it.

Every edit is anchored on an exact upstream string. If an anchor is gone the
script fails loudly rather than silently leaving a half-applied patch: that
means upstream changed and the anchor here needs updating.

Each edit is idempotent -- an already-patched file is reported as such.
"""

import pathlib
import sys

user = sys.argv[1] if len(sys.argv) > 1 else None
if not user:
    sys.exit("usage: patch-plugins.py <username>")

plugins = pathlib.Path.home() / ".config/omarchy/plugins"

# (file, anchor-that-must-exist, replacement, marker-proving-it-is-done)
EDITS = [
    (
        plugins / f"{user}.menu/BarWidget.qml",
        '    text: "\\ue900"\n    fontFamily: "omarchy"\n',
        '    // Apple\'s logo lives at U+F8FF in SF Pro, which the apple-fonts package\n'
        '    // installs. Standing in for the Apple menu at the far left of the bar.\n'
        '    // If SF Pro is ever removed this falls back to a blank box -- the nerd-font\n'
        '    // equivalent is "\\uf179" with fontFamily "JetBrainsMono Nerd Font".\n'
        '    text: "\\uf8ff"\n    fontFamily: "SF Pro Text"\n',
        'fontFamily: "SF Pro Text"',
    ),
    (
        plugins / f"{user}.workspaces/Workspaces.qml",
        '        text: focused ? "\\uDB85\\uDCFB" : (modelData === 10 ? "0" : String(modelData))\n'
        '        opacity: occupied || focused ? 1 : 0.5\n'
        '        horizontalMargin: 6\n',
        '        // Page-control dots instead of digits -- the Apple idiom for "which of\n'
        '        // these am I on". Filled if the workspace exists or has windows, hollow\n'
        '        // if it\'s empty; the three opacity steps carry focused vs occupied vs\n'
        '        // empty without needing numbers.\n'
        '        text: focused || occupied ? "\\u25CF" : "\\u25CB"\n'
        '        opacity: focused ? 1 : (occupied ? 0.75 : 0.35)\n'
        '        horizontalMargin: 2\n',
        'text: focused || occupied ? "\\u25CF" : "\\u25CB"',
    ),
    (
        plugins / f"{user}.workspaces/Workspaces.qml",
        '        fixedWidth: root.vertical ? root.barSize : Style.space(20)\n',
        '        fixedWidth: root.vertical ? root.barSize : Style.space(11)\n',
        'Style.space(11)',
    ),
]

failed = []
for path, anchor, replacement, done_marker in EDITS:
    if not path.exists():
        failed.append(f"{path} does not exist -- did the clone step run?")
        continue
    text = path.read_text()
    if done_marker in text:
        print(f"  already patched: {path.name}")
        continue
    if anchor not in text:
        failed.append(
            f"{path}: upstream anchor not found. Omarchy's version of this "
            f"widget has changed; update the anchor in lib/patch-plugins.py."
        )
        continue
    path.write_text(text.replace(anchor, replacement, 1))
    print(f"  patched: {path.name}")

if failed:
    print("\nPlugin patching failed:", file=sys.stderr)
    for f in failed:
        print(f"  - {f}", file=sys.stderr)
    sys.exit(1)
