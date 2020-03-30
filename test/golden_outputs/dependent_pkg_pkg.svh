// Copyright (c) 2020 Lightelligence
//
// Description: SV Package generated from dependent_pkg.yis by YIS

`ifndef __DEPENDENT_PKG_SVH__
  `define __DEPENDENT_PKG_SVH__

package dependent_pkg;

  // localparams
  
  localparam [hero::ANOTHER_PARAM - 1:0] NEW_PARAM = 5; // This should link up
  
  // enums
  
  // structs
  
  typedef struct packed {
    logic [hero::HERO_WIDTH - 1:0] fielda; // Width of hero bus around the bag.
    hero::hero_write fieldb; // A struct that wraps all fields needed for a single hero write.
    hero::CYCLE_TYPE fieldc; // Indicates a command type of IDLE, VALID, or DONE.
    logic [NEW_PARAM - 1:0] fieldd; // This summary is different than its base definition
  } another_struct; // Testing inter-package dependencies within struct fields.
  

endpackage : dependent_pkg
`endif