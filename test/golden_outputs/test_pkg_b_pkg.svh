// Copyright (c) 2020 Lightelligence
//
// Description: SV Pkg generated from test_pkg_b.yis by YIS

`ifndef __TEST_PKG_B_PKG_SVH__
  `define __TEST_PKG_B_PKG_SVH__


package test_pkg_b; // Example of what a dependent package looks like

  /////////////////////////////////////////////////////////////////////////////
  // localparams
  /////////////////////////////////////////////////////////////////////////////
  
  localparam [test_pkg_a::ANOTHER_PARAM - 1:0] NEW_PARAM = 5; // This should link up
  
  /////////////////////////////////////////////////////////////////////////////
  // enums
  /////////////////////////////////////////////////////////////////////////////
  
  /////////////////////////////////////////////////////////////////////////////
  // structs
  /////////////////////////////////////////////////////////////////////////////
  
  typedef struct packed {
    logic [test_pkg_a::HERO_WIDTH - 1:0] fielda; // Width of hero bus around the bag.
    test_pkg_a::hero_write_t fieldb; // type.doc_sumary
    test_pkg_a::CYCLE_TYPE_E fieldc; // Indicates a command type of IDLE, VALID, or DONE.
    logic [NEW_PARAM - 1:0] fieldd; // This summary is different than its base definition
  } another_struct_t; // Testing inter-package dependencies within struct fields.
  

endpackage : test_pkg_b
`endif // guard