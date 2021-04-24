//$fn = 120;
$fa = 3;
$fs = 0.1;
check_collision = 0; // [0=normal; 1=show intersection]
show_mode = 1; // [0=both; 1=block; 2=cap]

// Lead screw appears to be positioned 21mm in from the edge,
// and 21mm out from the extrusion.
block_width = 42;   // double the lead screw position
block_height = 20;  // extrustion width
block_length = 42;  // double the lead screw position
cap_adjustment = 4; // how far for cap can adjust back and forth

// Cap dimensions.
cap_width = 26;     // not critical
cap_height = 2.5;   // too thick causes internal interference in the block
cap_length = 36;    // too long causes thin walls in the block
cap_slot_inset = 3; // too small causes thin walls in the cap

// Bearing dimensions for a lead screw support bearing (688ZZ).
bearing_od = 16;
bearing_id = 8;
bearing_width = 5;

// Use an M5x20 bolt and T-nut to attach to extrusion. Tolerance
// tweaked so that bolt fits in printed hole.
mounting_bolt_diam = 5+0.4;
mounting_bolt_relief_diam = 9+0.4;
mounting_bolt_hold = 20 - 5.25; // Adjust for shorter bolts

// Use an M3x10 to attach the cap to the block. Tolerance tweaked
// so that bolt fits in printet hole and nut in printer slot.
cap_retention_bolt_diam = 3+0.4;
cap_retention_nut_height = 2.6+0.6;
cap_retention_nut_width = 5.5+0.4;
cap_retention_nut_depth = 10 - 1 - cap_retention_nut_height; // Adjust for shorter bolts
cap_retention_bolt_inset = 8;
cap_retention_bolt_hole_spacing = block_length - (2 * cap_retention_bolt_inset);

// Tolerance so that printed cap slides easily in printed block.
cap_tolerance = 0.4;

module sunken_bolt_hole(diam, depth, hold, relief_diam)
{
    translate([0, 0, -(depth+0.1)])
    {
        hull()
        {
            cylinder(r = diam/2, h = depth+0.2);
            translate([0, -diam/3.2, 0])
                cylinder(r = diam/4, h = depth+0.2, $fn = 4);
        }
    }
    translate([0, 0, -depth + hold])
    {
        hull()
        {
            cylinder(r = relief_diam/2, h = depth-hold+0.1);
            translate([0, -relief_diam/3.2, 0])
                cylinder(r = relief_diam/4, h = depth-hold+0.1, $fn = 4);
        }
    }
}

module slotted_hole(diam, depth, hold, slot_height, slot_width, angle)
{
    difference()
    {
        union()
        {
            translate([0, 0, -depth])
                cylinder(r = diam/2, h = depth+0.1);
            translate([0, 0, -(hold + slot_height)])
            {
                rotate([0, 0, angle])
                    translate([-slot_width/2, 0, 0])
                    cube([slot_width, slot_width*2, slot_height]);
                rotate([0, 0, 90+angle])
                    cylinder(r = slot_width/(2*sin(60)),
                        h = slot_height, $fn = 6);
            }
        }
        union()
        {
            translate([0, 0, -hold])
                cylinder(r = diam/2, h = 0.2);
        }
    }
}

module filleted_box(x, y, z, radius=1)
{
    hull()
    {
        translate([radius, radius, 0])
            cylinder(r = radius, h = z);

        translate([x - radius, radius, 0])
            cylinder(r = radius, h = z);

        translate([radius, y - radius, 0])
            cylinder(r = radius, h = z);

        translate([x - radius, y - radius, 0])
            cylinder(r = radius, h = z);
    }
}

module half_filleted_box(x, y, z, radius=1)
{
    hull()
    {
        cube([x, 1, z]);

        translate([radius, y - radius, 0])
            cylinder(r = radius, h = z);

        translate([x - radius, y - radius, 0])
            cylinder(r = radius, h = z);
    }
}

module block()
{
    difference()
    {
        // Block body
        half_filleted_box(block_width, block_length, block_height, 5);

        union()
        {
            // Right side mounting bolt hole
            translate([10, block_length, block_height / 2])
                rotate([270, 0, 0])
                sunken_bolt_hole(mounting_bolt_diam, block_length,
                    mounting_bolt_hold, mounting_bolt_relief_diam);

            // Left side mounting bolt hole
            translate([block_width - 10, block_length, block_height / 2])
                rotate([270, 0, 0])
                sunken_bolt_hole(mounting_bolt_diam, block_length,
                    mounting_bolt_hold, mounting_bolt_relief_diam);
            
            // Front cap retaining bolt hole
            translate([block_width / 2, cap_retention_bolt_inset,
                    block_height - cap_height])
                slotted_hole(cap_retention_bolt_diam,
                    block_height - cap_height - 2,
                    cap_retention_nut_depth, cap_retention_nut_height,
                    cap_retention_nut_width, 180);

            // Rear cap retaining bolt hole
            translate([block_width / 2, cap_retention_bolt_inset +
                    cap_retention_bolt_hole_spacing, block_height - cap_height])
                slotted_hole(cap_retention_bolt_diam,
                    block_height - cap_height - 2,
                    cap_retention_nut_depth, cap_retention_nut_height,
                    cap_retention_nut_width, 0);

            // Cap movement slot +/- 1.5mm movement
            slot_width = bearing_od + 2 + cap_tolerance;
            slot_length = bearing_od + cap_tolerance + cap_adjustment;
            slot_depth = bearing_width;
            translate([(block_width - slot_width) / 2,
                    (block_length - slot_length) / 2,
                    (block_height - slot_depth - cap_height)])
                filleted_box(slot_width, slot_length, slot_depth+0.1, 3);
            translate([(block_width - (cap_width + cap_tolerance)) / 2,
                    (block_length - (cap_length + cap_tolerance +
                    cap_adjustment)) / 2, (block_height - cap_height)])
                filleted_box(cap_width + cap_tolerance, cap_length + cap_adjustment + cap_tolerance, cap_height+0.1, 5);

            // Lead screw clearance slot
            hull()
            {
                translate([block_width / 2, block_length / 2 - 3, -0.1])
                    cylinder(r = (((bearing_od + bearing_id) / 4) - 1 ),
                        h = block_height+0.2);
                translate([block_width / 2, block_length / 2 + 3, -0.1])
                    cylinder(r = (((bearing_od + bearing_id) / 4) - 1 ),
                        h = block_height+0.2);
            }
        }
    }
}

module cap()
{
    difference()
    {
        union()
        {
            // Cap body
            filleted_box(cap_width, cap_length, cap_height, 5);

            // Cap bearing retainer
            translate([(cap_width - (bearing_od + 2)) / 2,
                    (cap_length - bearing_od) / 2, cap_height])
                filleted_box(bearing_od + 2, bearing_od, bearing_width, 3);
        }

        union()
        {
            // Bearing housing
            translate([cap_width / 2, cap_length / 2, cap_height])
                cylinder(r = (bearing_od / 2)+0.05, h = bearing_width+0.1);
            translate([(cap_width - bearing_id)/2,
                    (cap_length - bearing_od) / 2-0.1, cap_height])
                cube([bearing_id, bearing_od+0.2, bearing_width+0.1]);

            // Lead screw clearance hole
            translate([cap_width / 2, cap_length / 2, -0.1])
                cylinder(r = (bearing_od + bearing_id) / 4,
                    h = cap_height + bearing_width + 0.2);

            // Front cap retaining bolt slot
            hull()
            {
                translate([cap_width / 2, cap_slot_inset - 0.1, -0.1])
                    cylinder(r = cap_retention_bolt_diam/2, h = cap_height+0.2);
                translate([cap_width / 2, cap_adjustment +
                        cap_slot_inset + 0.1, -0.1])
                    cylinder(r = cap_retention_bolt_diam/2, h = cap_height+0.2);
            }

            // Rear cap retaining bolt slot
            hull()
            {
                translate([cap_width / 2, cap_retention_bolt_hole_spacing + 
                        cap_slot_inset - 0.1, -0.1])
                    cylinder(r = cap_retention_bolt_diam/2, h = cap_height+0.2);
                translate([cap_width / 2, cap_retention_bolt_hole_spacing +
                        cap_adjustment + cap_slot_inset + 0.1, -0.1])
                    cylinder(r = cap_retention_bolt_diam/2, h = cap_height+0.2);
            }
        }
    }
}

if (check_collision == 1)
{
    // Show up the contant points between block and cap.
    intersection()
    {
        position = 3; // [0-3]
        block();
        translate([(block_width + cap_width) / 2,
                position + 1, block_height-0.01])
                rotate([0, 180, 0])
            cap();
    }
}
else
{
    if (show_mode != 2)
    {
        translate([5, 0, 0])
            block();
    }
    if (show_mode != 1)
    {
        translate([-5-cap_width, 0, 0])
            cap();
    }
}
