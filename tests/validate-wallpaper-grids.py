#!/usr/bin/env python3
"""Check every wallpaper colour grid in lib/generate-wallpapers.sh.

The grids are the one part of this repo where a typo is both easy to make and
invisible until someone runs the installer: a dropped or malformed colour only
fails at render time, on the user's machine, after the packages have been
installed. This checks them without needing ImageMagick, so CI can run it.
"""

import pathlib
import re
import sys

script = pathlib.Path(__file__).resolve().parent.parent / "lib/generate-wallpapers.sh"
text = script.read_text()


def setting(name: str) -> int:
    match = re.search(rf"^{name}=(\d+)$", text, re.M)
    if not match:
        sys.exit(f"could not find {name}= in {script.name}")
    return int(match.group(1))


cols, rows = setting("COLS"), setting("ROWS")
expected = cols * rows

grids = re.findall(r"read -r -d '' (\w+) <<'EOF' \|\| true\n(.*?)\nEOF", text, re.S)
if not grids:
    sys.exit("no colour grids found -- has the heredoc format changed?")

# Every grid defined must also be rendered, and vice versa; a grid that is
# edited but never wired into a render call is a silent no-op.
rendered = set(re.findall(r'^render "\$(\w+)"', text, re.M))

failures = []
for name, body in grids:
    lines = [line for line in body.splitlines() if line.strip()]
    colours = body.split()

    if len(lines) != rows:
        failures.append(f"{name}: {len(lines)} rows, expected {rows}")
    if len(colours) != expected:
        failures.append(f"{name}: {len(colours)} colours, expected {expected} ({cols}x{rows})")
    for colour in colours:
        if not re.fullmatch(r"#[0-9A-Fa-f]{6}", colour):
            failures.append(f"{name}: {colour!r} is not a #rrggbb colour")
    if name not in rendered:
        failures.append(f"{name}: defined but never passed to render()")

for name in sorted(rendered - {n for n, _ in grids}):
    failures.append(f"{name}: rendered but no grid defines it")

if failures:
    print(f"{script.name}: {len(failures)} problem(s)", file=sys.stderr)
    for failure in failures:
        print(f"  {failure}", file=sys.stderr)
    sys.exit(1)

print(f"{len(grids)} grids, {cols}x{rows} = {expected} colours each -- all valid")
