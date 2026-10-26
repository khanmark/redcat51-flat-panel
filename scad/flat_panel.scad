// DIY slip-on flat panel for RedCat 51 / Rokinon 135
// Three support-free parts held together by 3x M3x40 bolts + M3 hex nuts
// (or 3x M3x35 bolts + M3 heat-set inserts, see insert_d below).
//
// Print orientations (as modeled):
//   back      - flat on bed, spigot up
//   surround  - front face (diffuser recess) down
//   collar    - flange down
//   diffuser  - flat on the bed (optional 3D-printed disc; set diffuser_t to 0.6 or 1.0)
//
// Assembly (front to back):
//   collar flange -> diffuser disc (sits in surround's front recess) -> surround -> back wall
//   Bolts go in from the back wall, through the surround lugs and the collar tabs; a hex nut on the
//   end of each collar tab clamps the stack (or the bolt threads into a heat-set insert instead).

part = "all"; // [back, surround, collar, diffuser, all, exploded]

/* [Fit] */
collar_id    = 81;    // matches the proven cover: 81 ID / 86 OD - slides over RedCat shield, inside Rokinon hood; no felt
collar_depth = 25;
wall         = 2.5;
lip_id       = 78;    // stop lip - shield/barrel bottoms out here
flange_t     = 2.5;

/* [Diffuser] */
diffuser_d        = 88;   // opal acrylic disc diameter
diffuser_recess_d = 88.5; // recess for the disc
diffuser_t        = 3;    // recess depth = disc thickness (flange clamps it); measure your disc and set this.
                          // 3D-printed diffuser: set 0.6 or 1.0 here and export BOTH part="diffuser" and part="surround"
seat_id           = 86;   // light opening; disc rests on this ring

/* [Cavity] */
cavity_id    = 100;
cavity_depth = 20;
front_t      = 4;     // front annulus thickness (includes diffuser recess)
skirt_id     = 90;    // baffle skirt hides LEDs from the diffuser
skirt_t      = 1.5;
skirt_len    = 10;

/* [Back wall] */
back_t       = 3;
spigot_h     = 2;
spigot_w     = 2;
spigot_clear = 0.2;   // per side

/* [Wire exit] - open slot through the side of the connector box, so wires leave the connector straight */
wire_angle   = 140;   // box + pocket assembly position, rotated to keep the longer pocket clear of the 210-degree lug
slot_w       = 4;     // radial width of the connector-to-converter slot
dc_slot_w    = 3;     // DC lead exit slot in the far end of the converter pocket

/* [Strip connector] - solderless strip-to-wire clip; slides down a channel from the open back */
conn_w       = 11.5;  // across the strip (axial)
conn_l       = 13.5;  // along the strip (tangential)
conn_t       = 4.2;   // thickness (radial)
conn_clear   = 0.5;

/* [Buck converter pocket] - outside the main wall, next to the side slot; slides in from the back, back wall seals it */
puck_l       = 25.5;  // along the wall
puck_w       = 17;    // front-to-back
puck_t       = 4.5;   // thickness
puck_clear   = 0.5;
puck_clear_l = 4;     // extra room along the wall (per end) for leads and fingers
puck_wall    = 1.6;

/* [Fasteners] */
lug_d        = 8;
screw_clear  = 3.4;
insert_d     = 4.0;   // hole in the collar tabs: bolt pass-through when using hex nuts; or check your heat-set insert's recommended hole size
insert_tab_t = 8;
lug_angles   = [90, 210, 330];

$fn = 180;

outer_d    = cavity_id + 2 * wall;          // 105
lug_r      = outer_d / 2 + lug_d / 2 - 1;   // 55.5
surround_h = front_t + cavity_depth;        // 24

module lug_pads(h) {
    for (a = lug_angles) rotate(a) hull() {
        translate([lug_r, 0, 0]) cylinder(d = lug_d, h = h);
        translate([outer_d / 2 - 5, 0, 0]) cylinder(d = lug_d, h = h);
    }
}

module lug_holes(d, h) {
    for (a = lug_angles) rotate(a)
        translate([lug_r, 0, -1]) cylinder(d = d, h = h + 2);
}

skirt_or   = skirt_id / 2 + skirt_t;                  // 46.5
chan_extra = 2;                                       // extra outward room so wires can exit beside the main wall
chan_out_r = skirt_or + conn_t + conn_clear + chan_extra;  // 53.2 - outer face of the connector channel
chan_len   = conn_l + 2 * conn_clear + 10;            // tangential length: connector + ~5mm each end for the wire bend
bump_wall  = 2.3;

// local thickening of the outer wall so the channel has a wall behind it
module conn_bump(h = surround_h) {
    rotate(wire_angle) translate([cavity_id / 2 - 2, -(chan_len / 2 + 2.5), 0])
        cube([chan_out_r + bump_wall - (cavity_id / 2 - 2), chan_len + 5, h]);
}

// buck converter pocket, placed tangent to the main wall right after the connector box
wall_or      = outer_d / 2;                                       // 52.5
pk_in_l      = puck_l + 2 * puck_clear_l;                         // 33.5
pk_in_w      = puck_w + 2 * puck_clear;                           // 18
pk_in_t      = puck_t + 2 * puck_clear;                           // 5.5
pk_half      = pk_in_l / 2 + puck_wall;
bump_half    = chan_len / 2 + 2.5;
pk_angle     = wire_angle + (bump_half + pk_half) / wall_or * 180 / PI;
pk_floor     = surround_h - pk_in_w;                              // pocket open to the back edge

module puck_body(h = surround_h) {
    rotate(pk_angle) translate([cavity_id / 2 - 2, -pk_half, 0])
        cube([wall_or + pk_in_t + puck_wall - (cavity_id / 2 - 2), 2 * pk_half, h]);
}

// connector box + converter pocket as one continuous outside shape
module side_body(h = surround_h) { hull() { conn_bump(h); puck_body(h); } }

module puck_void() {
    rotate(pk_angle) {
        translate([wall_or, -pk_in_l / 2, pk_floor]) cube([pk_in_t, pk_in_l, surround_h]);
        // DC lead exit through the far end wall, open to the back edge
        translate([wall_or + (pk_in_t - dc_slot_w) / 2, pk_in_l / 2 - 1, front_t]) cube([dc_slot_w, puck_wall + 2, surround_h]);
    }
}

// open slot through one side wall of the box, from the front ring to the back edge (back wall closes the top)
module side_slot() {
    rotate(wire_angle) translate([chan_out_r - slot_w, chan_len / 2 - 1, front_t])
        cube([slot_w, 2.5 + 8, surround_h]);   // runs through into the buck converter pocket
}

// full-height channel at the strip-joint location; connector drops in from the back, rests on the front ring
module conn_channel() {
    rotate(wire_angle) translate([skirt_or + 0.5, -chan_len / 2, front_t])
        cube([chan_out_r - skirt_or - 0.5, chan_len, surround_h]);
}

module back_wall() {
    difference() {
        union() {
            cylinder(d = outer_d, h = back_t);
            side_body(back_t);     // match the surround's outline
            lug_pads(back_t);
            translate([0, 0, back_t]) difference() {
                cylinder(d = cavity_id - 2 * spigot_clear, h = spigot_h);
                translate([0, 0, -1])
                    cylinder(d = cavity_id - 2 * spigot_clear - 2 * spigot_w, h = spigot_h + 2);
            }
        }
        lug_holes(screw_clear, back_t + spigot_h);
    }
}

module surround() {
    difference() {
        union() {
            cylinder(d = outer_d, h = surround_h);
            lug_pads(surround_h);
            side_body();
        }
        translate([0, 0, front_t]) cylinder(d = cavity_id, h = surround_h);
        conn_channel();
        translate([0, 0, -1]) cylinder(d = seat_id, h = front_t + 2);
        // diffuser recess with a 45-degree seat (no flat overhang); 88mm disc lands flush with front face
        chamfer_h = (diffuser_recess_d - seat_id) / 2;
        flat_h    = diffuser_t - (diffuser_recess_d - diffuser_d) / 2;
        translate([0, 0, -1]) cylinder(d = diffuser_recess_d, h = flat_h + 1);
        translate([0, 0, flat_h - 0.01])
            cylinder(d1 = diffuser_recess_d, d2 = seat_id, h = chamfer_h + 0.01);
        lug_holes(screw_clear, surround_h);
        side_slot();
        puck_void();
    }
    translate([0, 0, front_t]) difference() {
        cylinder(d = skirt_id + 2 * skirt_t, h = skirt_len);
        translate([0, 0, -1]) cylinder(d = skirt_id, h = skirt_len + 2);
    }
}

module collar() {
    difference() {
        union() {
            cylinder(d = outer_d, h = flange_t);
            side_body(flange_t);   // match the surround's outline
            lug_pads(insert_tab_t);
            cylinder(d = collar_id + 2 * wall, h = flange_t + collar_depth);
        }
        translate([0, 0, -1]) cylinder(d = lip_id, h = 100);
        translate([0, 0, flange_t]) cylinder(d = collar_id, h = 100);
        lug_holes(insert_d, insert_tab_t);
    }
}

// optional 3D-printed diffuser disc; its thickness is diffuser_t so it lands flush in the surround recess
module diffuser() {
    cylinder(d = diffuser_d, h = diffuser_t);
}

module assembly(gap = 0) {
    collar();
    translate([0, 0, -gap]) mirror([0, 0, 1]) surround();
    translate([0, 0, -surround_h - back_t - 2 * gap]) back_wall();
}

if (part == "back")          back_wall();
else if (part == "surround") surround();
else if (part == "collar")   collar();
else if (part == "diffuser") diffuser();
else if (part == "exploded") assembly(25);
else                         assembly(0);
