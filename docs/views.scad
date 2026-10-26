// Documentation renders for the flat panel. Not needed to print the panel.
// Run docs/render_images.sh - it strips the part-selector tail off scad/flat_panel.scad
// (so its modules can be reused here) and renders every image in docs/images/.
include <lib_flat_panel.scad>

view = "hero";   // hero, front, exploded, section, fit, back, surround, surround_front, collar

c_collar   = "#2b2b2b";
c_surround = "#e8e8e8";
c_back     = "#f2efe6";
c_diffuser = "#9fd3ff";
c_led      = "#ffd23f";
c_parts    = "#e8590c";
c_bolt     = "#b0b7c0";

// ---- component stand-ins (visual only, sizes from the .scad parameters) ----
// the printed diffuser in the surround frame (front face at z=0): rim on the front face, thin centre at the back
module diffuser_disc()  color(c_diffuser, 0.8) translate([0, 0, diffuser_t - 0.05]) mirror([0, 0, 1]) diffuser();

// LED strip stood on edge around the outside of the baffle skirt, resting on the front ring
module led_strip_ring() color(c_led) translate([0, 0, front_t]) difference() {
    cylinder(d = skirt_id + 2 * skirt_t + 2 * 0.4 + 2 * 1.2, h = 10);
    translate([0, 0, -1]) cylinder(d = skirt_id + 2 * skirt_t + 2 * 0.4, h = 12);
}

module strip_connector() color(c_parts)
    rotate(wire_angle) translate([skirt_or + 0.5 + conn_clear / 2, -conn_l / 2, front_t])
        cube([conn_t, conn_l, conn_w]);

module buck_converter() color(c_parts)
    rotate(pk_angle) translate([wall_or + puck_clear, -puck_l / 2, pk_floor + puck_clear])
        cube([puck_t, puck_l, puck_w]);

module nut() color(c_bolt) difference() {
    cylinder(d = 6.35, h = 2.4, $fn = 6);
    translate([0, 0, -1]) cylinder(d = 3, h = 5, $fn = 24);
}

// Everything in the "as modeled" frame: collar flange at z=0 and the collar pointing +z,
// surround at z<0 (front face against the flange), back wall furthest from the collar.
module parts_assembled(gap = 0, show_internals = true) {
    color(c_collar)   translate([0, 0, 0]) collar();
    translate([0, 0, -gap]) {
        color(c_surround) mirror([0, 0, 1]) surround();
        if (show_internals) {
            mirror([0, 0, 1]) {
                diffuser_disc();
                led_strip_ring();
                strip_connector();
                buck_converter();
            }
        }
    }
    color(c_back) translate([0, 0, -surround_h - back_t - 2 * gap]) back_wall();
}

// M3x40 bolt per lug: head on the outside of the back wall, nut on the end of the collar tab
module hardware(gap = 0, bolt_len = cavity_depth + 20) for (a = lug_angles) rotate(a) translate([lug_r, 0, 0]) {
    z_face = -surround_h - back_t - 2 * gap;   // outer face of the back wall
    color(c_bolt) translate([0, 0, z_face - 3]) cylinder(d = 5.5, h = 3, $fn = 24);
    color(c_bolt) translate([0, 0, z_face]) cylinder(d = 3, h = bolt_len, $fn = 24);
    translate([0, 0, insert_tab_t]) nut();
}

// nut-trap build: M3x35 bolt, nut sitting in the pocket on the surround side of the collar tab
module hardware_nut_trap() for (a = lug_angles) rotate(a) translate([lug_r, 0, 0]) {
    z_face = -surround_h - back_t;
    color(c_bolt) translate([0, 0, z_face - 3]) cylinder(d = 5.5, h = 3, $fn = 24);
    color(c_bolt) translate([0, 0, z_face]) cylinder(d = 3, h = back_t + surround_h + insert_tab_t, $fn = 24);
    translate([0, 0, 0.1]) nut();
}

if (view == "hero") {                       // like the original render: back wall up, collar down
    rotate([180, 0, 0]) parts_assembled(0, false);
} else if (view == "front") {               // from the telescope side: collar flange facing the viewer
    parts_assembled(0, false);
} else if (view == "exploded") {
    parts_assembled(30, true);
    hardware(30);
} else if (view == "section") {             // quarter cut through the wire-exit box, seen from the cut side
    rotate(-wire_angle) difference() {
        rotate(wire_angle) union() { parts_assembled(0, true); hardware(0); }
        translate([0, -200, -200]) cube([400, 200, 400]);
    }
} else if (view == "fit") {                 // everything in place, back wall off, open side up
    rotate([180, 0, 0]) rotate(-wire_angle + 90) {
        color(c_collar) collar();
        color(c_surround) mirror([0, 0, 1]) surround();
        mirror([0, 0, 1]) { diffuser_disc(); led_strip_ring(); strip_connector(); buck_converter(); }
    }
} else if (view == "back")           rotate([0, 0, 0]) color(c_back) back_wall();
else if (view == "surround")         rotate([180, 0, 0]) color(c_surround) surround();   // open (back) side up
else if (view == "surround_front")   color(c_surround) surround();                       // front face up
else if (view == "collar")           color(c_collar) collar();
else if (view == "collar_nut_trap")  rotate([180, 0, 0]) color(c_collar) collar(true);   // flange face up: pockets visible
else if (view == "nut_detail") {                                                            // pockets, one nut seated, one hovering
    rotate([180, 0, 0]) {
        color(c_collar) collar(true);
        rotate(210) translate([lug_r, 0, 0.1]) nut();
        rotate(90)  translate([lug_r, 0, -9])  nut();
    }
}
else if (view == "diffuser")         color(c_diffuser) diffuser();
