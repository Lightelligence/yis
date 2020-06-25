// Copyright (c) 2020 Lightelligence
// Description: Memory Wrappers Interface generated from .yis by YIS

///////////////////////////////////////////////////////////////////////////////
// name: test
// doc_summary: this is a test FIFO
/* doc_verbose: None */
// width: 16  ==>  16
// depth: 64  ==>  64
// ports: 1p

module test_sync_fifo
(
  input  clk,
  input  reset_n,
  input  fifo_wr,
  input  fifo_rd,
  input  [15:0] fifo_din,
  //FIXME: plumb this & DFT eventually input mem_pkg::dual_port_test_margin__st dual_port_test_margin__s,
  output fifo_amt,
  output logic fifo_mt,
  output fifo_afull,
  output fifo_full,
  output fifo_err,
  output logic fifo_rd_vld,
  output logic [15:0] fifo_dout
);

  localparam SYNC_RESET_FIXME = 1; // this needs to be reviewed with the reset scheme eventually

  logic [5:0] waddr;
  logic [5:0] raddr;
  logic we_n;
  logic pop_req_n;
  logic push_req_n;
  logic [5:0] addr;

  // simple arb if this is a 1P mem. assertion to go along with it.
  assign addr = fifo_wr ? waddr : raddr;
  ERR_RW_CONFLICT_ON_SINGLE_PORT_MEM: assert property (@(posedge clk) !(fifo_wr && fifo_rd)) else $error("%t: %m: ERROR: Can't read and write single-port FIFO in the same cycle", $time);

  assign push_req_n = ~fifo_wr;
  assign pop_req_n  = ~fifo_rd;

  // err_mode 0 means the error bit is latched until reset on any of the following (refer to the CW_fifoctl_s1_sf module for more details.):
  // 1. Overflow (push and no pop while full).
  // 2. Underflow (pop while empty).
  // 3. Empty pointer mismatch (rd_addr   wr_addr when empty).
  // 4. Full pointer mismatch (rd_addr   wr_addr when full).
  // 5. In between pointer mismatch (rd_addr = wr_addr when neither empty nor full).
  CW_fifoctl_s1_sf #(.depth(64), .ae_level(1), .af_level(1),
                     .err_mode(0), .rst_mode(SYNC_RESET_FIXME)) fifo_ctrl (  // lint: disable=UNCONN,UNCONO,SYNPRT
    .clk          (clk),
    .rst_n        (reset_n),
    .push_req_n   (push_req_n),
    .pop_req_n    (pop_req_n),
    .diag_n       (1'b1),
    .we_n         (we_n),
    .empty        (fifo_mt),
    .almost_empty (fifo_amt),
    .half_full    (),
    .almost_full  (fifo_afull),
    .full         (fifo_full),
    .error        (fifo_err),
    .wr_addr      (waddr),
    .rd_addr      (raddr));

  test_fifo_a_test_mem fifo_mem (
    .clk(clk),
    .rd(fifo_rd),
    .wr(fifo_wr),
    .addr(addr),
    .rdata(fifo_dout),
    .wdata(fifo_din),
    .dft_i_xyz(), // FIXME
    .prot_i_xyz(),// FIXME
    .dft_o_xyz(), // FIXME
    .prot_o_xyz() // FIXME
  );

endmodule : test_sync_fifo
