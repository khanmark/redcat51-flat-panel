#!/usr/bin/env bash
# Regenerates the pictures in docs/images/ (needs OpenSCAD 2025+ with the manifold backend).
set -euo pipefail
cd "$(dirname "$0")"
OUT=images
mkdir -p "$OUT" .build
# Drop the "if (part == ...)" selector at the end of the model so views.scad can reuse its modules.
sed '/^if (part == "back")/,$d' ../scad/flat_panel.scad > .build/lib_flat_panel.scad
cp views.scad .build/views.scad

render() {  # name view camera(eye+center) [extra args]
    local name=$1 view=$2 cam=$3; shift 3
    openscad --backend=manifold --render -o "$OUT/$name.png" --imgsize=1400,1000 \
        --camera="$cam" --projection=p --colorscheme=Tomorrow --autocenter --viewall \
        -D "view=\"$view\"" "$@" .build/views.scad
}

#        name              view            camera: tx,ty,tz, rotx,roty,rotz, dist (dist is overridden by --viewall)
render   assembled         hero            0,0,0,60,0,25,500
render   telescope_side    front           0,0,0,-55,0,25,500
render   exploded          exploded        0,0,0,65,0,30,500
render   components_fit    fit             0,0,0,50,0,0,500
render   part_back         back            0,0,0,55,0,25,500
render   part_surround     surround        0,0,0,50,0,25,500
render   part_surround_front surround_front 0,0,0,50,0,25,500
render   part_collar       collar          0,0,0,50,0,25,500
render   part_diffuser     diffuser        0,0,0,50,0,25,500 -D diffuser_t=1.0
render   part_collar_nut_trap collar_nut_trap 0,0,0,40,0,25,500
# close-up of the nut pockets (fixed camera, no --viewall)
openscad --backend=manifold --render -o "$OUT/nut_trap_detail.png" --imgsize=1400,1000 \
    --camera=0,-45,0,55,0,20,170 --projection=p --colorscheme=Tomorrow \
    -D 'view="nut_detail"' .build/views.scad
# The same model scaled up for a ~120 mm-diffuser scope (see README, "Scaling it up")
render   scaled_example    hero            0,0,0,60,0,25,500 \
    -D collar_id=108 -D lip_id=105 -D diffuser_d=118 -D diffuser_recess_d=118.5 -D seat_id=116 -D skirt_id=120 -D cavity_id=130 -D cavity_depth=35 -D skirt_len=17
render   scaled_example_exploded exploded  0,0,0,65,0,30,500 \
    -D collar_id=108 -D lip_id=105 -D diffuser_d=118 -D diffuser_recess_d=118.5 -D seat_id=116 -D skirt_id=120 -D cavity_id=130 -D cavity_depth=35 -D skirt_len=17
python3 -I annotate.py
rm -rf .build
echo "images written to docs/$OUT"
