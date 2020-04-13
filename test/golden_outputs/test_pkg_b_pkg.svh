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
  
  typedef test_pkg_a::CYCLE_TYPE_E [NEW_PARAM - 1:0] first_defined_type_t // Use another package's enum as the type and a local localparam as width
  
  // This verbose doc is several lines in order to demonstrate  that we
  // can have a multi-line verbose doc that can be linked through
  typedef test_pkg_a::hero_write_t [test_pkg_a::DOUBLE_LINK_PARAM - 1:0] second_defined_type_t // Use another package's struct as the type and another packages's localparam as width
  
  typedef several_things_t [2 - 1:0] local_item_type_t // Use this package's struct as the type and an int for a width
  
  /////////////////////////////////////////////////////////////////////////////
  // structs
  /////////////////////////////////////////////////////////////////////////////
  
  typedef struct packed {
    logic [test_pkg_a::HERO_WIDTH - 1:0] fielda; // Width of hero bus around the bag.
    test_pkg_a::hero_write_t fieldb; // A struct that wraps all fields needed for a single hero write.
    test_pkg_a::CYCLE_TYPE_E fieldc; // Indicates a command type of IDLE, VALID, or DONE.
    logic [NEW_PARAM - 1:0] fieldd; // This summary is different than its base definition
  } several_things_t; // Testing inter-package dependencies within struct fields.
  
  typedef struct packed {
    first_defined_type_t first_field; // Use another package's enum as the type and a local localparam as width
    // This verbose doc is several lines in order to demonstrate  that we
    // can have a multi-line verbose doc that can be linked through
    second_defined_type_t second_field; // Use another package's struct as the type and another packages's localparam as width
    // This also a custom verbose doc
    test_pkg_a::CYCLE_TYPE_E third_field; // This is a custom doc summary, not inherited from the type
  } type_links_t; // Link in a local typedef, a scoped typdef, and a scoped enum
  

endpackage : test_pkg_b
`endif // guard