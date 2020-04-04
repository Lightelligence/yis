// Copyright (c) 2020 Lightelligence
//
// Description: SV Pkg generated from test_pkg_a.yis by YIS

`ifndef __TEST_PKG_A_PKG_SVH__
  `define __TEST_PKG_A_PKG_SVH__


package test_pkg_a; // This is an example of what a package file could look like.

  /////////////////////////////////////////////////////////////////////////////
  // localparams
  /////////////////////////////////////////////////////////////////////////////
  
  localparam [DOUBLE_LINK_PARAM - 1:0] TRIPLE_NESTED_PARAM = ANOTHER_PARAM; // This paramter has a paramterized width and a parameterized type.
  
  localparam [HERO_WIDTH - 1:0] DOUBLE_LINK_PARAM = ANOTHER_PARAM; // This paramter has a paramterized width and a parameterized type.
  
  localparam [32 - 1:0] HERO_WIDTH = 36; // Width of hero bus around the bag.
  
  // This field has extra verbose documentation surrounding it for
  // reasons that might be clear later. The intent of these different
  // fields is so that when a block interface uses a struct or enum in
  // an interface definition, we can copy over the doc_summary and
  // keep it inline, but for more information point to the package
  // definition for the whole long-form documentation.
  localparam [6 - 1:0] ANOTHER_PARAM = 2; // This is a different parameter than the first.
  
  /////////////////////////////////////////////////////////////////////////////
  // enums
  /////////////////////////////////////////////////////////////////////////////
  
  // I'm writing this verbose documentation so that we have something to
  // attempt to link in for cycle_type.
  type enum logic [TRIPLE_NESTED_PARAM - 1:0] {
    CYCLE_TYPE_IDLE, // The bus is idle this cycle.
    // The enum value is so complicated it needs its own verbose
    // documentation that none of the other values in this enum need.
    CYCLE_TYPE_VALID, // The command on the bus this is valid and there will be future VALID cycles for this transaction.
    CYCLE_TYPE_DONE, // The command on the bus this is valid and this is the last cycle of data
  } CYCLE_TYPE_E; // Indicates a command type of IDLE, VALID, or DONE.
  
  /////////////////////////////////////////////////////////////////////////////
  // structs
  /////////////////////////////////////////////////////////////////////////////
  
  // This is a verbose doc. I'm writing it to provide that my verbose
  // doc links are working correctly.
  typedef struct packed {
    // I'm writing this verbose documentation so that we have something to
    // attempt to link in for cycle_type.
    CYCLE_TYPE_E cycle_type; // Indicates a command type of IDLE, VALID, or DONE.
    logic [HERO_WIDTH - 1:0] wdat; // Width of hero bus around the bag.
    sub_struct_t struct_reference; // Test a struct of a struct
    logic [1 - 1:0] clk_en; // Clock enable for the bus
  } hero_write_t; // A struct that wraps all fields needed for a single hero write.
  
  typedef struct packed {
    wire [ANOTHER_PARAM - 1:0] subfield_a; // This is a different parameter than the first.
    wire [ANOTHER_PARAM - 1:0] subfield_b; // This is a different parameter than the first.
    wire [ANOTHER_PARAM - 1:0] subfield_c; // This is a different parameter than the first.
    wire [ANOTHER_PARAM - 1:0] subfield_d; // This is a different parameter than the first.
  } sub_struct_t; // A sub-struct of hero_write_t that is declared afterwards.
  

endpackage : test_pkg_a
`endif // guard