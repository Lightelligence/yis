// Copyright (c) 2020 Lightelligence
//
// Description: SV Pkg generated from test_pkg_b.yis by YIS

`ifndef __TEST_PKG_B_PKG_SVH__
  `define __TEST_PKG_B_PKG_SVH__


package test_pkg_b; // Example of what a dependent package looks like

  
  localparam [/* test_pkg_a::ANOTHER_PARAM.value */ 2 - 1:0] NEW_PARAM = 3; // This should link up to [test_pkg_a::ANOTHER_PARAM]
  
  localparam [32 - 1:0] MAX_WR_CYCLES = 4; // Maximum number of write cycles allowed for the pipelined write
  
  localparam [32 - 1:0] WR_WIDTH = 8; // Width of a single write cycle
  
  localparam [32 - 1:0] NEW_PARAM_WIDTH = 2; // Computed width of NEW_PARAM
  
  localparam [32 - 1:0] NEW_PARAM_COUNT_WIDTH = 2; // Computed count_width of NEW_PARAM
  
  localparam [2 - 1:0] NEW_PARAM_WIDTH_ONE = 1; // NEW_PARAM_WIDTH-wide 1 for incrmeneters and decrementers of matching length operators
  
  localparam [32 - 1:0] MAX_WR_CYCLES_WIDTH = 2; // Computed width of MAX_WR_CYCLES
  
  localparam [32 - 1:0] MAX_WR_CYCLES_COUNT_WIDTH = 3; // Computed count_width of MAX_WR_CYCLES
  
  localparam [2 - 1:0] MAX_WR_CYCLES_WIDTH_ONE = 1; // MAX_WR_CYCLES_WIDTH-wide 1 for incrmeneters and decrementers of matching length operators
  
  localparam [32 - 1:0] WR_WIDTH_WIDTH = 3; // Computed width of WR_WIDTH
  
  localparam [32 - 1:0] WR_WIDTH_COUNT_WIDTH = 4; // Computed count_width of WR_WIDTH
  
  localparam [3 - 1:0] WR_WIDTH_WIDTH_ONE = 1; // WR_WIDTH_WIDTH-wide 1 for incrmeneters and decrementers of matching length operators
  
  localparam [32 - 1:0] WRITE_TYPE_E_WIDTH = 3; // Computed width of WRITE_TYPE_E
  
  localparam [32 - 1:0] PIPELINED_WRITE_T_WIDTH = 50; // Computed width of pipelined_write_t
  
  localparam [32 - 1:0] SEVERAL_THINGS_T_WIDTH = 87; // Computed width of several_things_t
  
  localparam [32 - 1:0] TYPE_LINKS_T_WIDTH = 100; // Computed width of type_links_t
  
  localparam [32 - 1:0] WRITE_CMD_T_WIDTH = 10; // Computed width of write_cmd_t
  
  localparam [32 - 1:0] WRITE_DATA_T_WIDTH = 10; // Computed width of write_data_t
  
  localparam [32 - 1:0] FITAX_DEFINED_TYPE_T_WIDTH = 6; // Computed width of first_defined_type_t
  
  localparam [32 - 1:0] SECOND_DEFINED_TYPE_T_WIDTH = 92; // Computed width of second_defined_type_t
  
  localparam [32 - 1:0] LOCAL_ITEM_TYPE_T_WIDTH = 174; // Computed width of local_item_type_t
  
  typedef enum logic [3 - 1:0] {
    WRITE_TYPE_STD, // Standard write, nothing special
    WRITE_TYPE_MULTI_WDONE, // Send a wdone for each individual cycle completing
    WRITE_TYPE_SINGLE_WDONE // Send a wdone only for the entire write xaction
  } WRITE_TYPE_E; // Specifies how the write should be handled
  
  typedef struct packed {
    logic [1 - 1:0] vld; // This cmd is valid, this is the start of a new pipelined write
    logic [/* test_pkg_a::CYCLE_TYPE_E.width + 2 */ 4 - 1:0] rsvd; // Reserved
    logic [/* clog2(MAX_WR_CYCLES.value - 1) */ 2 - 1:0] num_cycles; // Number of cycles for this write. 0 indicates MAX_WRITE_CYCLES, otherwise indicates the regular value
    WRITE_TYPE_E write_type; // Specifies how the write should be handled
  } write_cmd_t; // The command cycle of a pipelined write
  
  typedef struct packed {
    test_pkg_a_rypkg::CYCLE_TYPE_E cycle_type; // Indicates a command type of IDLE, VALID, or DONE.
    logic [/* WR_WIDTH.value */ 8 - 1:0] dat; // One data cycle
  } write_data_t; // Data cycle of a pipelined write
  
  typedef struct packed {
    write_cmd_t cmd_cycle; // The command cycle of a pipelined write
    write_data_t dat0; // Data cycle of a pipelined write
    write_data_t dat1; // Data cycle of a pipelined write
    write_data_t dat2; // Data cycle of a pipelined write
    write_data_t dat3; // Data cycle of a pipelined write
  } pipelined_write_t; // Defines a pipelined write transaction
  
  typedef struct packed {
    logic [/* test_pkg_a::HERO_WIDTH.value */ 36 - 1:0] fielda; // Width of hero bus around the bag.
    test_pkg_a_rypkg::hero_write_t fieldb; // A struct that wraps all fields needed for a single hero write.
    test_pkg_a_rypkg::CYCLE_TYPE_E fieldc; // Indicates a command type of IDLE, VALID, or DONE.
    logic [/* NEW_PARAM.value */ 3 - 1:0] fieldd; // This summary is different than its base definition
  } several_things_t; // Testing inter-package dependencies within struct fields.
  
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
  
  typedef several_things_t [2 - 1:0] local_item_type_t; // Use this package's struct as the type and an int for a width
  

endpackage : test_pkg_b_rypkg
`endif // guard