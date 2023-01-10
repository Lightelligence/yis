// Copyright (c) 2023 Lightelligence
//
// Description: SV Pkg generated from test_pkg_a.yis by YIS

`ifndef __TEST_PKG_A_RYPKG_SVH__
  `define __TEST_PKG_A_RYPKG_SVH__


package test_pkg_a_rypkg; // This is an example of what a package file could look like.

  
  localparam HERO_WIDTH = 32'd36; // Width of hero bus around the bag.
  
  // This field has extra verbose documentation surrounding it for
  // reasons that might be clear later. The intent of these different
  // fields is so that when a block interface uses a struct or enum in
  // an interface definition, we can copy over the doc_summary and
  // keep it inline, but for more information point to the package
  // definition for the whole long-form documentation.
  localparam [6 - 1:0] ANOTHER_PARAM = 6'd2; // This is a different parameter than the first.
  
  localparam [/* HERO_WIDTH.width */ 32 - 1:0] DOUBLE_LINK_PARAM = /* ANOTHER_PARAM.value */ 32'd2; // This parameter has a paramterized width and a parameterized type.
  
  localparam [/* DOUBLE_LINK_PARAM.value */ 2 - 1:0] TRIPLE_NESTED_PARAM = /* ANOTHER_PARAM.value */ 2'd2; // This parameter has a paramterized width and a parameterized type.
  
  localparam [32 - 1:0] TRIPLE_NESTED_PARAM_WIDTH = /* clog2(TRIPLE_NESTED_PARAM.value) */ 32'd1; // Width of TRIPLE_NESTED_PARAM
  
  localparam [32 - 1:0] TRIPLE_NESTED_PARAM_COUNT_WIDTH = /* clog2(TRIPLE_NESTED_PARAM.value + 1) */ 32'd2; // Width to count TRIPLE_NESTED_PARAM items
  
  localparam [/* clog2(TRIPLE_NESTED_PARAM.value) */ 1 - 1:0] TRIPLE_NESTED_PARAM_WIDTH_ONE = 1'd1; // TRIPLE_NESTED_PARAM_WIDTH-wide 1 for incrementers and decrementers
  
  localparam [32 - 1:0] DOUBLE_LINK_PARAM_WIDTH = /* clog2(DOUBLE_LINK_PARAM.value) */ 32'd1; // Width of DOUBLE_LINK_PARAM
  
  localparam [32 - 1:0] DOUBLE_LINK_PARAM_COUNT_WIDTH = /* clog2(DOUBLE_LINK_PARAM.value + 1) */ 32'd2; // Width to count DOUBLE_LINK_PARAM items
  
  localparam [/* clog2(DOUBLE_LINK_PARAM.value) */ 1 - 1:0] DOUBLE_LINK_PARAM_WIDTH_ONE = 1'd1; // DOUBLE_LINK_PARAM_WIDTH-wide 1 for incrementers and decrementers
  
  localparam [32 - 1:0] HERO_WIDTH_WIDTH = /* clog2(HERO_WIDTH.value) */ 32'd6; // Width of HERO_WIDTH
  
  localparam [32 - 1:0] HERO_WIDTH_COUNT_WIDTH = /* clog2(HERO_WIDTH.value + 1) */ 32'd6; // Width to count HERO_WIDTH items
  
  localparam [/* clog2(HERO_WIDTH.value) */ 6 - 1:0] HERO_WIDTH_WIDTH_ONE = 6'd1; // HERO_WIDTH_WIDTH-wide 1 for incrementers and decrementers
  
  localparam [32 - 1:0] ANOTHER_PARAM_WIDTH = /* clog2(ANOTHER_PARAM.value) */ 32'd1; // Width of ANOTHER_PARAM
  
  localparam [32 - 1:0] ANOTHER_PARAM_COUNT_WIDTH = /* clog2(ANOTHER_PARAM.value + 1) */ 32'd2; // Width to count ANOTHER_PARAM items
  
  localparam [/* clog2(ANOTHER_PARAM.value) */ 1 - 1:0] ANOTHER_PARAM_WIDTH_ONE = 1'd1; // ANOTHER_PARAM_WIDTH-wide 1 for incrementers and decrementers
  
  // I'm writing this verbose documentation so that we have something to
  // attempt to link in for cycle_type.
  typedef enum logic [/* TRIPLE_NESTED_PARAM.value */ 2 - 1:0] {
    IDLE, // The bus is idle this cycle.
    // The enum value is so complicated it needs its own verbose
    // documentation that none of the other values in this enum need.
    VALID, // The command on the bus this is valid and there will be future VALID cycles for this transaction.
    DONE // The command on the bus this is valid and this is the last cycle of data.
  } CYCLE_TYPE_E; // Indicates a command type of IDLE, VALID, or DONE.
  
  localparam [32 - 1:0] CYCLE_TYPE_E_WIDTH = /* CYCLE_TYPE_E.width */ 32'd2; // Width of CYCLE_TYPE_E
  
  typedef enum logic {
    BOOL_TRUE = 1'd1, // This is true
    BOOL_FALSE = 1'd0 // This is false
  } BOOL_E; // Test for an enum that is width 1
  
  localparam [32 - 1:0] BOOL_E_WIDTH = /* BOOL_E.width */ 32'd1; // Width of BOOL_E
  
  typedef enum logic [4 - 1:0] {
    CONCISE_SEQUENTIAL_THINGS0 = 4'd0, // ThingX
    CONCISE_SEQUENTIAL_THINGS2 = 4'd2, // ThingX
    CONCISE_SEQUENTIAL_THINGS4 = 4'd4, // ThingX
    CONCISE_SEQUENTIAL_THINGS6 = 4'd6, // ThingX
    CONCISE_SEQUENTIAL_THINGS8 = 4'd8, // ThingX
    CONCISE_BEE = 4'd3 // ThingX
  } CONCISE_E; // Write a lot of enums without much YIS
  
  localparam [32 - 1:0] CONCISE_E_WIDTH = /* CONCISE_E.width */ 32'd4; // Width of CONCISE_E
  
  typedef struct packed {
    logic subfield_a; // Test that a width-1 logic field generates correctly
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
    sub_def_t [/* 2 + 1 */ 3 - 1:0] another_type_reference; // Test a struct of a struct
    logic clk_en; // Clock enable for the bus
  } hero_write_t; // A struct that wraps all fields needed for a single hero write.
  
  localparam [32 - 1:0] HERO_WRITE_T_WIDTH = /* hero_write_t.width */ 32'd60; // Width of hero_write_t
  
  localparam [32 - 1:0] SUB_DEF_T_WIDTH = /* sub_def_t.width */ 32'd7; // Width of sub_def_t
  
  // And it has a doc_verbose for good measure
  typedef logic [/* ANOTHER_PARAM.value */ 2 - 1:0] vanilla_type_t; // This is a basic logic type and width
  
  localparam [32 - 1:0] VANILLA_TYPE_T_WIDTH = /* vanilla_type_t.width */ 32'd2; // Width of vanilla_type_t
  
  typedef vanilla_type_t [1 - 1:0] nested_type_t; // Use another typedef as the base type, a localparam as the width
  
  localparam [32 - 1:0] NESTED_TYPE_T_WIDTH = /* nested_type_t.width */ 32'd2; // Width of nested_type_t
  

endpackage : test_pkg_a_rypkg
`endif // guard