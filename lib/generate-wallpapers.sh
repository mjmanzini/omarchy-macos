#!/usr/bin/env bash
#
# Render the theme wallpapers from the colour grids below.
#
# Storing six 2560x1600 16-bit PNGs in git costs ~15MB for what is, in the end,
# a smooth blend between a few dozen colours. Each wallpaper is instead a 9x7
# grid of control colours, written into a tiny image and scaled up to full size
# with a Lanczos filter -- ordinary image interpolation, which on a field this
# smooth is indistinguishable from the real thing (43-48dB PSNR against the
# originals) and produces no plateaus or seams.
#
# Output is 16-bit. That is not fussiness: an 8-bit gradient stretched over
# 2560px bands on large flat transitions, and these are almost entirely large
# flat transitions.
#
# To restyle a wallpaper, edit its grid. Rows run top to bottom, columns left to
# right, and the four corner entries are the image's corners.
#
#   ./generate-wallpapers.sh [output-root]
#
# output-root defaults to the repo's config/omarchy/themes, so install.sh picks
# the results up with the rest of the theme.

set -euo pipefail

WIDTH=2560
HEIGHT=1600
COLS=9
ROWS=7
FILTER=Lanczos

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_ROOT="${1:-$REPO/config/omarchy/themes}"

command -v magick >/dev/null || { echo "error: ImageMagick (magick) is required" >&2; exit 1; }

# --- macos-light ------------------------------------------------------------
read -r -d '' SEQUOIA_DAY <<'EOF' || true
#E8EFFB #E4ECFC #E1E6FC #D8CFFD #CDB9FF #CBB6FF #CBB6FF #CBB6FF #CBB6FF
#D1E1FD #C7DBFD #C7D3FE #CCC2FE #CCB7FF #CBB6FF #CBB6FF #CBB6FF #CBB6FF
#B3CFFE #ADCBFF #B2C6FF #C3BCFF #CBB6FF #CBB6FF #CBB6FF #CBB6FF #CBB6FF
#A9C8FF #ABC9FE #B3C7FE #C5C0FD #D1BBFD #D1BAFD #CFB9FE #CDB7FE #CCB7FF
#B2CAFD #C0CDFA #CECFF7 #DDCDF5 #E6CAF5 #E6C8F5 #E1C5F7 #D9C0FA #D4BFFC
#D2D0F6 #E7D4F1 #F3D7EF #F8D7EE #FBD6ED #FAD6EE #F8D4EF #F1D0F1 #EBD2F5
#F2D7EF #FCD8ED #FED9EC #FFD9EC #FFD9EC #FFD9EC #FFD9EC #FDD8ED #FBDAEE
EOF

read -r -d '' SONOMA_MIST <<'EOF' || true
#F0F2F8 #ECF0F8 #E9ECF9 #E2DBFC #D9CBFF #D7C9FF #D7C9FF #D7C9FF #D7C9FF
#DDE8FA #D5E4FB #D4DEFC #D8D2FE #D7CAFF #D7C9FF #D7C9FF #D7C9FF #D7C9FF
#C5DCFE #C0D9FE #C4D5FF #D1CDFF #D7C9FF #D7C9FF #D7C9FF #D7C9FF #D7C9FF
#BDD7FF #BED7FD #C4D6FB #D2D1FA #DBCDF9 #DCCCFA #DACBFB #D8CAFD #D7C9FF
#C4D8FA #CEDAF2 #DADCEA #E5DAE6 #ECD8E5 #ECD6E6 #E8D4EA #E2D0F2 #DED0F9
#DDDDE8 #ECE0DC #F6E1D6 #FAE1D3 #FCE1D3 #FBE1D3 #F9DFD6 #F4DDDC #F0DDE6
#F5E1D6 #FCE3D1 #FFE3CF #FFE3CF #FFE3CF #FFE3CF #FFE3CF #FEE2D1 #FCE3D5
EOF

# --- macos-dark -------------------------------------------------------------
read -r -d '' SEQUOIA_NIGHT <<'EOF' || true
#151720 #161A26 #1B1B2F #332253 #472975 #4A2A7A #4A2A7A #4A2A7A #4A2A7A
#192440 #1A294E #232A58 #3C296B #492A79 #4A2A7A #4A2A7A #4A2A7A #4A2A7A
#1D346B #1E3773 #273576 #3E2E78 #492A7A #4A2A7A #4A2A7A #4A2A7A #4A2A7A
#1F3A79 #1E3A79 #233877 #353175 #412D75 #432C75 #462B77 #482A79 #492A79
#1D3A75 #1B3A6F #1A3969 #203665 #283364 #2B3265 #313169 #392E6E #3F2A6D
#173A66 #133A5D #113A58 #123A56 #133955 #143956 #173858 #1E355B #242E55
#113A58 #103A54 #0F3A52 #0F3A52 #0F3A52 #0F3A52 #0F3A52 #113953 #12364E
EOF

read -r -d '' MIDNIGHT <<'EOF' || true
#0F1117 #0F131C #121422 #1E1938 #291E4F #2A1F52 #2A1F52 #2A1F52 #2A1F52
#111C31 #12213C #172141 #231F4A #2A1F51 #2A1F52 #2A1F52 #2A1F52 #2A1F52
#152B52 #152E58 #1A2B58 #252354 #2A1F52 #2A1F52 #2A1F52 #2A1F52 #2A1F52
#16305D #16305D #182F5B #202855 #262451 #272351 #282151 #292052 #2A1F51
#16325C #153459 #153655 #183451 #1C314E #1E304E #202D4F #23274F #25214B
#143754 #133B50 #133D4D #133D4B #143D4B #143C4B #153B4B #18364B #192C43
#133D4D #123E4B #123F4A #123F4A #123F4A #123F4A #123F4A #133E4A #133945
EOF

# --- ironman ----------------------------------------------------------------
# The reactor burning up through the gunmetal chassis, with the red plate
# underneath catching light along the bottom edge.
read -r -d '' ARC_REACTOR <<'EOF' || true
#05070C #060B10 #08141D #0D2633 #113141 #0D2633 #08141D #060B10 #05070C
#060A0F #081017 #0D232F #1F4C61 #316B84 #1F4C61 #0D232F #081017 #060A0F
#080E14 #0A1620 #143242 #3E7992 #96C9DA #3E7992 #143242 #0A1620 #080E14
#0A111A #0E1A26 #1A3647 #457891 #9DC2D2 #457891 #1A3647 #0E1A26 #0A111A
#0A0F16 #101720 #1E2836 #37485B #495D72 #37485B #1E2836 #101720 #0A0F16
#0A0C11 #141017 #261922 #3D232D #482632 #3D232D #261922 #141017 #0A0C11
#0A080B #170B0F #301015 #4D1419 #5A141A #4D1419 #301015 #170B0F #0A080B
EOF

# Light raking diagonally across a red plate and into the gold trim.
read -r -d '' HOT_ROD <<'EOF' || true
#070A0D #0D0A0C #160A0D #230A0D #320A0D #480B0E #600D10 #770E13 #8E1015
#0E0A0D #140A0D #1F0A0D #2E0A0D #450B0E #600D11 #780F13 #901115 #A51E17
#1B1014 #241217 #2F1014 #450E11 #5F0E11 #791014 #921416 #A82118 #BC2E1A
#2C1D24 #34252E #452029 #5F161C #7B1317 #951919 #AD2A1E #C23921 #D35229
#391E26 #482934 #5C252E #791B21 #971F1D #B33424 #CB4E2F #DD6E3D #E88C48
#521319 #65181F #7C181F #961D1D #B23122 #CE5130 #E3814A #F0A65D #F3B55F
#6D0F13 #831116 #991918 #B0281B #C83F23 #DD6F3C #EFA057 #F4BA64 #F3C662
EOF

# Write the grid out as a tiny PPM and let the resize filter do the blending.
render() {
  local grid="$1" dest="$2" body="" n=0 hex
  for hex in $grid; do
    [[ $hex =~ ^#[0-9A-Fa-f]{6}$ ]] || { echo "error: bad colour '$hex' in $dest" >&2; exit 1; }
    body+="$((16#${hex:1:2})) $((16#${hex:3:2})) $((16#${hex:5:2}))\n"
    n=$(( n + 1 ))
  done
  [[ $n -eq $(( COLS * ROWS )) ]] || { echo "error: $dest expects $(( COLS * ROWS )) colours, got $n" >&2; exit 1; }
  mkdir -p "$(dirname "$dest")"
  printf "P3\n%d %d\n255\n$body" "$COLS" "$ROWS" \
    | magick ppm:- -filter "$FILTER" -resize "${WIDTH}x${HEIGHT}!" -depth 16 "PNG48:$dest"
  echo "  $(basename "$(dirname "$(dirname "$dest")")")/$(basename "$dest")"
}

echo "Rendering wallpapers into ${OUT_ROOT/#$HOME/\~}"
render "$SEQUOIA_DAY"   "$OUT_ROOT/macos-light/backgrounds/1-sequoia-day.png"
render "$SONOMA_MIST"   "$OUT_ROOT/macos-light/backgrounds/2-sonoma-mist.png"
render "$SEQUOIA_NIGHT" "$OUT_ROOT/macos-dark/backgrounds/1-sequoia-night.png"
render "$MIDNIGHT"      "$OUT_ROOT/macos-dark/backgrounds/2-midnight.png"
render "$ARC_REACTOR"   "$OUT_ROOT/ironman/backgrounds/1-arc-reactor.png"
render "$HOT_ROD"       "$OUT_ROOT/ironman/backgrounds/2-hot-rod.png"
