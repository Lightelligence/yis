// Copyright (c) 2020 Lightelligence
//
// Description: SV Pkg generated from test_pkg_a.yis by YIS

`ifndef __TEST_PKG_A_PKG_SVH__
  `define __TEST_PKG_A_PKG_SVH__

// This is now verbose documentation. It doesn't work yet.
package test_pkg_a; // This is an example of what a package file could look like.

  /////////////////////////////////////////////////////////////////////////////
  // localparams
  /////////////////////////////////////////////////////////////////////////////
  
  
  localparam [32 - 1:0] HERO_WIDTH = 36; // Width of hero bus around the bag.
  
  // This field has extra verbose documentation surrounding it for
  // reasons that might be clear later. The intent of these different
  // fields is so that when a block interface uses a struct or enum in
  // an interface definition, we can copy over the doc_summary and
  // keep it inline, but for more information point to the package
  // definition for the whole long-form documentation.
  localparam [6 - 1:0] ANOTHER_PARAM = 2; // This is a different parameter than the first.
  
  
  localparam [HERO_WIDTH - 1:0] THIRD_PARAM = 134; // This paramter has a paramterized width from the first param.
  
  /////////////////////////////////////////////////////////////////////////////
  // enums
  /////////////////////////////////////////////////////////////////////////////
  
  // I'm writing this verbose documentation so that we have something to
  // attempt to link in for cycle_type.
  type enum logic [4 - 1:0] {
    
    _E_IDLE, // The bus is idle this cycle.
    // The enum value is so complicated it needs its own verbose
    // documentation that none of the other values in this enum need.
    _E_VALID, // The command on the bus this is valid and there will be future VALID cycles for this transaction.
    
    _E_DONE, // The command on the bus this is valid and this is the last cycle of data
  } CYCLE_TYPE_E; // Indicates a command type of IDLE, VALID, or DONE.
  
  /////////////////////////////////////////////////////////////////////////////
  // structs
  /////////////////////////////////////////////////////////////////////////////
  
  
  typedef struct packed {
    // I'm writing this verbose documentation so that we have something to
    // attempt to link in for cycle_type.
    CYCLE_TYPE_E cycle_type; // Indicates a command type of IDLE, VALID, or DONE.
    
    logic [HERO_WIDTH - 1:0] wdat; // Width of hero bus around the bag.
    
    logic [1 - 1:0] clk_en; // Clock enable for the bus
  } hero_write_t; // A struct that wraps all fields needed for a single hero write.
  

endpackage : test_pkg_a
`endif // guard