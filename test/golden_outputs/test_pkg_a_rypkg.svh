// Copyright (c) 2020 Lightelligence
//
// Description: SV Pkg generated from test_pkg_a.yis by YIS

`ifndef __TEST_PKG_A_PKG_SVH__
  `define __TEST_PKG_A_PKG_SVH__


package test_pkg_a; // This is an example of what a package file could look like.

  
  localparam [32 - 1:0] HERO_WIDTH = 36; // Width of hero bus around the bag.
  
  // This field has extra verbose documentation surrounding it for
  // reasons that might be clear later. The intent of these different
  // fields is so that when a block interface uses a struct or enum in
  // an interface definition, we can copy over the doc_summary and
  // keep it inline, but for more information point to the package
  // definition for the whole long-form documentation.
  localparam [6 - 1:0] ANOTHER_PARAM = 2; // This is a different parameter than the first.
  
  localparam [/* HERO_WIDTH.width */ 32 - 1:0] DOUBLE_LINK_PARAM = /* ANOTHER_PARAM.value */ 2; // This parameter has a paramterized width and a parameterized type.
  
  localparam [/* DOUBLE_LINK_PARAM.value */ 2 - 1:0] TRIPLE_NESTED_PARAM = /* ANOTHER_PARAM.value */ 2; // This parameter has a paramterized width and a parameterized type.
  
  localparam [32 - 1:0] TRIPLE_NESTED_PARAM_WIDTH = 1; // Computed width of TRIPLE_NESTED_PARAM
  
  localparam [1 - 1:0] TRIPLE_NESTED_PARAM_WIDTH_ONE = 1; // TRIPLE_NESTED_PARAM_WIDTH-wide 1 for incrmeneters and decrementers of matching length operators
  
  localparam [32 - 1:0] DOUBLE_LINK_PARAM_WIDTH = 1; // Computed width of DOUBLE_LINK_PARAM
  
  localparam [1 - 1:0] DOUBLE_LINK_PARAM_WIDTH_ONE = 1; // DOUBLE_LINK_PARAM_WIDTH-wide 1 for incrmeneters and decrementers of matching length operators
  
  localparam [32 - 1:0] HERO_WIDTH_WIDTH = 6; // Computed width of HERO_WIDTH
  
  localparam [6 - 1:0] HERO_WIDTH_WIDTH_ONE = 1; // HERO_WIDTH_WIDTH-wide 1 for incrmeneters and decrementers of matching length operators
  
  localparam [32 - 1:0] ANOTHER_PARAM_WIDTH = 1; // Computed width of ANOTHER_PARAM
  
  localparam [1 - 1:0] ANOTHER_PARAM_WIDTH_ONE = 1; // ANOTHER_PARAM_WIDTH-wide 1 for incrmeneters and decrementers of matching length operators
  
  localparam [32 - 1:0] CYCLE_TYPE_E_WIDTH = 2; // Computed width of CYCLE_TYPE_E
  
  localparam [32 - 1:0] BOOL_E_WIDTH = 1; // Computed width of BOOL_E
  
  localparam [32 - 1:0] HERO_WRITE_T_WIDTH = 46; // Computed width of hero_write_t
  
  localparam [32 - 1:0] SUB_DEF_T_WIDTH = 7; // Computed width of sub_def_t
  
  localparam [32 - 1:0] VANILLA_TYPE_T_WIDTH = 6; // Computed width of vanilla_type_t
  
  localparam [32 - 1:0] NESTED_TYPE_T_WIDTH = 12; // Computed width of nested_type_t
  
  // I'm writing this verbose documentation so that we have something to
  // attempt to link in for cycle_type.
  typedef enum logic [/* TRIPLE_NESTED_PARAM.value */ 2 - 1:0] {
    CYCLE_TYPE_IDLE, // The bus is idle this cycle.
    // The enum value is so complicated it needs its own verbose
    // documentation that none of the other values in this enum need.
    CYCLE_TYPE_VALID, // The command on the bus this is valid and there will be future VALID cycles for this transaction.
    CYCLE_TYPE_DONE // The command on the bus this is valid and this is the last cycle of data.
  } CYCLE_TYPE_E; // Indicates a command type of IDLE, VALID, or DONE.
  
  typedef enum logic [1 - 1:0] {
    BOOL_TRUE = 1, // This is true
    BOOL_FALSE = 0 // This is false
  } BOOL_E; // Test for an enum that is width 1
  
  typedef struct packed {
    logic [1 - 1:0] subfield_a; // Test that a width-1 logic field generates correctly
    logic [/* ANOTHER_PARAM.value */ 2 - 1:0] subfield_b; // This is a different parameter than the first.
    logic [/* ANOTHER_PARAM.value */ 2 - 1:0] subfield_c; // This is a different parameter than the first.
    logic [/* ANOTHER_PARAM.value */ 2 - 1:0] subfield_d; // This is a different parameter than the first.
  } sub_def_t; // A sub-struct of hero_write_t that is declared afterwards.
  
  // This is a verbose doc. I'm writing it to provide that my verbose
  // doc links are working correctly.
  typedef struct packed {
    // I'm writing this verbose documentation so that we have something to
    // attempt to link in for cycle_type.
    CYCLE_TYPE_E cycle_type; // Indicates a command type of IDLE, VALID, or DONE.
    logic [/* HERO_WIDTH.value */ 36 - 1:0] wdat; // Width of hero bus around the bag.
    sub_def_t another_type_reference; // Test a struct of a struct
    logic [1 - 1:0] clk_en; // Clock enable for the bus
  } hero_write_t; // A struct that wraps all fields needed for a single hero write.
  
  // And it has a doc_verbose for good measure
  typedef logic [6 - 1:0] vanilla_type_t; // This is a basic logic type and width
  
  typedef vanilla_type_t [/* ANOTHER_PARAM.value */ 2 - 1:0] nested_type_t; // Use another typedef as the base type, a localparam as the width
  

endpackage : test_pkg_a
`endif // guard