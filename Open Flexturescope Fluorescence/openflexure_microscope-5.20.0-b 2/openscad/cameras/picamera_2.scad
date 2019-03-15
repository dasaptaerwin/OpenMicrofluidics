/******************************************************************
*                                                                 *
* OpenFlexure Microscope: Raspberry Pi Camera v2 push-fit mount   *
*                                                                 *
* This is part of the OpenFlexure microscope, an open-source      *
* microscope and 3-axis translation stage.  It gets really good   *
* precision over a ~10mm range, by using plastic flexure          *
* mechanisms.                                                     *
*                                                                 *
* This file provides two parts for the microscope; the bit that   *
* fits onto the camera (picam2_camera_mount) and a cover that     *
* protects the PCB (picam_cover).  The former is part of the      *
* optics module in optics.scad, and the latter is printed         *
* directly.                                                       *
*                                                                 *
* The fit is set by one main function, picam2_push_fit().  It's   *
* designed to be subtracted from a solid block, with the bottom   *
* of the block at z=0.  It grips the plastic camera housing with  *
* four slightly flexible fingers, which ensures the camera pops   *
* in easily but is held relatively firmly.  Two screw holes are   *
* also provided that should self-tap with M2 or similar screws.   *
* I recommend you use these for extra security if the camera is   *
* likely to be handled a lot.                                     *
*                                                                 *
* (c) Richard Bowman, January 2016                                *
* Released under the CERN Open Hardware License                   *
*                                                                 *
******************************************************************/


use <../utilities.scad>;

d=0.05; //small distance!

function picamera_2_camera_mount_height() = 4.5;
bottom = picamera_2_camera_mount_height() * -1;

function picamera_2_camera_sensor_height() = 2; //Height of the sensor above the PCB

module picam2_flex_and_components(cw=8.5+1){
    // A 2D perimeter inside which the flex and components of the camera sit.
    // NB this should fit both v1 and v2 of the module
    // cw is the width of the camera module's casing, nominally 8 or 8.5mm but
    // deliberately printed a bit generous to ensure it fits easily without 
    // damaging the flex.
    
    translate([-cw/2,cw/2-1]) square([cw,13.4-cw/2+1]); //flex (also clears v1 connector)
    translate([-cw/2-2.5,6.7]) square([cw+2.5, 5.4]); //connector
}

module picam1_led(){
    // v1 of the camera module has an LED on board that we should make a cut-out for
    translate([5,10]) square([3.5,2]);
    translate([6,8]) square([3.5,2]);
}
    
module picam2_cutout( beam_length=15){
    // This module is designed to be subtracted from the bottom of a shape.
    // The z=0 plane should be the print bed.
    // It includes cut-outs for the components on the PCB and also a push-fit hole
    // for the camera module.  This uses flexible "fingers" to grip the camera firmly
    // but gently.  Just push to insert, and wiggle to remove.  You may find popping 
    // off the brown ribbon cable and removing the PCB first helps when extracting
    // the camera module again.
    cw = 8.5 + 1.0; //size of camera box sides (NB deliberately loose fitting)
    ch=2.9; //height of camera box (including foam support)
    camera = [cw,cw,ch]; //size of camera box
    hole_r = 4.3; //size of camera aperture
	union(){
        sequential_hull(){
            //cut-out for camera
            translate([0,0,-d]) cube([cw+0.5,cw+0.5,d],center=true); //wider at bottom
            translate([0,0,0.5]) cube([cw,cw,d],center=true);
            translate([0,0,ch/2]) cube([cw,cw,ch],center=true);
            cylinder(r=hole_r, h=2*picamera_2_camera_mount_height(), center=true);
        }
            
        //clearance for the ribbon cable at top of camera
        fh=2.5; // the height of the flex
        mh = picamera_2_camera_mount_height();
        
        dz = mh-fh-0.75; // extra height above the flex for the sloping "roof"
        rw = cw - 2*dz; 
        hull(){
            translate([0,0,-d]) linear_extrude(fh) picam2_flex_and_components(cw);
            translate([0,0,-d]) linear_extrude(fh+dz) offset(-dz) picam2_flex_and_components(cw);
        }
        //clearance for the LED/resistor on v1 of the camera
        hull(){
            translate([0,0,-d]) linear_extrude(fh) picam1_led();
            translate([0,0,-d]) linear_extrude(fh+dz) offset(-dz) picam1_led();
        }
        
        //beam clearance
        cylinder(r=hole_r, h=beam_length);
        
        //chamfered screw holes for mounting
        sx = 21/2; //position of screw holes
        reflect([1,0,0]) translate([sx,0,0]) rotate(60){
            //cylinder(r1=3, r2=0,h=4, center=true); //chamfered bottom
            //deformable_hole_trylinder(1.5/2,2.1/2,h=12, center=true);
            cylinder(r1=3.1, r2=1.1, h=5, $fn=3, center=true);
            cylinder(r=1.1, h=20, $fn=3, center=true);
        }
	}
}
//picam2_cutout();

module picam2_board(h=d){
    // a rounded rectangle with the dimensions of the picamera board v2
    // centred on the origin
    b = 24;
    w = 25;
    roc = 2;
    linear_extrude(h) hull(){
        reflect([1,0]) reflect([0,1]) translate([w/2-roc, b/2-roc]) circle(r=roc,$fn=12);
    }
}

module picamera_2_camera_mount(counterbore=false){
    // A mount for the pi camera v2
    // This should finish at z=0+d, with a surface that can be
    // hull-ed onto the lens assembly.
    b = 24;
    w = 25;
    difference(){
        rotate(45) translate([0,2.4,0]) sequential_hull(){
            translate([0,0,bottom]) picam2_board(h=d);
            translate([0,0,-1]) picam2_board(h=d);
            translate([0,0,0]) cube([w-(-1.5-bottom)*2,b,d],center=true);
        }
        rotate(45) translate([0,0,bottom]) picam2_cutout();
        if(counterbore){
            translate([0,0,bottom-1]) picamera_2_bottom_mounting_posts(height=999, radius=1, cutouts=false);
            translate([0,0,bottom+1])  picamera_2_bottom_mounting_posts(height=999, radius=2.7, cutouts=false);
        }
    }
}
difference(){
    picamera_2_camera_mount(counterbore=true);
    //rotate([90,0,0]) cylinder(r=999,h=999,$fn=4);
}

module picamera_2_bottom_mounting_posts(height=-1, radius=-1, outers=true, cutouts=true){
    // posts to mount to pi camera from below
    r = radius > 0 ? radius : 2;
    h = height > 0 ? height : 4;
    rotate(45)
    reflect([1,0,0]) for(y=[0,12.5]) translate([21/2, y, 0]) difference(){
        if(outers) cylinder(r=r, h=h, $fn=12);
        if(cutouts) intersection(){
            cylinder(h=13, d=2*1.7, center=true, $fn=3);
            rotate(60) cylinder(h=999, d=2*1.7*1.4, center=true, $fn=3);
        }
    }
}

/////////// Cover for camera board //////////////
module picamera_2_cover(){
    // A cover for the camera PCB, slips over the bottom of the camera
    // mount.  This version should be compatible with v1 and v2 of the board
    b = 24;
    w = 25;
    h = 3;
    t = 1; //wall thickness
    centre_y=2.4;
    difference(){
        union(){
            //bottom and sides
            difference(){
                translate([-w/2,-b/2+centre_y,0]) cube([w, b, h]);
                // cut out centre to form walls on 3 sides
                translate([-w/2+t,-b/2+centre_y-t,0.75]) cube([w-2*t, b, h]);
                //chamfer the connector edge for ease of access
                translate([-999,-b/2+centre_y,h]) rotate([-135,0,0]) cube([9999,999,999]);
            }
            //mounting screws
            reflect([1,0,0]) translate([21/2, 0, 0]) cylinder(r=3, h=h, $fn=16);
        }
        //counterbore the mounting screws
        reflect([1,0,0]) translate([21/2, 0, h-1]) rotate(90) intersection(){
           cylinder(r=2, h=999, $fn=16, center=true);
            hole_from_bottom(r=1.1, h=999, base_w=999);
        }
    }
} 
//picam_cover();

pcb = [25.4+0.5,24+0.5,2]; //size of the picam PCB (+0.5mm so it fits)
camera_housing = [9,9,2.5]; //size of the plastic housing
camera_housing_y = 2.5; //shift of the camera housing from the centre
lens_unscrew_r = 5.5/2; //size of the bit we unscrew
    
module generous_camera_bits(){
    //The other stuff on the PCB (mostly the ribbon cable)
    camera = [8.5,8.5,2.3]; //size of camera box
	cw = camera[0]+1; //side length of camera box at bottom (slightly larger)
	union(){
		//ribbon cable at top of camera
        sequential_hull(){
            translate([0,0,0]) cube([cw-1,d,4],center=true);
            translate([0,9.4-(4.4/1)/2,0]) cube([cw-1,1,4],center=true);
        }
        //flex connector
        translate([-1.25,9.4,0]) cube([cw-1+2.5, 4.4+1, 4],center=true);
        
	}
}

module picamera_2_gripper(){
    // this little bit of plastic grips the plastic camera housing
    // and allows you to safely unscrew the lens
    // it protects the (surprisingly delicate) flex that connects the camera to the PCB.
    outer = pcb+[4,-5,camera_housing[2]]; //size of the tool
    difference(){
        translate([0,-1,outer[2]/2]) cube(outer, center=true);
        
        //central hole for the camera housing
        translate([0,camera_housing_y,0]) cube(camera_housing + [0,0,999],center=true);
        
        //cut-outs for the other bits (cable etc.)
        translate([0,camera_housing_y,camera_housing[2]]) rotate([180,0,0]) generous_camera_bits();
        
        //indent for PCB
        translate([0,0,outer[2]]) cube(pcb + [0,0,pcb[2]],center=true);
    
    }
}

module picamera_2_lens_gripper(){
    //a tool to unscrew the lens from the pi camera
    inner_r = 4.7/2;
    union(){
        difference(){
            cylinder(r=7,h=2);
            cylinder(r=5,h=999,center=true);
        }
        for(a=[0,90,180,270]) rotate(a) translate([inner_r,0,0]) cube([1.5,5,2]);
    }
}