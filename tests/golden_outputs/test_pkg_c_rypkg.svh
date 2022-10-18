// Copyright (c) 2022 Lightelligence
//
// Description: SV Pkg generated from test_pkg_c.yis by YIS

`ifndef __TEST_PKG_C_RYPKG_SVH__
  `define __TEST_PKG_C_RYPKG_SVH__


package test_pkg_c_rypkg; // Define the addressing schema

  
  // This is an assumption that we will have 40 bits of addressing over
  // PCIE. Even if not using PCIE, this might be a good assumption to
  // make for future proofing.
  localparam [32 - 1:0] ADDR_WIDTH = 32'd27; // The default address width
  
  localparam [32 - 1:0] ADDR_WIDTH_WIDTH = /* clog2(ADDR_WIDTH.value) */ 32'd5; // Width of ADDR_WIDTH
  
  localparam [32 - 1:0] ADDR_WIDTH_COUNT_WIDTH = /* clog2(ADDR_WIDTH.value + 1) */ 32'd5; // Width to count ADDR_WIDTH items
  
  localparam [/* clog2(ADDR_WIDTH.value) */ 5 - 1:0] ADDR_WIDTH_WIDTH_ONE = 5'd1; // ADDR_WIDTH_WIDTH-wide 1 for incrementers and decrementers
  
  localparam [32 - 1:0] NUM_ZAP = 32'd8; // There are reasons why this is 8
  
  localparam [32 - 1:0] NUM_ZAP_WIDTH = /* clog2(NUM_ZAP.value) */ 32'd3; // Width of NUM_ZAP
  
  localparam [32 - 1:0] NUM_ZAP_COUNT_WIDTH = /* clog2(NUM_ZAP.value + 1) */ 32'd4; // Width to count NUM_ZAP items
  
  localparam [/* clog2(NUM_ZAP.value) */ 3 - 1:0] NUM_ZAP_WIDTH_ONE = 3'd1; // NUM_ZAP_WIDTH-wide 1 for incrementers and decrementers
  
  typedef enum logic [3 - 1:0] {
    RACK_ZAP_ID_ZAP0 = 3'd0, // Zap 0 within) a rack
    RACK_ZAP_ID_ZAP1 = 3'd1, // Zap 1 within a rack
    RACK_ZAP_ID_ZAP2 = 3'd2, // Zap 2 within a rack
    RACK_ZAP_ID_ZAP3 = 3'd3, // Zap 3 within a rack
    RACK_ZAP_ID_ZAP4 = 3'd4, // Zap 4 within a rack
    RACK_ZAP_ID_ZAP5 = 3'd5, // Zap 5 within a rack
    RACK_ZAP_ID_ZAP6 = 3'd6, // Zap 6 within a rack
    RACK_ZAP_ID_ZAP7 = 3'd7 // Zap 7 within a rack
  } RACK_ZAP_ID_E; // The zap id within a rack.
  
  localparam [32 - 1:0] RACK_ZAP_ID_E_WIDTH = /* RACK_ZAP_ID_E.width */ 32'd3; // Width of RACK_ZAP_ID_E
  
  typedef enum logic {
    ADDR_TYPE_MEM = 1'd0, // This is a memory address.
    ADDR_TYPE_CSR = 1'd1 // This is an CSR address.
  } ADDR_TYPE_E; // Indicates top-level address type.
  
  localparam [32 - 1:0] ADDR_TYPE_E_WIDTH = /* ADDR_TYPE_E.width */ 32'd1; // Width of ADDR_TYPE_E
  
  typedef enum logic {
    IS_ZAP_NON_ZAP = 1'd0, // This address targets something outside a zap.
    IS_ZAP_ZAP = 1'd1 // This address targets something inside a zap.
  } IS_ZAP_E; // Indicates a zap address or a non-zap address.
  
  localparam [32 - 1:0] IS_ZAP_E_WIDTH = /* IS_ZAP_E.width */ 32'd1; // Width of IS_ZAP_E
  
  typedef enum logic [3 - 1:0] {
    NON_ZAP_BLOCK_ID_LEG_ID = 3'd0, // LEG
    NON_ZAP_BLOCK_ID_TAX_ID = 3'd1, // LEG controller
    NON_ZAP_BLOCK_ID_EGO_ID = 3'd2, // EGO controller
    NON_ZAP_BLOCK_ID_ASH_ID = 3'd4, // Interrupt Controller
    NON_ZAP_BLOCK_ID_SIN_ID = 3'd5, // Lorem ipsum dolor
    NON_ZAP_BLOCK_ID_RACK_ID = 3'd6, // One of the non-zap blocks within the RACK
    NON_ZAP_BLOCK_ID_FOX_ID = 3'd7 // Sit amet
  } NON_ZAP_BLOCK_ID_E; // The ID of an individual block in the BAG that does not live inside ZAP.
  
  localparam [32 - 1:0] NON_ZAP_BLOCK_ID_E_WIDTH = /* NON_ZAP_BLOCK_ID_E.width */ 32'd3; // Width of NON_ZAP_BLOCK_ID_E
  
  typedef enum logic [4 - 1:0] {
    ZAP_BLOCK_ID_TRY = 4'd1, // Consectetur adipiscing
    ZAP_BLOCK_ID_HORN = 4'd2, // Zap Miscellaneous Bus Controller
    ZAP_BLOCK_ID_EYE = 4'd3, // Eye beams
    ZAP_BLOCK_ID_PIE_SLICE0 = 4'd4, // PIE slice 0
    ZAP_BLOCK_ID_PIE_SLICE1 = 4'd5, // PIE slice 1
    ZAP_BLOCK_ID_PIE_SLICE2 = 4'd6, // PIE slice 2
    ZAP_BLOCK_ID_PIE_SLICE3 = 4'd7, // PIE slice 2
    ZAP_BLOCK_ID_KID = 4'd8, // Pellentesque eget
    ZAP_BLOCK_ID_JOB = 4'd9, // Aliquet lorem
    ZAP_BLOCK_ID_TIP = 4'd10, // JOB Bridge
    ZAP_BLOCK_ID_GET = 4'd11, // Nulla pharetra velit. Sed eget justo dolor. Proin egestas nulla vitae tempor fringilla. Sed commodo vulputate enim a pulvinar. Receive
    ZAP_BLOCK_ID_GRE = 4'd12 // Nulla pharetra velit. Sed eget justo dolor. Proin egestas nulla vitae tempor fringilla. Sed commodo vulputate enim a pulvinar. Transmit
  } ZAP_BLOCK_ID_E; // A subblock ID inside a ZAP.
  
  localparam [32 - 1:0] ZAP_BLOCK_ID_E_WIDTH = /* ZAP_BLOCK_ID_E.width */ 32'd4; // Width of ZAP_BLOCK_ID_E
  
  typedef enum logic [2 - 1:0] {
    RACK_BLOCK_ID_ICE = 2'd0, // Sed eget
    RACK_BLOCK_ID_CRY = 2'd1, // Sed lobortis congue Receive
    RACK_BLOCK_ID_CUP = 2'd2 // Sed lobortis congue Transmit
  } RACK_BLOCK_ID_E; // A block instantiated at RACK-level that is not a zap
  
  localparam [32 - 1:0] RACK_BLOCK_ID_E_WIDTH = /* RACK_BLOCK_ID_E.width */ 32'd2; // Width of RACK_BLOCK_ID_E
  
  typedef enum logic [3 - 1:0] {
    CUP_ID_CUP0 = 3'd0, // CUPn
    CUP_ID_CUP1 = 3'd1, // CUPn
    CUP_ID_CUP2 = 3'd2, // CUPn
    CUP_ID_CUP3 = 3'd3, // CUPn
    CUP_ID_CUP4 = 3'd4, // CUPn
    CUP_ID_CUP5 = 3'd5, // CUPn
    CUP_ID_CUP6 = 3'd6, // CUPn
    CUP_ID_CUP7 = 3'd7 // CUPn
  } CUP_ID_E; // CUP numbering for address generation
  
  localparam [32 - 1:0] CUP_ID_E_WIDTH = /* CUP_ID_E.width */ 32'd3; // Width of CUP_ID_E
  
  typedef enum logic [7 - 1:0] {
    CRY_ID_CRY0 = 7'd0, // CRYn
    CRY_ID_CRY1 = 7'd1, // CRYn
    CRY_ID_CRY2 = 7'd2, // CRYn
    CRY_ID_CRY3 = 7'd3, // CRYn
    CRY_ID_CRY4 = 7'd4, // CRYn
    CRY_ID_CRY5 = 7'd5, // CRYn
    CRY_ID_CRY6 = 7'd6, // CRYn
    CRY_ID_CRY7 = 7'd7, // CRYn
    CRY_ID_CRY8 = 7'd8, // CRYn
    CRY_ID_CRY9 = 7'd9, // CRYn
    CRY_ID_CRY10 = 7'd10, // CRYn
    CRY_ID_CRY11 = 7'd11, // CRYn
    CRY_ID_CRY12 = 7'd12, // CRYn
    CRY_ID_CRY13 = 7'd13, // CRYn
    CRY_ID_CRY14 = 7'd14, // CRYn
    CRY_ID_CRY15 = 7'd15, // CRYn
    CRY_ID_CRY16 = 7'd16, // CRYn
    CRY_ID_CRY17 = 7'd17, // CRYn
    CRY_ID_CRY18 = 7'd18, // CRYn
    CRY_ID_CRY19 = 7'd19, // CRYn
    CRY_ID_CRY20 = 7'd20, // CRYn
    CRY_ID_CRY21 = 7'd21, // CRYn
    CRY_ID_CRY22 = 7'd22, // CRYn
    CRY_ID_CRY23 = 7'd23, // CRYn
    CRY_ID_CRY24 = 7'd24, // CRYn
    CRY_ID_CRY25 = 7'd25, // CRYn
    CRY_ID_CRY26 = 7'd26, // CRYn
    CRY_ID_CRY27 = 7'd27, // CRYn
    CRY_ID_CRY28 = 7'd28, // CRYn
    CRY_ID_CRY29 = 7'd29, // CRYn
    CRY_ID_CRY30 = 7'd30, // CRYn
    CRY_ID_CRY31 = 7'd31, // CRYn
    CRY_ID_CRY32 = 7'd32, // CRYn
    CRY_ID_CRY33 = 7'd33, // CRYn
    CRY_ID_CRY34 = 7'd34, // CRYn
    CRY_ID_CRY35 = 7'd35, // CRYn
    CRY_ID_CRY36 = 7'd36, // CRYn
    CRY_ID_CRY37 = 7'd37, // CRYn
    CRY_ID_CRY38 = 7'd38, // CRYn
    CRY_ID_CRY39 = 7'd39, // CRYn
    CRY_ID_CRY40 = 7'd40, // CRYn
    CRY_ID_CRY41 = 7'd41, // CRYn
    CRY_ID_CRY42 = 7'd42, // CRYn
    CRY_ID_CRY43 = 7'd43, // CRYn
    CRY_ID_CRY44 = 7'd44, // CRYn
    CRY_ID_CRY45 = 7'd45, // CRYn
    CRY_ID_CRY46 = 7'd46, // CRYn
    CRY_ID_CRY47 = 7'd47, // CRYn
    CRY_ID_CRY48 = 7'd48, // CRYn
    CRY_ID_CRY49 = 7'd49, // CRYn
    CRY_ID_CRY50 = 7'd50, // CRYn
    CRY_ID_CRY51 = 7'd51, // CRYn
    CRY_ID_CRY52 = 7'd52, // CRYn
    CRY_ID_CRY53 = 7'd53, // CRYn
    CRY_ID_CRY54 = 7'd54, // CRYn
    CRY_ID_CRY55 = 7'd55, // CRYn
    CRY_ID_CRY56 = 7'd56, // CRYn
    CRY_ID_CRY57 = 7'd57, // CRYn
    CRY_ID_CRY58 = 7'd58, // CRYn
    CRY_ID_CRY59 = 7'd59, // CRYn
    CRY_ID_CRY60 = 7'd60, // CRYn
    CRY_ID_CRY61 = 7'd61, // CRYn
    CRY_ID_CRY62 = 7'd62, // CRYn
    CRY_ID_CRY63 = 7'd63, // CRYn
    CRY_ID_CRY64 = 7'd64, // CRYn
    CRY_ID_CRY65 = 7'd65, // CRYn
    CRY_ID_CRY66 = 7'd66, // CRYn
    CRY_ID_CRY67 = 7'd67, // CRYn
    CRY_ID_CRY68 = 7'd68, // CRYn
    CRY_ID_CRY69 = 7'd69, // CRYn
    CRY_ID_CRY70 = 7'd70, // CRYn
    CRY_ID_CRY71 = 7'd71, // CRYn
    CRY_ID_CRY72 = 7'd72, // CRYn
    CRY_ID_CRY73 = 7'd73, // CRYn
    CRY_ID_CRY74 = 7'd74, // CRYn
    CRY_ID_CRY75 = 7'd75, // CRYn
    CRY_ID_CRY76 = 7'd76, // CRYn
    CRY_ID_CRY77 = 7'd77, // CRYn
    CRY_ID_CRY78 = 7'd78, // CRYn
    CRY_ID_CRY79 = 7'd79, // CRYn
    CRY_ID_CRY80 = 7'd80, // CRYn
    CRY_ID_CRY81 = 7'd81, // CRYn
    CRY_ID_CRY82 = 7'd82, // CRYn
    CRY_ID_CRY83 = 7'd83, // CRYn
    CRY_ID_CRY84 = 7'd84, // CRYn
    CRY_ID_CRY85 = 7'd85, // CRYn
    CRY_ID_CRY86 = 7'd86, // CRYn
    CRY_ID_CRY87 = 7'd87, // CRYn
    CRY_ID_CRY88 = 7'd88, // CRYn
    CRY_ID_CRY89 = 7'd89, // CRYn
    CRY_ID_CRY90 = 7'd90, // CRYn
    CRY_ID_CRY91 = 7'd91, // CRYn
    CRY_ID_CRY92 = 7'd92, // CRYn
    CRY_ID_CRY93 = 7'd93, // CRYn
    CRY_ID_CRY94 = 7'd94, // CRYn
    CRY_ID_CRY95 = 7'd95, // CRYn
    CRY_ID_CRY96 = 7'd96, // CRYn
    CRY_ID_CRY97 = 7'd97, // CRYn
    CRY_ID_CRY98 = 7'd98, // CRYn
    CRY_ID_CRY99 = 7'd99, // CRYn
    CRY_ID_CRY100 = 7'd100, // CRYn
    CRY_ID_CRY101 = 7'd101, // CRYn
    CRY_ID_CRY102 = 7'd102, // CRYn
    CRY_ID_CRY103 = 7'd103, // CRYn
    CRY_ID_CRY104 = 7'd104, // CRYn
    CRY_ID_CRY105 = 7'd105, // CRYn
    CRY_ID_CRY106 = 7'd106, // CRYn
    CRY_ID_CRY107 = 7'd107, // CRYn
    CRY_ID_CRY108 = 7'd108, // CRYn
    CRY_ID_CRY109 = 7'd109, // CRYn
    CRY_ID_CRY110 = 7'd110, // CRYn
    CRY_ID_CRY111 = 7'd111, // CRYn
    CRY_ID_CRY112 = 7'd112, // CRYn
    CRY_ID_CRY113 = 7'd113, // CRYn
    CRY_ID_CRY114 = 7'd114, // CRYn
    CRY_ID_CRY115 = 7'd115, // CRYn
    CRY_ID_CRY116 = 7'd116, // CRYn
    CRY_ID_CRY117 = 7'd117, // CRYn
    CRY_ID_CRY118 = 7'd118, // CRYn
    CRY_ID_CRY119 = 7'd119, // CRYn
    CRY_ID_CRY120 = 7'd120, // CRYn
    CRY_ID_CRY121 = 7'd121, // CRYn
    CRY_ID_CRY122 = 7'd122, // CRYn
    CRY_ID_CRY123 = 7'd123, // CRYn
    CRY_ID_CRY124 = 7'd124, // CRYn
    CRY_ID_CRY125 = 7'd125, // CRYn
    CRY_ID_CRY126 = 7'd126, // CRYn
    CRY_ID_CRY127 = 7'd127 // CRYn
  } CRY_ID_E; // CRY numbering for address generation
  
  localparam [32 - 1:0] CRY_ID_E_WIDTH = /* CRY_ID_E.width */ 32'd7; // Width of CRY_ID_E
  
  typedef enum logic {
    ICE_ID_ICE0 = 1'd0 // ICE 0
  } ICE_ID_E; // ICE Numbering
  
  localparam [32 - 1:0] ICE_ID_E_WIDTH = /* ICE_ID_E.width */ 32'd1; // Width of ICE_ID_E
  
  typedef logic [/* clog2(8) */ 3 - 1:0] rack_id_t; // ID of a rack
  
  typedef struct packed {
    rack_id_t rack_id; // ID of a rack
    RACK_ZAP_ID_E zap_id; // Zap ID (Within a rack)
  } zap_id_t; // The ID for a given ZAP
  
  localparam [32 - 1:0] ZAP_ID_T_WIDTH = /* zap_id_t.width */ 32'd6; // Width of zap_id_t
  
  typedef struct packed {
    logic [/* ADDR_WIDTH.value - IS_ZAP_E.width - ADDR_TYPE_E.width - zap_id_t.width */ 19 - 1:0] offset; // JOB Address Offset
  } job_addr_t; // JOB Addr struct
  
  typedef struct packed {
    ZAP_BLOCK_ID_E zap_block_id; // A subblock ID inside a ZAP.
    logic [/* ADDR_WIDTH.value - IS_ZAP_E.width - ADDR_TYPE_E.width - zap_id_t.width - ZAP_BLOCK_ID_E.width */ 15 - 1:0] offset; // offset into the CSR address space
  } zap_csr_addr_t; // Zap CSR Addr Struct
  
  typedef union packed {
    job_addr_t job_addr; // JOB Addr struct
    zap_csr_addr_t zap_csr_addr; // Zap CSR Addr Struct
  } zap_addr_sub_addr_t; // Union of the sub_addr field in zap_addr_t
  
  // Only valid when addr_t.addr_type == ADDR_TYPE_E::MEM
  typedef struct packed {
    ADDR_TYPE_E is_csr; // Indicates top-level address type.
    zap_id_t zap_id; // The ID for a given ZAP
    zap_addr_sub_addr_t sub_addr; // Union of the sub_addr field in zap_addr_t
  } zap_addr_t; // A memory address
  
  // clog2(NUM_ZAP) is used here because this field needs to address
  // individual instances of any non-zap block instantiated in the
  // RACK (CRY, CUP, ICE). In this case, there are more CRY instances
  // (NUM_ZAP) than CUP or ICE instances so NUM_ZAP is used.
  typedef logic [/* clog2(NUM_ZAP.value) */ 3 - 1:0] rack_block_inst_id_t; // ID number for one of the non-zap blocks instantiated at RACK-level
  
  typedef struct packed {
    rack_id_t rack_id; // ID of a rack
    RACK_BLOCK_ID_E rack_block_id; // which type of block
    rack_block_inst_id_t rack_block_inst_id; // Which instance of this block-type
    logic [/* ADDR_WIDTH.value - IS_ZAP_E.width - NON_ZAP_BLOCK_ID_E.width - rack_id_t.width - RACK_BLOCK_ID_E.width - rack_block_inst_id_t.width */ 15 - 1:0] offset; // offset within this instance's addr space
  } rack_addr_t; // Address for blocks within the RACK
  
  typedef union packed {
    logic [/* ADDR_WIDTH.value - IS_ZAP_E.width - NON_ZAP_BLOCK_ID_E.width */ 23 - 1:0] offset; // offset for cases where this is not a RACK-block
    rack_addr_t rack_addr; // Address for blocks within the RACK
  } non_zap_subaddr_t; // Union for sub_addr field in addr_t
  
  typedef struct packed {
    NON_ZAP_BLOCK_ID_E non_zap_block_id; // The ID of an individual block in the BAG that does not live inside ZAP.
    non_zap_subaddr_t sub_addr; // Union for sub_addr field in addr_t
  } non_zap_addr_t; // Non-Zap Addr Struct
  
  typedef union packed {
    zap_addr_t zap_addr; // A memory address
    non_zap_addr_t non_zap_addr; // Non-Zap Addr Struct
  } addr_sub_addr_t; // Union for sub_addr field in addr_t
  
  typedef struct packed {
    IS_ZAP_E is_zap; // Indicates a zap address or a non-zap address.
    addr_sub_addr_t sub_addr; // Union for sub_addr field in addr_t
  } addr_t; // A generic address
  
  localparam [32 - 1:0] ADDR_T_WIDTH = /* addr_t.width */ 32'd27; // Width of addr_t
  
  localparam [32 - 1:0] JOB_ADDR_T_WIDTH = /* job_addr_t.width */ 32'd19; // Width of job_addr_t
  
  localparam [32 - 1:0] ZAP_CSR_ADDR_T_WIDTH = /* zap_csr_addr_t.width */ 32'd19; // Width of zap_csr_addr_t
  
  localparam [32 - 1:0] ZAP_ADDR_T_WIDTH = /* zap_addr_t.width */ 32'd26; // Width of zap_addr_t
  
  localparam [32 - 1:0] NON_ZAP_ADDR_T_WIDTH = /* non_zap_addr_t.width */ 32'd26; // Width of non_zap_addr_t
  
  localparam [32 - 1:0] RACK_ADDR_T_WIDTH = /* rack_addr_t.width */ 32'd23; // Width of rack_addr_t
  
  localparam [32 - 1:0] RACK_ID_T_WIDTH = /* rack_id_t.width */ 32'd3; // Width of rack_id_t
  
  localparam [32 - 1:0] RACK_BLOCK_INST_ID_T_WIDTH = /* rack_block_inst_id_t.width */ 32'd3; // Width of rack_block_inst_id_t
  
  typedef logic [/* clog2(4) */ 2 - 1:0] quad_id_t; // ID of a quad
  
  localparam [32 - 1:0] QUAD_ID_T_WIDTH = /* quad_id_t.width */ 32'd2; // Width of quad_id_t
  

endpackage : test_pkg_c_rypkg
`endif // guard