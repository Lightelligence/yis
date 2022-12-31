
// Autogenerated from tests/golden_inputs/test_pkg_a.yis by yis (https://github.com/Lightelligence/yis)
//
// Do Not Edit
//
#ifndef __TEST_PKG_A_YIS_H__
#define __TEST_PKG_A_YIS_H__

#include <stdint.h>


#define TRIPLE_NESTED_PARAM 2           // This parameter has a paramterized width and a parameterized type.
#define TRIPLE_NESTED_PARAM_WIDTH 1           // Width of TRIPLE_NESTED_PARAM
#define TRIPLE_NESTED_PARAM_COUNT_WIDTH 2           // Width to count TRIPLE_NESTED_PARAM items
#define TRIPLE_NESTED_PARAM_WIDTH_ONE 1           // TRIPLE_NESTED_PARAM_WIDTH-wide 1 for incrementers and decrementers
#define DOUBLE_LINK_PARAM 2           // This parameter has a paramterized width and a parameterized type.
#define DOUBLE_LINK_PARAM_WIDTH 1           // Width of DOUBLE_LINK_PARAM
#define DOUBLE_LINK_PARAM_COUNT_WIDTH 2           // Width to count DOUBLE_LINK_PARAM items
#define DOUBLE_LINK_PARAM_WIDTH_ONE 1           // DOUBLE_LINK_PARAM_WIDTH-wide 1 for incrementers and decrementers
#define HERO_WIDTH 36           // Width of hero bus around the bag.
#define HERO_WIDTH_WIDTH 6           // Width of HERO_WIDTH
#define HERO_WIDTH_COUNT_WIDTH 6           // Width to count HERO_WIDTH items
#define HERO_WIDTH_WIDTH_ONE 1           // HERO_WIDTH_WIDTH-wide 1 for incrementers and decrementers
#define ANOTHER_PARAM 2           // This is a different parameter than the first.
#define ANOTHER_PARAM_WIDTH 1           // Width of ANOTHER_PARAM
#define ANOTHER_PARAM_COUNT_WIDTH 2           // Width to count ANOTHER_PARAM items
#define ANOTHER_PARAM_WIDTH_ONE 1           // ANOTHER_PARAM_WIDTH-wide 1 for incrementers and decrementers
#define CYCLE_TYPE_E_WIDTH 2           // Width of CYCLE_TYPE_E
#define BOOL_E_WIDTH 1           // Width of BOOL_E
#define CONCISE_E_WIDTH 4           // Width of CONCISE_E
#define HERO_WRITE_T_WIDTH 60           // Width of hero_write_t
#define SUB_DEF_T_WIDTH 7           // Width of sub_def_t
#define VANILLA_TYPE_T_WIDTH 2           // Width of vanilla_type_t
#define NESTED_TYPE_T_WIDTH 2           // Width of nested_type_t


// Indicates a command type of IDLE, VALID, or DONE.
typedef enum {
    IDLE,                    // The bus is idle this cycle.
    VALID,                    // The command on the bus this is valid and there will be future VALID cycles for this transaction.
    DONE,                    // The command on the bus this is valid and this is the last cycle of data.
} CYCLE_TYPE_E;

// Test for an enum that is width 1
typedef enum {
    TRUE = 1,   // This is true
    FALSE = 0,   // This is false
} BOOL_E;

// Write a lot of enums without much YIS
typedef enum {
    SEQUENTIAL_THINGS0 = 0,   // ThingX
    SEQUENTIAL_THINGS2 = 2,   // ThingX
    SEQUENTIAL_THINGS4 = 4,   // ThingX
    SEQUENTIAL_THINGS6 = 6,   // ThingX
    SEQUENTIAL_THINGS8 = 8,   // ThingX
    BEE = 3,   // ThingX
} CONCISE_E;


// This is a basic logic type and width
typedef uint8_t vanilla_type_t;    // 2 bits wide

// Use another typedef as the base type, a localparam as the width
typedef uint8_t nested_type_t;    // 2 bits wide


// A sub-struct of hero_write_t that is declared afterwards.
typedef struct _sub_def_t {
    uint8_t subfield_a;    // 1 bits : Test that a width-1 logic field generates correctly
    uint8_t subfield_b;    // 2 bits : This is a different parameter than the first.
    uint8_t subfield_c;    // 2 bits : This is a different parameter than the first.
    uint8_t subfield_d;    // 2 bits : This is a different parameter than the first.
} sub_def_t;

// A struct that wraps all fields needed for a single hero write.
typedef struct _hero_write_t {
    CYCLE_TYPE_E cycle_type;    // 2 bits : Indicates a command type of IDLE, VALID, or DONE.
    uint64_t wdat;    // 36 bits : Width of hero bus around the bag.
    sub_def_t another_type_reference;    // 21 bits : Test a struct of a struct
    uint8_t clk_en;    // 1 bits : Clock enable for the bus
} hero_write_t;



#endif // __TEST_PKG_A_YIS_H__