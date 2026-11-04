#!/usr/bin/env bash
# Exports every STL from flat_panel.scad in one go (needs OpenSCAD 2021.01 or newer).
#   scad/export_stls.sh            writes stl/ and optional/ in this repo
#   scad/export_stls.sh some/dir   writes some/dir/stl and some/dir/optional instead
# Pass your own settings after --, e.g.  scad/export_stls.sh . -- -D collar_id=95
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=${1:-.}
[ "$#" -gt 0 ] && shift
[ "${1:-}" = "--" ] && shift
mkdir -p "$OUT/stl" "$OUT/optional"
SCAD=scad/flat_panel.scad

# The collar and back wall come out mirrored on purpose (see the note at the bottom of the scad file).
for part in collar surround back diffuser; do
    openscad -o "$OUT/stl/flat_panel_$part.stl" -D "part=\"$part\"" "$@" "$SCAD"
done
openscad -o "$OUT/optional/flat_panel_collar_heat_insert.stl" -D 'part="collar_heat_insert"' "$@" "$SCAD"
openscad -o "$OUT/optional/flat_panel_diffuser_0.6mm.stl" -D 'part="diffuser"' -D diffuser_center_t=0.6 "$@" "$SCAD"
echo "STLs written to $OUT/stl and $OUT/optional"
