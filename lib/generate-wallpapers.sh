#!/usr/bin/env bash
#
# Render the four macOS-style gradient wallpapers into the theme folders.
#
# Storing four 2560x1600 16-bit PNGs in git costs 10MB for what is, in the end,
# a smooth blend between a handful of colours. Each wallpaper is instead
# described by a 7x6 grid of control colours below, and ImageMagick interpolates
# between them with Shepards (inverse-distance) weighting.
#
# The grids were fitted by least squares against the original renders, so what
# comes out matches them to about 1.2% RMSE (38-41dB PSNR) -- no visible
# difference on a gradient this smooth.
#
# Output is 16-bit. That is not fussiness: an 8-bit gradient stretched over
# 2560px shows banding on large flat transitions, and these wallpapers are
# almost entirely large flat transitions.
#
#   ./generate-wallpapers.sh [output-root]
#
# output-root defaults to the repo's config/omarchy/themes, so install.sh picks
# the results up with the rest of the theme.

set -euo pipefail

WIDTH=2560
HEIGHT=1600
POWER=3          # inverse-distance exponent; 3 keeps the plateaus flat
COLS=7
ROWS=6

# Shepards weighting is evaluated per pixel against every control point, which
# costs ~6s per wallpaper at full size. The field has no detail finer than the
# control grid, so it is rendered at a fraction of the size and scaled up --
# same result to within 0.0001 RMSE, roughly twenty times faster.
RENDER_WIDTH=320
RENDER_HEIGHT=200

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_ROOT="${1:-$REPO/config/omarchy/themes}"

command -v magick >/dev/null || { echo "error: ImageMagick (magick) is required" >&2; exit 1; }

# Control grids, row-major, top row first. Each is COLS x ROWS colours spread
# evenly over the image, corners included.
read -r -d '' SEQUOIA_DAY <<'EOF' || true
#F1F4FB #EEF4FB #E5E5FC #CDB8FF #CAB5FF #CBB6FF #CBB6FF
#D8E6FC #C8DEFD #CACCFE #CBB4FF #CAB5FF #CBB5FF #CBB6FF
#ABCBFF #A3C9FF #B4BFFF #CBB4FF #CAB4FF #C9B5FF #CAB5FF
#A5C7FF #B1CBFC #C9CBF9 #E0C4F7 #DDC1F9 #D2BBFC #CDBAFF
#CCCFF7 #ECD6F0 #FCD9ED #FFD9EC #FED7ED #F4D2F0 #EBD5F6
#FAD8ED #FFDAEB #FFDAEB #FFDAEB #FFDAEB #FFDAEB #FFDCED
EOF

read -r -d '' SONOMA_MIST <<'EOF' || true
#F6F6F7 #F4F6F7 #EDEAF9 #D9CAFF #D6C8FF #D7C9FF #D7C9FF
#E3ECFA #D6E6FB #D7D9FD #D7C7FF #D6C8FF #D7C9FF #D7C9FF
#BFD9FF #B8D7FF #C5D0FF #D7C7FF #D6C8FF #D6C8FF #D6C8FF
#B9D6FF #C3D9F9 #D6D9EF #E7D3EC #E5D1EF #DDCCF8 #D8CCFF
#D8DCEB #F0E1D9 #FCE3D0 #FFE3CF #FEE2D0 #F7DED9 #F0E0E8
#FBE2D2 #FFE4CD #FFE4CD #FFE4CD #FFE4CD #FFE4CD #FFE5D1
EOF

read -r -d '' SEQUOIA_NIGHT <<'EOF' || true
#131213 #111415 #20192E #492976 #4C2A7C #4B2A7A #4A2A7A
#171F35 #172849 #2F285F #4E2A7C #4C2A7C #4B2A7B #4B2A7A
#1E3773 #1D3B7B #33347D #4E297C #4D297C #4C297C #4C2A7C
#1F3B7C #1B3B76 #20386D #32316A #372F6D #422C75 #472873
#183A69 #123A5B #0F3B53 #103A52 #113A54 #1B3659 #222B4E
#103A54 #0E3A50 #0E3A50 #0D3B50 #0C3B50 #0D3B51 #0E374C
EOF

read -r -d '' MIDNIGHT <<'EOF' || true
#0D0C0D #0D0E0F #141220 #291E4F #2B1F53 #2A1F52 #2A1F52
#101828 #112039 #1C1F43 #2C1E53 #2B1F53 #2A1F52 #2A1F52
#152D58 #15315F #1F295B #2C1E53 #2B1E53 #2B1E53 #2B1E53
#163060 #15335D #183356 #202C4F #22294F #272351 #281D4D
#143756 #133C4F #123F4B #123F4A #133E4A #17384B #18283D
#123E4B #124049 #124049 #11404A #11414A #11404A #113C45
EOF

# Turn a grid of colours into "x,y #rrggbb x,y #rrggbb ..." across the canvas.
render() {
  local grid="$1" dest="$2" points i=0 col row x y
  points=""
  for hex in $grid; do
    col=$(( i % COLS )); row=$(( i / COLS ))
    x=$(awk -v c="$col" -v n="$COLS" -v w="$RENDER_WIDTH"  'BEGIN{printf "%.3f", c*(w-1)/(n-1)}')
    y=$(awk -v r="$row" -v n="$ROWS" -v h="$RENDER_HEIGHT" 'BEGIN{printf "%.3f", r*(h-1)/(n-1)}')
    points+="$x,$y $hex "
    i=$(( i + 1 ))
  done
  [[ $i -eq $(( COLS * ROWS )) ]] || { echo "error: $dest expects $(( COLS * ROWS )) colours, got $i" >&2; exit 1; }
  mkdir -p "$(dirname "$dest")"
  magick -size "${RENDER_WIDTH}x${RENDER_HEIGHT}" xc: \
         -define "shepards:power=$POWER" \
         -sparse-color shepards "$points" \
         -filter Lanczos -resize "${WIDTH}x${HEIGHT}!" \
         -depth 16 "PNG48:$dest"
  echo "  $(basename "$(dirname "$(dirname "$dest")")")/$(basename "$dest")"
}

echo "Rendering wallpapers into ${OUT_ROOT/#$HOME/\~}"
render "$SEQUOIA_DAY"   "$OUT_ROOT/macos-light/backgrounds/1-sequoia-day.png"
render "$SONOMA_MIST"   "$OUT_ROOT/macos-light/backgrounds/2-sonoma-mist.png"
render "$SEQUOIA_NIGHT" "$OUT_ROOT/macos-dark/backgrounds/1-sequoia-night.png"
render "$MIDNIGHT"      "$OUT_ROOT/macos-dark/backgrounds/2-midnight.png"
