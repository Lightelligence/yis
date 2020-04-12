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
  // typedefs
  /////////////////////////////////////////////////////////////////////////////
  
  typedef test_pkg_a::CYCLE_TYPE_E [NEW_PARAM - 1:0] enum_based_typedef_t // Use another package's enum as the type and a local localparam as width
  
  typedef test_pkg_a::hero_write_t [test_pkg_a::DOUBLE_LINK_PARAM - 1:0] struct_based_typedef_t // Use another package's struct as the type and another packages's localparam as width
  
  typedef another_struct_t [2 - 1:0] local_struct_typedef_t // Use this package's struct as the type and an int for a width
  
  /////////////////////////////////////////////////////////////////////////////
  // structs
  /////////////////////////////////////////////////////////////////////////////
  
  typedef struct packed {
    logic [test_pkg_a::HERO_WIDTH - 1:0] fielda; // Width of hero bus around the bag.
    test_pkg_a::hero_write_t fieldb; // A struct that wraps all fields needed for a single hero write.
    test_pkg_a::CYCLE_TYPE_E fieldc; // Indicates a command type of IDLE, VALID, or DONE.
    logic [NEW_PARAM - 1:0] fieldd; // This summary is different than its base definition
  } another_struct_t; // Testing inter-package dependencies within struct fields.
  

endpackage : test_pkg_b
`endif // guard