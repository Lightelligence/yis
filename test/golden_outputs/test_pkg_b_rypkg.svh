// Copyright (c) 2020 Lightelligence
//
// Description: SV Pkg generated from test_pkg_b.yis by YIS

`ifndef __TEST_PKG_B_PKG_SVH__
  `define __TEST_PKG_B_PKG_SVH__


package test_pkg_b; // Example of what a dependent package looks like

  
  localparam [/* test_pkg_a::ANOTHER_PARAM.value */ 2 - 1:0] NEW_PARAM = 3; // This should link up to [test_pkg_a::ANOTHER_PARAM]
  
  localparam [32 - 1:0] MAX_WR_CYCLES = 4; // Maximum number of write cycles allowed for the pipelined write
  
  localparam [32 - 1:0] WR_WIDTH = 8; // Width of a single write cycle
  
  typedef enum logic [3 - 1:0] {
    WRITE_TYPE_STD, // Standard write, nothing special
    WRITE_TYPE_MULTI_WDONE, // Send a wdone for each individual cycle completing
    WRITE_TYPE_SINGLE_WDONE // Send a wdone only for the entire write xaction
  } WRITE_TYPE__ET; // Specifies how the write should be handled
  
  typedef struct packed {
    logic [/* test_pkg_a::CYCLE_TYPE__ET.width + 2 */ 4 - 1:0] rsvd; // Reserved
    logic [1 - 1:0] val; // This cmd is valid, this is the start of a new pipelined write
    logic [/* bits(MAX_WR_CYCLES.value - 1) */ 2 - 1:0] num_cycles; // Number of cycles for this write. 0 indicates MAX_WRITE_CYCLES, otherwise indicates the regular value
    WRITE_TYPE__ET write_type__e; // Specifies how the write should be handled
  } write_cmd__st; // The command cycle of a pipelined write
  
  typedef struct packed {
    test_pkg_a_rypkg::CYCLE_TYPE__ET cycle_type__e; // Indicates a command type of IDLE, VALID, or DONE.
    logic [/* WR_WIDTH.value */ 8 - 1:0] dat; // One data cycle
  } write_dat__st; // Data cycle of a pipelined write
  
  typedef struct packed {
    write_cmd__st cmd_cycle__s; // The command cycle of a pipelined write
    write_dat__st dat0__s; // Data cycle of a pipelined write
    write_dat__st dat1__s; // Data cycle of a pipelined write
    write_dat__st dat2__s; // Data cycle of a pipelined write
    write_dat__st dat3__s; // Data cycle of a pipelined write
  } pipelined_write__st; // Defines a pipelined write transaction
  
  typedef struct packed {
    logic [/* test_pkg_a::HERO_WIDTH.value */ 36 - 1:0] fielda; // Width of hero bus around the bag.
    test_pkg_a_rypkg::hero_write__st fieldb__s; // A struct that wraps all fields needed for a single hero write.
    test_pkg_a_rypkg::CYCLE_TYPE__ET fieldc__e; // Indicates a command type of IDLE, VALID, or DONE.
    logic [/* NEW_PARAM.value */ 3 - 1:0] fieldd; // This summary is different than its base definition
  } several_things__st; // Testing inter-package dependencies within struct fields.
  
  typedef test_pkg_a_rypkg::CYCLE_TYPE__ET [/* NEW_PARAM.value */ 3 - 1:0] first_defined_type__t; // Use another package's enum as the type and a local localparam as width
  
  // This verbose doc is several lines in order to demonstrate  that we
  // can have a multi-line verbose doc that can be linked through
  typedef test_pkg_a_rypkg::hero_write__st [/* test_pkg_a::DOUBLE_LINK_PARAM.value */ 2 - 1:0] second_defined_type__t; // Use another package's struct as the type and another packages's localparam as width
  
  typedef struct packed {
    first_defined_type__t first_field; // Use another package's enum as the type and a local localparam as width
    // This verbose doc is several lines in order to demonstrate  that we
    // can have a multi-line verbose doc that can be linked through
    second_defined_type__t second_field; // Use another package's struct as the type and another packages's localparam as width
    // This also a custom verbose doc
    test_pkg_a_rypkg::CYCLE_TYPE__ET third_field__e; // This is a custom doc summary, not inherited from the type
  } type_links__st; // Link in a local typedef, a scoped typdef, and a scoped enum
  
  typedef several_things__st [2 - 1:0] local_item_type__t; // Use this package's struct as the type and an int for a width
  

endpackage : test_pkg_b
`endif // guard
