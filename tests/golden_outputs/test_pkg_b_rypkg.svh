// Copyright (c) 2022 Lightelligence
//
// Description: SV Pkg generated from test_pkg_b.yis by YIS

`ifndef __TEST_PKG_B_RYPKG_SVH__
  `define __TEST_PKG_B_RYPKG_SVH__


package test_pkg_b_rypkg; // Example of what a dependent package looks like

  
  localparam [/* test_pkg_a::ANOTHER_PARAM.value */ 2 - 1:0] NEW_PARAM = 2'd3; // This should link up to [test_pkg_a::ANOTHER_PARAM]
  
  localparam [32 - 1:0] NEW_PARAM_WIDTH = /* clog2(NEW_PARAM.value) */ 32'd2; // Width of NEW_PARAM
  
  localparam [32 - 1:0] NEW_PARAM_COUNT_WIDTH = /* clog2(NEW_PARAM.value + 1) */ 32'd2; // Width to count NEW_PARAM items
  
  localparam [/* clog2(NEW_PARAM.value) */ 2 - 1:0] NEW_PARAM_WIDTH_ONE = 2'd1; // NEW_PARAM_WIDTH-wide 1 for incrementers and decrementers
  
  localparam [32 - 1:0] MAX_WR_CYCLES = 32'd4; // Maximum number of write cycles allowed for the pipelined write
  
  localparam [32 - 1:0] MAX_WR_CYCLES_WIDTH = /* clog2(MAX_WR_CYCLES.value) */ 32'd2; // Width of MAX_WR_CYCLES
  
  localparam [/* MAX_WR_CYCLES_WIDTH.value */ 2 - 1:0] MAX_WR_CYCLES_WIDTH_2 = 2'd2; // a 2 that is MAX_WR_CYCLES_WIDTH-wide (am implicit localparam generated by YIS)
  
  localparam [32 - 1:0] MAX_WR_CYCLES_WIDTH_2_WIDTH = /* clog2(MAX_WR_CYCLES_WIDTH_2.value) */ 32'd1; // Width of MAX_WR_CYCLES_WIDTH_2
  
  localparam [32 - 1:0] MAX_WR_CYCLES_WIDTH_2_COUNT_WIDTH = /* clog2(MAX_WR_CYCLES_WIDTH_2.value + 1) */ 32'd2; // Width to count MAX_WR_CYCLES_WIDTH_2 items
  
  localparam [/* clog2(MAX_WR_CYCLES_WIDTH_2.value) */ 1 - 1:0] MAX_WR_CYCLES_WIDTH_2_WIDTH_ONE = 1'd1; // MAX_WR_CYCLES_WIDTH_2_WIDTH-wide 1 for incrementers and decrementers
  
  localparam [32 - 1:0] MAX_WR_CYCLES_COUNT_WIDTH = /* clog2(MAX_WR_CYCLES.value + 1) */ 32'd3; // Width to count MAX_WR_CYCLES items
  
  localparam [/* clog2(MAX_WR_CYCLES.value) */ 2 - 1:0] MAX_WR_CYCLES_WIDTH_ONE = 2'd1; // MAX_WR_CYCLES_WIDTH-wide 1 for incrementers and decrementers
  
  localparam [32 - 1:0] WR_WIDTH = 32'd8; // Width of a single write cycle
  
  localparam [32 - 1:0] WR_WIDTH_WIDTH = /* clog2(WR_WIDTH.value) */ 32'd3; // Width of WR_WIDTH
  
  localparam [32 - 1:0] WR_WIDTH_COUNT_WIDTH = /* clog2(WR_WIDTH.value + 1) */ 32'd4; // Width to count WR_WIDTH items
  
  localparam [/* clog2(WR_WIDTH.value) */ 3 - 1:0] WR_WIDTH_WIDTH_ONE = 3'd1; // WR_WIDTH_WIDTH-wide 1 for incrementers and decrementers
  
  // Used to verify logic fields of width 1 in a a struct via an
  // equation.
  localparam [32 - 1:0] THIS_IS_ONE = 32'd1; // A localparam value of 1
  
  localparam [32 - 1:0] THIS_IS_ONE_WIDTH = /* clog2(THIS_IS_ONE.value) */ 32'd0; // Width of THIS_IS_ONE
  
  localparam [32 - 1:0] THIS_IS_ONE_COUNT_WIDTH = /* clog2(THIS_IS_ONE.value + 1) */ 32'd1; // Width to count THIS_IS_ONE items
  
  // Width would be 0 because clog2(1)=0. Forcing to 1.
  localparam [/* clog2(THIS_IS_ONE.value) */ 1 - 1:0] THIS_IS_ONE_WIDTH_ONE = 1'd1; // THIS_IS_ONE_WIDTH-wide 1 for incrementers and decrementers
  
  typedef enum logic [3 - 1:0] {
    WRITE_TYPE_STD, // Standard write, nothing special
    WRITE_TYPE_MULTI_WDONE, // Send a wdone for each individual cycle completing
    WRITE_TYPE_SINGLE_WDONE // Send a wdone only for the entire write xaction
  } WRITE_TYPE_E; // Specifies how the write should be handled
  
  localparam [32 - 1:0] WRITE_TYPE_E_WIDTH = /* WRITE_TYPE_E.width */ 32'd3; // Width of WRITE_TYPE_E
  
  typedef struct packed {
    logic [/* test_pkg_a::HERO_WIDTH.value */ 36 - 1:0] fielda; // Width of hero bus around the bag.
    test_pkg_a_rypkg::hero_write_t fieldb; // A struct that wraps all fields needed for a single hero write.
    test_pkg_a_rypkg::CYCLE_TYPE_E fieldc; // Indicates a command type of IDLE, VALID, or DONE.
    logic [/* NEW_PARAM.value */ 3 - 1:0] fieldd; // This summary is different than its base definition
  } several_things_t; // Testing inter-package dependencies within struct fields.
  
  localparam [32 - 1:0] SEVERAL_THINGS_T_WIDTH = /* several_things_t.width */ 32'd87; // Width of several_things_t
  
  typedef test_pkg_a_rypkg::CYCLE_TYPE_E [/* NEW_PARAM.value */ 3 - 1:0] first_defined_type_t; // Use another package's enum as the type and a local localparam as width
  
  // This verbose doc is several lines in order to demonstrate  that we
  // can have a multi-line verbose doc that can be linked through
  typedef test_pkg_a_rypkg::hero_write_t [/* test_pkg_a::DOUBLE_LINK_PARAM.value */ 2 - 1:0] second_defined_type_t; // Use another package's struct as the type and another packages's localparam as width
  
  typedef struct packed {
    first_defined_type_t first_field; // Use another package's enum as the type and a local localparam as width
    // This verbose doc is several lines in order to demonstrate  that we
    // can have a multi-line verbose doc that can be linked through
    second_defined_type_t second_field; // Use another package's struct as the type and another packages's localparam as width
    // This also a custom verbose doc
    test_pkg_a_rypkg::CYCLE_TYPE_E third_field; // This is a custom doc summary, not inherited from the type
  } type_links_t; // Link in a local typedef, a scoped typdef, and a scoped enum
  
  localparam [32 - 1:0] TYPE_LINKS_T_WIDTH = /* type_links_t.width */ 32'd100; // Width of type_links_t
  
  typedef struct packed {
    logic vld; // This cmd is valid, this is the start of a new pipelined write
    logic [/* test_pkg_a::CYCLE_TYPE_E.width + 2 */ 4 - 1:0] rsvd; // Reserved
    logic [/* clog2(MAX_WR_CYCLES.value - 1) */ 2 - 1:0] num_cycles; // Number of cycles for this write. 0 indicates MAX_WRITE_CYCLES, otherwise indicates the regular value
    WRITE_TYPE_E write_type; // Specifies how the write should be handled
  } write_cmd_t; // The command cycle of a pipelined write
  
  localparam [32 - 1:0] WRITE_CMD_T_WIDTH = /* write_cmd_t.width */ 32'd10; // Width of write_cmd_t
  
  typedef struct packed {
    test_pkg_a_rypkg::CYCLE_TYPE_E cycle_type; // Indicates a command type of IDLE, VALID, or DONE.
    logic [/* WR_WIDTH.value */ 8 - 1:0] dat; // One data cycle
  } write_dat_t; // Data cycle of a pipelined write
  
  localparam [32 - 1:0] WRITE_DAT_T_WIDTH = /* write_dat_t.width */ 32'd10; // Width of write_dat_t
  
  typedef struct packed {
    logic vld; // This field should be rendered as bare logic without anything else
    logic /* (2 * THIS_IS_ONE.value) - THIS_IS_ONE.value */ new_bit_field; // This field should be rendered to just a bare logic with the equation in comments
    logic /* THIS_IS_ONE.value */ simple_bit_field; // This field should be rendered to just a bare logic with the equation in comments
  } one_bit_field_t; // Struct to hold 1-bit bit fields to make sure the 1-bit rendering is correct
  
  localparam [32 - 1:0] ONE_BIT_FIELD_T_WIDTH = /* one_bit_field_t.width */ 32'd3; // Width of one_bit_field_t
  
  localparam [32 - 1:0] FIRST_DEFINED_TYPE_T_WIDTH = /* first_defined_type_t.width */ 32'd6; // Width of first_defined_type_t
  
  localparam [32 - 1:0] SECOND_DEFINED_TYPE_T_WIDTH = /* second_defined_type_t.width */ 32'd92; // Width of second_defined_type_t
  
  typedef several_things_t [2 - 1:0] local_item_type_t; // Use this package's struct as the type and an int for a width
  
  localparam [32 - 1:0] LOCAL_ITEM_TYPE_T_WIDTH = /* local_item_type_t.width */ 32'd174; // Width of local_item_type_t
  
  typedef logic [/* MAX_WR_CYCLES_WIDTH.value */ 2 - 1:0] type_from_implicit_param_t; // Use an auto-generated localparam in the definition of another YIS type
  
  localparam [32 - 1:0] TYPE_FROM_IMPLICIT_PARAM_T_WIDTH = /* type_from_implicit_param_t.width */ 32'd2; // Width of type_from_implicit_param_t
  
  typedef logic width_one_typedef_t; // A logic typedef width of 1
  
  localparam [32 - 1:0] WIDTH_ONE_TYPEDEF_T_WIDTH = /* width_one_typedef_t.width */ 32'd1; // Width of width_one_typedef_t
  
  typedef logic /* THIS_IS_ONE.value + THIS_IS_ONE.value - THIS_IS_ONE.value */ width_one_eqn_typedef_t; // A logic typedef width of 1 from an equation
  
  localparam [32 - 1:0] WIDTH_ONE_EQN_TYPEDEF_T_WIDTH = /* width_one_eqn_typedef_t.width */ 32'd1; // Width of width_one_eqn_typedef_t
  
  typedef struct packed {
    write_cmd_t cmd_cycle; // The command cycle of a pipelined write
    write_dat_t dat0; // Data cycle of a pipelined write
    write_dat_t dat1; // Data cycle of a pipelined write
    write_dat_t dat2; // Data cycle of a pipelined write
    write_dat_t dat3; // Data cycle of a pipelined write
  } pipelined_write_t; // Defines a pipelined write transaction
  

endpackage : test_pkg_b_rypkg
`endif // guard