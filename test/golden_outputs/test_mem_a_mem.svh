// Copyright (c) 2020 Lightelligence
// Description: Memory Wrappers Interface generated from test_mem_a.yis by YIS


///////////////////////////////////////////////////////////////////////////////
// name: rx_fifo
// doc_summary: Receive FIFO Memory
/* doc_verbose: Boring info about memories. And now
I'm on a new line
 */
// width: test_pkg_a::TRIPLE_NESTED_PARAM.width+4  ==>  6
// depth: 512  ==>  512
// ecc: True
// parity: False
// ports: 2p

module rx_fifo_mem_wrapper(
    // Output Ports
    output [5:0] rdata,
    // Input Ports
    input [8:0] raddr,
    input [8:0] waddr,
    input [5:0] wdata,
    input wr,
    input rd,
    // DFT
    //
    input clk
);

    //==========================================================================
    //  SRAM instance
    //--------------------------------------------------------------------------
    // behavior mem model for now
    wire [10:0] data_to_sram, data_from_sram;
    flop_array_2p #(.ADDR_WIDTH(9), .DATA_WIDTH(11), .DEPTH(512) ) u_mem (
        .we(wr),
        .re(rd),
        .waddr(waddr),
        .raddr(raddr),
        .wdata(data_to_sram),
        .rdata(data_from_sram),
        .clk(clk)
    );

    //==========================================================================
    // Read pipeline
    //--------------------------------------------------------------------------
    // in pipe FIXME

    // out pipe
    wire [5:0] data_from_oup0;
    test_mem_a_pipe #(.WIDTH(11), .PIPE_STAGES(1)) out_pipe0 (
        .d(data_from_sram),
        .q(data_from_oup0),
        .clk(clk)
    );
    wire [5:0] data_to_oup1;
    test_mem_a_pipe #(.WIDTH(6), .PIPE_STAGES(1)) out_pipe1 (
        .d(data_to_oup1),
        .q(rdata),
        .clk(clk)
    );

    //==========================================================================
    //  Protection
    //--------------------------------------------------------------------------
    //  ECC
    //  - gen -
    wire [4:0] checksum;
    assign data_to_sram = {checksum, wdata};
    test_mem_a_m6_ecc_gen u_gen (
        .ecc(checksum),
        .data(wdata)
    );
    //  - chk -
    test_mem_a_m6_ecc_chk u_chk (
        .data(data_to_oup1),
        .single_bit_err(),
        .double_bit_err(),
        .codeword(data_from_oup0)
    );
    //  - hero -

endmodule : rx_fifo_mem_wrapper

///////////////////////////////////////////////////////////////////////////////
// name: tx_fifo
// doc_summary: Transimit FIFO Memory

// width: test_pkg_a::hero_write__st.width  ==>  46
// depth: 1024  ==>  1024
// ecc: True
// parity: False
// ports: 1p

module tx_fifo_mem_wrapper(
    // Output Ports
    output [45:0] rdata,
    // Input Ports
    input [9:0] addr,
    input [45:0] wdata,
    input wr,
    input rd,
    // DFT
    //
    input clk
);

    //==========================================================================
    //  SRAM instance
    //--------------------------------------------------------------------------
    // behavior mem model for now
    wire [52:0] data_to_sram, data_from_sram;
    flop_array_2p #(.ADDR_WIDTH(10), .DATA_WIDTH(53), .DEPTH(1024) ) u_mem (
        .we(wr),
        .re(rd),
        .waddr(addr),
        .raddr(addr),
        .wdata(data_to_sram),
        .rdata(data_from_sram),
        .clk(clk)
    );

    //==========================================================================
    // Read pipeline
    //--------------------------------------------------------------------------
    // in pipe FIXME

    // out pipe
    wire [45:0] data_from_oup0;
    test_mem_a_pipe #(.WIDTH(53), .PIPE_STAGES(1)) out_pipe0 (
        .d(data_from_sram),
        .q(data_from_oup0),
        .clk(clk)
    );
    wire [45:0] data_to_oup1;
    test_mem_a_pipe #(.WIDTH(46), .PIPE_STAGES(1)) out_pipe1 (
        .d(data_to_oup1),
        .q(rdata),
        .clk(clk)
    );

    //==========================================================================
    //  Protection
    //--------------------------------------------------------------------------
    //  ECC
    //  - gen -
    wire [6:0] checksum;
    assign data_to_sram = {checksum, wdata};
    test_mem_a_m46_ecc_gen u_gen (
        .ecc(checksum),
        .data(wdata)
    );
    //  - chk -
    test_mem_a_m46_ecc_chk u_chk (
        .data(data_to_oup1),
        .single_bit_err(),
        .double_bit_err(),
        .codeword(data_from_oup0)
    );
    //  - hero -

endmodule : tx_fifo_mem_wrapper

///////////////////////////////////////////////////////////////////////////////
// name: wt_fifo
// doc_summary: Weight FIFO Memory

// width: 6  ==>  6
// depth: test_pkg_a::hero_write__st.width  ==>  46
// ecc: True
// parity: False
// ports: 2p

module wt_fifo_mem_wrapper(
    // Output Ports
    output [5:0] rdata,
    // Input Ports
    input [5:0] raddr,
    input [5:0] waddr,
    input [5:0] wdata,
    input wr,
    input rd,
    // DFT
    //
    input clk
);

    //==========================================================================
    //  SRAM instance
    //--------------------------------------------------------------------------
    // behavior mem model for now
    wire [10:0] data_to_sram, data_from_sram;
    flop_array_2p #(.ADDR_WIDTH(6), .DATA_WIDTH(11), .DEPTH(46) ) u_mem (
        .we(wr),
        .re(rd),
        .waddr(waddr),
        .raddr(raddr),
        .wdata(data_to_sram),
        .rdata(data_from_sram),
        .clk(clk)
    );

    //==========================================================================
    // Read pipeline
    //--------------------------------------------------------------------------
    // in pipe FIXME

    // out pipe
    wire [5:0] data_from_oup0;
    test_mem_a_pipe #(.WIDTH(11), .PIPE_STAGES(1)) out_pipe0 (
        .d(data_from_sram),
        .q(data_from_oup0),
        .clk(clk)
    );
    wire [5:0] data_to_oup1;
    test_mem_a_pipe #(.WIDTH(6), .PIPE_STAGES(1)) out_pipe1 (
        .d(data_to_oup1),
        .q(rdata),
        .clk(clk)
    );

    //==========================================================================
    //  Protection
    //--------------------------------------------------------------------------
    //  ECC
    //  - gen -
    wire [4:0] checksum;
    assign data_to_sram = {checksum, wdata};
    test_mem_a_m6_ecc_gen u_gen (
        .ecc(checksum),
        .data(wdata)
    );
    //  - chk -
    test_mem_a_m6_ecc_chk u_chk (
        .data(data_to_oup1),
        .single_bit_err(),
        .double_bit_err(),
        .codeword(data_from_oup0)
    );
    //  - hero -

endmodule : wt_fifo_mem_wrapper

///////////////////////////////////////////////////////////////////////////////
// name: adc_fifo
// doc_summary: adc FIFO Memory

// width: 11  ==>  11
// depth: test_pkg_a::hero_write__st.width  ==>  46
// ecc: False
// parity: True
// ports: 1p

module adc_fifo_mem_wrapper(
    // Output Ports
    output [10:0] rdata,
    // Input Ports
    input [5:0] addr,
    input [10:0] wdata,
    input wr,
    input rd,
    // DFT
    //
    input clk
);

    //==========================================================================
    //  SRAM instance
    //--------------------------------------------------------------------------
    // behavior mem model for now
    wire [11:0] data_to_sram, data_from_sram;
    flop_array_2p #(.ADDR_WIDTH(6), .DATA_WIDTH(12), .DEPTH(46) ) u_mem (
        .we(wr),
        .re(rd),
        .waddr(addr),
        .raddr(addr),
        .wdata(data_to_sram),
        .rdata(data_from_sram),
        .clk(clk)
    );

    //==========================================================================
    // Read pipeline
    //--------------------------------------------------------------------------
    // in pipe FIXME

    // out pipe
    wire [10:0] data_from_oup0;
    test_mem_a_pipe #(.WIDTH(12), .PIPE_STAGES(1)) out_pipe0 (
        .d(data_from_sram),
        .q(data_from_oup0),
        .clk(clk)
    );
    wire [10:0] data_to_oup1;
    test_mem_a_pipe #(.WIDTH(11), .PIPE_STAGES(1)) out_pipe1 (
        .d(data_to_oup1),
        .q(rdata),
        .clk(clk)
    );

    //==========================================================================
    //  Protection
    //--------------------------------------------------------------------------
    //  Parity
    //  - gen -
    wire [0:0] checksum;
    assign data_to_sram = {checksum, wdata};
    test_mem_a_m11_parity_gen u_gen (
        .parity(checksum),
        .data(wdata)
    );
    //  - chk -
    test_mem_a_m11_parity_chk u_chk (
        .data(data_to_oup1),
        .err(),
        .codeword(data_from_oup0)
    );
    //  - hero -

endmodule : adc_fifo_mem_wrapper

///////////////////////////////////////////////////////////////////////////////
// name: hero_fifo
// doc_summary: hero FIFO Memory

// width: 2  ==>  2
// depth: test_pkg_a::hero_write__st.width  ==>  46
// ecc: False
// parity: False
// ports: 1p

module hero_fifo_mem_wrapper(
    // Output Ports
    output [1:0] rdata,
    // Input Ports
    input [5:0] addr,
    input [1:0] wdata,
    input wr,
    input rd,
    // DFT
    //
    input clk
);

    //==========================================================================
    //  SRAM instance
    //--------------------------------------------------------------------------
    // behavior mem model for now
    wire [1:0] data_to_sram, data_from_sram;
    flop_array_2p #(.ADDR_WIDTH(6), .DATA_WIDTH(2), .DEPTH(46) ) u_mem (
        .we(wr),
        .re(rd),
        .waddr(addr),
        .raddr(addr),
        .wdata(data_to_sram),
        .rdata(data_from_sram),
        .clk(clk)
    );

    //==========================================================================
    // Read pipeline
    //--------------------------------------------------------------------------
    // in pipe FIXME

    // out pipe
    wire [1:0] data_from_oup0;
    test_mem_a_pipe #(.WIDTH(2), .PIPE_STAGES(1)) out_pipe0 (
        .d(data_from_sram),
        .q(data_from_oup0),
        .clk(clk)
    );
    wire [1:0] data_to_oup1;
    test_mem_a_pipe #(.WIDTH(2), .PIPE_STAGES(1)) out_pipe1 (
        .d(data_to_oup1),
        .q(rdata),
        .clk(clk)
    );

    assign data_to_sram = wdata;
    assign data_to_oup1 = data_from_oup0;

endmodule : hero_fifo_mem_wrapper
