// Copyright (c) 2020 Lightelligence
// Description: Memory Wrappers Interface generated from test_mem_a.yis by YIS


///////////////////////////////////////////////////////////////////////////////
// name: rx_fifo
// doc_summary: Receive FIFO Memory
/* doc_verbose: Boring info about memories. And now
I'm on a new line
 */
// width: test_pkg_a::TRIPLE_NESTED_PARAM.width+4  ==>  6
// depth: test_pkg_a::hero_write_t.width+18  ==>  64
// ports: 2p
// prot: none
// sram_cfg: flop_array_2p
// pipe0: 2
// pipe1: 1
// row: 1
// col: 1
// read_ports: 1
// write_ports: 1
// stage0: 0
// stage1: 0

module behav_2p_mem(
    input  rd,
    input [5:0] raddr,
    output [5:0] rdata,
    input  wr,
    input [5:0] waddr,
    input [5:0] wdata,
    input wr,
    input rd,
    // DFT
    //
    input clk
);


    typedef struct packed {
        logic [5:0] waddr;
        logic [5:0] raddr;
        logic  wr;
        logic [5:0] wdata;
        logic  rd;
        logic [5:0] rdata;
    }   sram_io_t;

    //==========================================================================
    // Write/Read in stages
    //--------------------------------------------------------------------------
        // in rewiring
            //  -   data
            wire [5:0] data_in;
            assign data_in[5:0] = wdata;
            
        
        
        // ctrl bits
            wire [0:0] rd_ctrl;
            wire [0:0] wr_ctrl;
            assign rd_ctrl =rd;
            assign wr_ctrl =wr;
        // ctrl/addr/data mux
            sram_io_t     sram_io [0:0];
            assign sram_io[0].rd = rd_ctrl[0];
            assign sram_io[0].wr = wr_ctrl[0];
            assign sram_io[0].raddr =raddr[5:0];
            assign sram_io[0].waddr =waddr[5:0];
            assign sram_io[0].wdata =data_in;
        

    //==========================================================================
    //  SRAM instance
    //--------------------------------------------------------------------------
        // behavior mem model
        wire [5:0] data_to_behav_pipe_0_0;
        test_mem_a_pipe #(.WIDTH(6), .PIPE_STAGES(1)) u_behav_pipe_0_0 (
            .d(data_to_behav_pipe_0_0),
            .q(sram_io[0].rdata[5:0]),
            .clk(clk)
        );
        `gumi_flop_array_2p #(.ADDR_WIDTH(6), .DATA_WIDTH(6), .DEPTH(64) ) u_mem_0_0 (
            .we(sram_io[0].wr),
            .re(sram_io[0].rd),
            .waddr(sram_io[0].waddr),
            .raddr(sram_io[0].raddr),
            .wdata(sram_io[0].wdata[5:0]),
            .rdata(data_to_behav_pipe_0_0),
        .clk(clk)
    );

    //==========================================================================
    // Read pipeline
    //--------------------------------------------------------------------------

            wire [5:0] data_to_oup0;
            assign data_to_oup0 = sram_io[0].rdata;
        //  out pipe 0
            wire [5:0] data_out;
            test_mem_a_pipe #(.WIDTH(6), .PIPE_STAGES(2-1)) pipe0 (
                .d(data_to_oup0),
                .q(data_out),
        .clk(clk)
    );
        //  out pipe 1
            test_mem_a_pipe #(.WIDTH(6), .PIPE_STAGES(1)) pipe1 (
                .d(data_out),
        .q(rdata),
        .clk(clk)
    );

    

    `ifdef TBV
        test_mem_a_pipe #(.WIDTH(1), .PIPE_STAGES(4)) rdata_vld (
            .d(rd),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(6), .PIPE_STAGES(4)) raddr_pipe (
            .d(raddr),
            .q(),
            .clk(clk)
        );
    `endif  //  TBV

endmodule : behav_2p_mem


///////////////////////////////////////////////////////////////////////////////
// name: tx_fifo
// doc_summary: Transimit FIFO Memory

// width: test_pkg_a::hero_write__st.width  ==>  46
// depth: 1024  ==>  1024
// ecc: True
// parity: False
// ports: 1p
// prot: ecc
// sram_cfg: sad2lsph4s1p784x16m4b1w0c1p0d0r3s10
// pipe0: 2
// pipe1: 1
// row: 1
// col: 1
// read_ports: 1
// write_ports: 1
// stage0: 0
// stage1: 0

module sram_1p_ecc_mem(
    input rd,
    input [8:0] raddr,
    output [10:0] rdata,
    input  wr,
    input [8:0] waddr,
    input [10:0] wdata,
    // DFT
    //
    input clk
);


    typedef struct packed {
        logic [8:0] addr;
        logic  wr;
        logic [15:0] wdata;
        logic  rd;
        logic [15:0] rdata;
    }   sram_io_t;

    //==========================================================================
    //  SRAM instance
    //--------------------------------------------------------------------------
        // in rewiring
            //  -   data
            wire [15:0] data_in;
            assign data_in[10:0] = wdata;
            //  -   addr
            wire [8:0]  addr;
            assign addr =wr ? waddr : raddr;
        
        
        // ctrl bits
            wire [0:0] rd_ctrl;
            wire [0:0] wr_ctrl;
            assign rd_ctrl =rd;
            assign wr_ctrl =wr;
        // ctrl/addr/data mux
            sram_io_t     sram_io [0:0];
            assign sram_io[0].rd = rd_ctrl[0];
            assign sram_io[0].wr = wr_ctrl[0];
            assign sram_io[0].addr =addr[8:0];
            assign sram_io[0].wdata =data_in;
        

    //==========================================================================
    // Read pipeline
    //--------------------------------------------------------------------------
        // sram
        `gumi_sad2lsph4s1p784x16m4b1w0c1p0d0r3s10 u_mem_0_0 (
            //  PORT_
            //  --
            //   - output
            .QP(sram_io[0].rdata[15:0]),
            //   - input
            .PIPEME('1),
            //   - input
            .WE(sram_io[0].wr),
            .D(sram_io[0].wdata[15:0]),
            .CLK(clk),
            .ME(sram_io[0].wr | sram_io[0].rd),
            .ADR({1'b0, sram_io[0].addr}),
            //  light sleep
            .LS(1'b0)
        );

    //==========================================================================
    // Read out pipeline
    //--------------------------------------------------------------------------
        
            wire [15:0] data_to_oup0;
            assign data_to_oup0 = sram_io[0].rdata;
        //  out pipe 0
            wire [15:0] data_out;
            test_mem_a_pipe #(.WIDTH(16), .PIPE_STAGES(2-1)) pipe0 (
                .d(data_to_oup0),
                .q(data_out),
        .clk(clk)
    );
        //  out pipe 1
            wire [10:0] data_to_oup1;
            test_mem_a_pipe #(.WIDTH(11), .PIPE_STAGES(1)) pipe1 (
        .d(data_to_oup1),
        .q(rdata),
        .clk(clk)
    );

    //==========================================================================
    //  Protection
    //--------------------------------------------------------------------------
        //  Ecc
    //  - gen -
            test_mem_a_m11_ecc_gen u_gen (
                .ecc_to_sram(data_in[15:11]),
                .data_in(wdata)
    );
    //  - chk -
            test_mem_a_m11_ecc_chk u_chk (
                .data_out(data_to_oup1),
        .single_bit_err(),
        .double_bit_err(),
                .ecc_from_sram(data_out[15:11]),
                .data_from_sram(data_out[10:0])
    );
    //  - hero -

    `ifdef TBV
        test_mem_a_pipe #(.WIDTH(1), .PIPE_STAGES(4)) rdata_vld (
            .d(rd),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(9), .PIPE_STAGES(4)) raddr_pipe (
            .d(addr),
            .q(),
            .clk(clk)
        );
    `endif  //  TBV

endmodule : sram_1p_ecc_mem


///////////////////////////////////////////////////////////////////////////////
// name: wt_fifo
// doc_summary: Weight FIFO Memory

// width: test_pkg_a::hero_write_t.width - 20  ==>  26
// depth: 1024  ==>  1024
// ports: 2p
// prot: ecc
// sram_cfg: sadglsph4s2p768x16m4b8w0c1p0d0r1s10
// pipe0: 2
// pipe1: 1
// row: 2
// col: 2
// read_ports: 1
// write_ports: 1
// stage0: 0
// stage1: 0

module sub_banking_mem(
    input rd,
    input [9:0] raddr,
    output [25:0] rdata,
    input  wr,
    input [9:0] waddr,
    input [25:0] wdata,
    // DFT
    //
    input clk
);
    wire [31:0]  unused;
    wire unused_ok;
    assign unused_ok = |unused;

    typedef struct packed {
        logic [8:0] waddr;
        logic [8:0] raddr;
        logic  wr;
        logic [31:0] wdata;
        logic  rd;
        logic [31:0] rdata;
    }   sram_io_t;

    //==========================================================================
    //  SRAM instance
    //--------------------------------------------------------------------------
        // in rewiring
            //  -   data
            wire [31:0] data_in;
            assign data_in[25:0] = wdata;
            
        
        // addr decoder
            wire [1:0]    raddr_decoder[0:0];
            wire [1:0]    waddr_decoder[0:0];
            assign raddr_decoder[0] = 1'b1 << raddr[9:9];
            assign waddr_decoder[0] = 1'b1 << waddr[9:9];
        // ctrl bits
            wire [1:0] rd_ctrl;
            wire [1:0] wr_ctrl;
            assign rd_ctrl =(raddr_decoder[0] & { 2{rd} }) ;
            assign wr_ctrl =(waddr_decoder[0] & { 2{wr} }) ;
        // ctrl/addr/data mux
            sram_io_t     sram_io [1:0];
            assign sram_io[0].rd = rd_ctrl[0];
            assign sram_io[0].wr = wr_ctrl[0];
            assign sram_io[0].raddr =raddr[8:0];
            assign sram_io[0].waddr =waddr[8:0];
            assign sram_io[0].wdata =data_in;
            assign sram_io[1].rd = rd_ctrl[1];
            assign sram_io[1].wr = wr_ctrl[1];
            assign sram_io[1].raddr =raddr[8:0];
            assign sram_io[1].waddr =waddr[8:0];
            assign sram_io[1].wdata =data_in;
        

    //==========================================================================
    // Read pipeline
    //--------------------------------------------------------------------------
        // sram
        `gumi_sadglsph4s2p768x16m4b8w0c1p0d0r1s10 u_mem_0_0 (
            //  PORT_A
            //  --
            //   - output
            //   - input
            .WEA('1),
            .DA(sram_io[0].wdata[15:0]),
            .CLKA(clk),
            .MEA(sram_io[0].wr),
            .ADRA({1'b0, sram_io[0].waddr}),
            //  PORT_B
            //  --
            //   - output
            .QPB(sram_io[0].rdata[15:0]),
            //   - input
            .PIPEMEB('1),
            .CLKB(clk),
            .MEB(sram_io[0].rd),
            .ADRB({1'b0, sram_io[0].raddr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sadglsph4s2p768x16m4b8w0c1p0d0r1s10 u_mem_0_1 (
            //  PORT_A
            //  --
            //   - output
            //   - input
            .WEA('1),
            .DA(sram_io[0].wdata[31:16]),
            .CLKA(clk),
            .MEA(sram_io[0].wr),
            .ADRA({1'b0, sram_io[0].waddr}),
            //  PORT_B
            //  --
            //   - output
            .QPB(sram_io[0].rdata[31:16]),
            //   - input
            .PIPEMEB('1),
            .CLKB(clk),
            .MEB(sram_io[0].rd),
            .ADRB({1'b0, sram_io[0].raddr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sadglsph4s2p768x16m4b8w0c1p0d0r1s10 u_mem_1_0 (
            //  PORT_A
            //  --
            //   - output
            //   - input
            .WEA('1),
            .DA(sram_io[1].wdata[15:0]),
            .CLKA(clk),
            .MEA(sram_io[1].wr),
            .ADRA({1'b0, sram_io[1].waddr}),
            //  PORT_B
            //  --
            //   - output
            .QPB(sram_io[1].rdata[15:0]),
            //   - input
            .PIPEMEB('1),
            .CLKB(clk),
            .MEB(sram_io[1].rd),
            .ADRB({1'b0, sram_io[1].raddr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sadglsph4s2p768x16m4b8w0c1p0d0r1s10 u_mem_1_1 (
            //  PORT_A
            //  --
            //   - output
            //   - input
            .WEA('1),
            .DA(sram_io[1].wdata[31:16]),
            .CLKA(clk),
            .MEA(sram_io[1].wr),
            .ADRA({1'b0, sram_io[1].waddr}),
            //  PORT_B
            //  --
            //   - output
            .QPB(sram_io[1].rdata[31:16]),
            //   - input
            .PIPEMEB('1),
            .CLKB(clk),
            .MEB(sram_io[1].rd),
            .ADRB({1'b0, sram_io[1].raddr}),
            //  light sleep
            .LS(1'b0)
        );

    //==========================================================================
    // Read out pipeline
    //--------------------------------------------------------------------------
        // rd_sel_pipe
            wire [0:0]   rd_sel;
            test_mem_a_pipe #(.WIDTH(1), .PIPE_STAGES(1+1+0)) rd_sel_pipe (
                .d(raddr[9:9]),
                .q(rd_sel),
                .clk(clk)
            );
        // rd dout mux
            wire [31:0] data_to_oup0;
            assign data_to_oup0 = sram_io[rd_sel].rdata;
        //  out pipe 0
            wire [31:0] data_out;
            test_mem_a_pipe #(.WIDTH(32), .PIPE_STAGES(2-1)) pipe0 (
                .d(data_to_oup0),
                .q(data_out),
        .clk(clk)
    );
        //  out pipe 1
            wire [25:0] data_to_oup1;
            test_mem_a_pipe #(.WIDTH(26), .PIPE_STAGES(1)) pipe1 (
        .d(data_to_oup1),
        .q(rdata),
        .clk(clk)
    );

    //==========================================================================
    //  Protection
    //--------------------------------------------------------------------------
        //  Ecc
    //  - gen -
            test_mem_a_m26_ecc_gen u_gen (
                .ecc_to_sram(data_in[31:26]),
                .data_in(wdata)
    );
    //  - chk -
            test_mem_a_m26_ecc_chk u_chk (
                .data_out(data_to_oup1),
        .single_bit_err(),
        .double_bit_err(),
                .ecc_from_sram(data_out[31:26]),
                .data_from_sram(data_out[25:0])
    );
    //  - hero -

    `ifdef TBV
        test_mem_a_pipe #(.WIDTH(1), .PIPE_STAGES(4)) rdata_vld (
            .d(rd),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(10), .PIPE_STAGES(4)) raddr_pipe (
            .d(raddr),
            .q(),
            .clk(clk)
        );
    `endif  //  TBV

endmodule : sub_banking_mem


///////////////////////////////////////////////////////////////////////////////
// name: adc_fifo
// doc_summary: adc FIFO Memory

// width: 8  ==>  8
// depth: test_pkg_a::hero_write_t.width+18  ==>  64
// ports: 2p
// prot: parity
// sram_cfg: sadglsph4s2p768x16m4b8w0c1p0d0r1s10
// pipe0: 2
// pipe1: 1
// row: 8
// col: 1
// read_ports: 6
// write_ports: 4
// stage0: 1
// stage1: 0

module multiple_port_2p_mem(
    input  rd_0,
    input [5:0] raddr_0,
    output [7:0] rdata_0,
    input  wr_0,
    input [5:0] waddr_0,
    input [7:0] wdata_0,
    input  rd_1,
    input [5:0] raddr_1,
    output [7:0] rdata_1,
    input  wr_1,
    input [5:0] waddr_1,
    input [7:0] wdata_1,
    input  rd_2,
    input [5:0] raddr_2,
    output [7:0] rdata_2,
    input  wr_2,
    input [5:0] waddr_2,
    input [7:0] wdata_2,
    input  rd_3,
    input [5:0] raddr_3,
    output [7:0] rdata_3,
    input  wr_3,
    input [5:0] waddr_3,
    input [7:0] wdata_3,
    input  rd_4,
    input [5:0] raddr_4,
    output [7:0] rdata_4,
    input  rd_5,
    input [5:0] raddr_5,
    output [7:0] rdata_5,
    // DFT
    //
    input clk
);
    wire [118:0]  unused;
    wire unused_ok;
    assign unused_ok = |unused;

    typedef struct packed {
        logic [2:0] waddr;
        logic [2:0] raddr;
        logic  wr;
        logic [8:0] wdata;
        logic  rd;
        logic [8:0] rdata;
    }   sram_io_t;

    //==========================================================================
    //  SRAM instance
    //--------------------------------------------------------------------------
        // in rewiring
            //  -   data
            wire [8:0] data_in_0;
            assign data_in_0[7:0] = wdata_0;
            wire [8:0] data_in_1;
            assign data_in_1[7:0] = wdata_1;
            wire [8:0] data_in_2;
            assign data_in_2[7:0] = wdata_2;
            wire [8:0] data_in_3;
            assign data_in_3[7:0] = wdata_3;
            
        // in stage0 
            wire  rd_from_inp0_0; 
            wire [5:0] raddr_from_inp0_0; 
            wire  wr_from_inp0_0; 
            wire [5:0] waddr_from_inp0_0; 
            wire [8:0] data_in_from_inp0_0;
            test_mem_a_pipe #(.WIDTH(23), .PIPE_STAGES(1)) in_stage0_0 (
                .d({rd_0, raddr_0, wr_0, waddr_0, data_in_0}),
                .q({rd_from_inp0_0, raddr_from_inp0_0, wr_from_inp0_0, waddr_from_inp0_0, data_in_from_inp0_0}),
                .clk(clk)
            ); 
            wire  rd_from_inp0_1; 
            wire [5:0] raddr_from_inp0_1; 
            wire  wr_from_inp0_1; 
            wire [5:0] waddr_from_inp0_1; 
            wire [8:0] data_in_from_inp0_1;
            test_mem_a_pipe #(.WIDTH(23), .PIPE_STAGES(1)) in_stage0_1 (
                .d({rd_1, raddr_1, wr_1, waddr_1, data_in_1}),
                .q({rd_from_inp0_1, raddr_from_inp0_1, wr_from_inp0_1, waddr_from_inp0_1, data_in_from_inp0_1}),
                .clk(clk)
            ); 
            wire  rd_from_inp0_2; 
            wire [5:0] raddr_from_inp0_2; 
            wire  wr_from_inp0_2; 
            wire [5:0] waddr_from_inp0_2; 
            wire [8:0] data_in_from_inp0_2;
            test_mem_a_pipe #(.WIDTH(23), .PIPE_STAGES(1)) in_stage0_2 (
                .d({rd_2, raddr_2, wr_2, waddr_2, data_in_2}),
                .q({rd_from_inp0_2, raddr_from_inp0_2, wr_from_inp0_2, waddr_from_inp0_2, data_in_from_inp0_2}),
                .clk(clk)
            ); 
            wire  rd_from_inp0_3; 
            wire [5:0] raddr_from_inp0_3; 
            wire  wr_from_inp0_3; 
            wire [5:0] waddr_from_inp0_3; 
            wire [8:0] data_in_from_inp0_3;
            test_mem_a_pipe #(.WIDTH(23), .PIPE_STAGES(1)) in_stage0_3 (
                .d({rd_3, raddr_3, wr_3, waddr_3, data_in_3}),
                .q({rd_from_inp0_3, raddr_from_inp0_3, wr_from_inp0_3, waddr_from_inp0_3, data_in_from_inp0_3}),
                .clk(clk)
            ); 
            wire  rd_from_inp0_4; 
            wire [5:0] raddr_from_inp0_4;
            test_mem_a_pipe #(.WIDTH(7), .PIPE_STAGES(1)) in_stage0_4 (
                .d({rd_4, raddr_4}),
                .q({rd_from_inp0_4, raddr_from_inp0_4}),
        .clk(clk)
    );
            wire  rd_from_inp0_5; 
            wire [5:0] raddr_from_inp0_5;
            test_mem_a_pipe #(.WIDTH(7), .PIPE_STAGES(1)) in_stage0_5 (
                .d({rd_5, raddr_5}),
                .q({rd_from_inp0_5, raddr_from_inp0_5}),
                .clk(clk)
            );
        // addr decoder
            wire [7:0]    raddr_decoder[5:0];
            wire [7:0]    waddr_decoder[3:0];
            assign raddr_decoder[0] = 1'b1 << raddr_from_inp0_0[5:3];
            assign raddr_decoder[1] = 1'b1 << raddr_from_inp0_1[5:3];
            assign raddr_decoder[2] = 1'b1 << raddr_from_inp0_2[5:3];
            assign raddr_decoder[3] = 1'b1 << raddr_from_inp0_3[5:3];
            assign raddr_decoder[4] = 1'b1 << raddr_from_inp0_4[5:3];
            assign raddr_decoder[5] = 1'b1 << raddr_from_inp0_5[5:3];
            assign waddr_decoder[0] = 1'b1 << waddr_from_inp0_0[5:3];
            assign waddr_decoder[1] = 1'b1 << waddr_from_inp0_1[5:3];
            assign waddr_decoder[2] = 1'b1 << waddr_from_inp0_2[5:3];
            assign waddr_decoder[3] = 1'b1 << waddr_from_inp0_3[5:3];
        // ctrl bits
            wire [7:0] rd_ctrl;
            wire [7:0] wr_ctrl;
            assign rd_ctrl =(raddr_decoder[0] & { 8{rd_from_inp0_0} }) | (raddr_decoder[1] & { 8{rd_from_inp0_1} }) | (raddr_decoder[2] & { 8{rd_from_inp0_2} }) | (raddr_decoder[3] & { 8{rd_from_inp0_3} }) | (raddr_decoder[4] & { 8{rd_from_inp0_4} }) | (raddr_decoder[5] & { 8{rd_from_inp0_5} }) ;
            assign wr_ctrl =(waddr_decoder[0] & { 8{wr_from_inp0_0} }) | (waddr_decoder[1] & { 8{wr_from_inp0_1} }) | (waddr_decoder[2] & { 8{wr_from_inp0_2} }) | (waddr_decoder[3] & { 8{wr_from_inp0_3} }) ;
        // ctrl/addr/data mux
            sram_io_t     sram_io [7:0];
            assign sram_io[0].rd = rd_ctrl[0];
            assign sram_io[0].wr = wr_ctrl[0];
            assign sram_io[0].raddr =
                raddr_decoder[0][0] ? raddr_from_inp0_0[2:0] :
                raddr_decoder[1][0] ? raddr_from_inp0_1[2:0] :
                raddr_decoder[2][0] ? raddr_from_inp0_2[2:0] :
                raddr_decoder[3][0] ? raddr_from_inp0_3[2:0] :
                raddr_decoder[4][0] ? raddr_from_inp0_4[2:0] :
                raddr_decoder[5][0] ? raddr_from_inp0_5[2:0] :
                'x;
            assign sram_io[0].waddr =
                waddr_decoder[0][0] ? waddr_from_inp0_0[2:0] :
                waddr_decoder[1][0] ? waddr_from_inp0_1[2:0] :
                waddr_decoder[2][0] ? waddr_from_inp0_2[2:0] :
                waddr_decoder[3][0] ? waddr_from_inp0_3[2:0] :
                'x;
            assign sram_io[0].wdata =
                waddr_decoder[0][0] ? data_in_from_inp0_0 :
                waddr_decoder[1][0] ? data_in_from_inp0_1 :
                waddr_decoder[2][0] ? data_in_from_inp0_2 :
                waddr_decoder[3][0] ? data_in_from_inp0_3 :
                'x;
            assign sram_io[1].rd = rd_ctrl[1];
            assign sram_io[1].wr = wr_ctrl[1];
            assign sram_io[1].raddr =
                raddr_decoder[0][1] ? raddr_from_inp0_0[2:0] :
                raddr_decoder[1][1] ? raddr_from_inp0_1[2:0] :
                raddr_decoder[2][1] ? raddr_from_inp0_2[2:0] :
                raddr_decoder[3][1] ? raddr_from_inp0_3[2:0] :
                raddr_decoder[4][1] ? raddr_from_inp0_4[2:0] :
                raddr_decoder[5][1] ? raddr_from_inp0_5[2:0] :
                'x;
            assign sram_io[1].waddr =
                waddr_decoder[0][1] ? waddr_from_inp0_0[2:0] :
                waddr_decoder[1][1] ? waddr_from_inp0_1[2:0] :
                waddr_decoder[2][1] ? waddr_from_inp0_2[2:0] :
                waddr_decoder[3][1] ? waddr_from_inp0_3[2:0] :
                'x;
            assign sram_io[1].wdata =
                waddr_decoder[0][1] ? data_in_from_inp0_0 :
                waddr_decoder[1][1] ? data_in_from_inp0_1 :
                waddr_decoder[2][1] ? data_in_from_inp0_2 :
                waddr_decoder[3][1] ? data_in_from_inp0_3 :
                'x;
            assign sram_io[2].rd = rd_ctrl[2];
            assign sram_io[2].wr = wr_ctrl[2];
            assign sram_io[2].raddr =
                raddr_decoder[0][2] ? raddr_from_inp0_0[2:0] :
                raddr_decoder[1][2] ? raddr_from_inp0_1[2:0] :
                raddr_decoder[2][2] ? raddr_from_inp0_2[2:0] :
                raddr_decoder[3][2] ? raddr_from_inp0_3[2:0] :
                raddr_decoder[4][2] ? raddr_from_inp0_4[2:0] :
                raddr_decoder[5][2] ? raddr_from_inp0_5[2:0] :
                'x;
            assign sram_io[2].waddr =
                waddr_decoder[0][2] ? waddr_from_inp0_0[2:0] :
                waddr_decoder[1][2] ? waddr_from_inp0_1[2:0] :
                waddr_decoder[2][2] ? waddr_from_inp0_2[2:0] :
                waddr_decoder[3][2] ? waddr_from_inp0_3[2:0] :
                'x;
            assign sram_io[2].wdata =
                waddr_decoder[0][2] ? data_in_from_inp0_0 :
                waddr_decoder[1][2] ? data_in_from_inp0_1 :
                waddr_decoder[2][2] ? data_in_from_inp0_2 :
                waddr_decoder[3][2] ? data_in_from_inp0_3 :
                'x;
            assign sram_io[3].rd = rd_ctrl[3];
            assign sram_io[3].wr = wr_ctrl[3];
            assign sram_io[3].raddr =
                raddr_decoder[0][3] ? raddr_from_inp0_0[2:0] :
                raddr_decoder[1][3] ? raddr_from_inp0_1[2:0] :
                raddr_decoder[2][3] ? raddr_from_inp0_2[2:0] :
                raddr_decoder[3][3] ? raddr_from_inp0_3[2:0] :
                raddr_decoder[4][3] ? raddr_from_inp0_4[2:0] :
                raddr_decoder[5][3] ? raddr_from_inp0_5[2:0] :
                'x;
            assign sram_io[3].waddr =
                waddr_decoder[0][3] ? waddr_from_inp0_0[2:0] :
                waddr_decoder[1][3] ? waddr_from_inp0_1[2:0] :
                waddr_decoder[2][3] ? waddr_from_inp0_2[2:0] :
                waddr_decoder[3][3] ? waddr_from_inp0_3[2:0] :
                'x;
            assign sram_io[3].wdata =
                waddr_decoder[0][3] ? data_in_from_inp0_0 :
                waddr_decoder[1][3] ? data_in_from_inp0_1 :
                waddr_decoder[2][3] ? data_in_from_inp0_2 :
                waddr_decoder[3][3] ? data_in_from_inp0_3 :
                'x;
            assign sram_io[4].rd = rd_ctrl[4];
            assign sram_io[4].wr = wr_ctrl[4];
            assign sram_io[4].raddr =
                raddr_decoder[0][4] ? raddr_from_inp0_0[2:0] :
                raddr_decoder[1][4] ? raddr_from_inp0_1[2:0] :
                raddr_decoder[2][4] ? raddr_from_inp0_2[2:0] :
                raddr_decoder[3][4] ? raddr_from_inp0_3[2:0] :
                raddr_decoder[4][4] ? raddr_from_inp0_4[2:0] :
                raddr_decoder[5][4] ? raddr_from_inp0_5[2:0] :
                'x;
            assign sram_io[4].waddr =
                waddr_decoder[0][4] ? waddr_from_inp0_0[2:0] :
                waddr_decoder[1][4] ? waddr_from_inp0_1[2:0] :
                waddr_decoder[2][4] ? waddr_from_inp0_2[2:0] :
                waddr_decoder[3][4] ? waddr_from_inp0_3[2:0] :
                'x;
            assign sram_io[4].wdata =
                waddr_decoder[0][4] ? data_in_from_inp0_0 :
                waddr_decoder[1][4] ? data_in_from_inp0_1 :
                waddr_decoder[2][4] ? data_in_from_inp0_2 :
                waddr_decoder[3][4] ? data_in_from_inp0_3 :
                'x;
            assign sram_io[5].rd = rd_ctrl[5];
            assign sram_io[5].wr = wr_ctrl[5];
            assign sram_io[5].raddr =
                raddr_decoder[0][5] ? raddr_from_inp0_0[2:0] :
                raddr_decoder[1][5] ? raddr_from_inp0_1[2:0] :
                raddr_decoder[2][5] ? raddr_from_inp0_2[2:0] :
                raddr_decoder[3][5] ? raddr_from_inp0_3[2:0] :
                raddr_decoder[4][5] ? raddr_from_inp0_4[2:0] :
                raddr_decoder[5][5] ? raddr_from_inp0_5[2:0] :
                'x;
            assign sram_io[5].waddr =
                waddr_decoder[0][5] ? waddr_from_inp0_0[2:0] :
                waddr_decoder[1][5] ? waddr_from_inp0_1[2:0] :
                waddr_decoder[2][5] ? waddr_from_inp0_2[2:0] :
                waddr_decoder[3][5] ? waddr_from_inp0_3[2:0] :
                'x;
            assign sram_io[5].wdata =
                waddr_decoder[0][5] ? data_in_from_inp0_0 :
                waddr_decoder[1][5] ? data_in_from_inp0_1 :
                waddr_decoder[2][5] ? data_in_from_inp0_2 :
                waddr_decoder[3][5] ? data_in_from_inp0_3 :
                'x;
            assign sram_io[6].rd = rd_ctrl[6];
            assign sram_io[6].wr = wr_ctrl[6];
            assign sram_io[6].raddr =
                raddr_decoder[0][6] ? raddr_from_inp0_0[2:0] :
                raddr_decoder[1][6] ? raddr_from_inp0_1[2:0] :
                raddr_decoder[2][6] ? raddr_from_inp0_2[2:0] :
                raddr_decoder[3][6] ? raddr_from_inp0_3[2:0] :
                raddr_decoder[4][6] ? raddr_from_inp0_4[2:0] :
                raddr_decoder[5][6] ? raddr_from_inp0_5[2:0] :
                'x;
            assign sram_io[6].waddr =
                waddr_decoder[0][6] ? waddr_from_inp0_0[2:0] :
                waddr_decoder[1][6] ? waddr_from_inp0_1[2:0] :
                waddr_decoder[2][6] ? waddr_from_inp0_2[2:0] :
                waddr_decoder[3][6] ? waddr_from_inp0_3[2:0] :
                'x;
            assign sram_io[6].wdata =
                waddr_decoder[0][6] ? data_in_from_inp0_0 :
                waddr_decoder[1][6] ? data_in_from_inp0_1 :
                waddr_decoder[2][6] ? data_in_from_inp0_2 :
                waddr_decoder[3][6] ? data_in_from_inp0_3 :
                'x;
            assign sram_io[7].rd = rd_ctrl[7];
            assign sram_io[7].wr = wr_ctrl[7];
            assign sram_io[7].raddr =
                raddr_decoder[0][7] ? raddr_from_inp0_0[2:0] :
                raddr_decoder[1][7] ? raddr_from_inp0_1[2:0] :
                raddr_decoder[2][7] ? raddr_from_inp0_2[2:0] :
                raddr_decoder[3][7] ? raddr_from_inp0_3[2:0] :
                raddr_decoder[4][7] ? raddr_from_inp0_4[2:0] :
                raddr_decoder[5][7] ? raddr_from_inp0_5[2:0] :
                'x;
            assign sram_io[7].waddr =
                waddr_decoder[0][7] ? waddr_from_inp0_0[2:0] :
                waddr_decoder[1][7] ? waddr_from_inp0_1[2:0] :
                waddr_decoder[2][7] ? waddr_from_inp0_2[2:0] :
                waddr_decoder[3][7] ? waddr_from_inp0_3[2:0] :
                'x;
            assign sram_io[7].wdata =
                waddr_decoder[0][7] ? data_in_from_inp0_0 :
                waddr_decoder[1][7] ? data_in_from_inp0_1 :
                waddr_decoder[2][7] ? data_in_from_inp0_2 :
                waddr_decoder[3][7] ? data_in_from_inp0_3 :
                'x;
        

    //==========================================================================
    // Read pipeline
    //--------------------------------------------------------------------------
        // sram
        `gumi_sadglsph4s2p768x16m4b8w0c1p0d0r1s10 u_mem_0_0 (
            //  PORT_A
            //  --
            //   - output
            //   - input
            .WEA('1),
            .DA({7'b0, sram_io[0].wdata[8:0]}),
            .CLKA(clk),
            .MEA(sram_io[0].wr),
            .ADRA({7'b0, sram_io[0].waddr}),
            //  PORT_B
            //  --
            //   - output
            .QPB({unused[6:0], sram_io[0].rdata[8:0]}),
            //   - input
            .PIPEMEB('1),
            .CLKB(clk),
            .MEB(sram_io[0].rd),
            .ADRB({7'b0, sram_io[0].raddr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sadglsph4s2p768x16m4b8w0c1p0d0r1s10 u_mem_1_0 (
            //  PORT_A
            //  --
            //   - output
            //   - input
            .WEA('1),
            .DA({7'b0, sram_io[1].wdata[8:0]}),
            .CLKA(clk),
            .MEA(sram_io[1].wr),
            .ADRA({7'b0, sram_io[1].waddr}),
            //  PORT_B
            //  --
            //   - output
            .QPB({unused[13:7], sram_io[1].rdata[8:0]}),
            //   - input
            .PIPEMEB('1),
            .CLKB(clk),
            .MEB(sram_io[1].rd),
            .ADRB({7'b0, sram_io[1].raddr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sadglsph4s2p768x16m4b8w0c1p0d0r1s10 u_mem_2_0 (
            //  PORT_A
            //  --
            //   - output
            //   - input
            .WEA('1),
            .DA({7'b0, sram_io[2].wdata[8:0]}),
            .CLKA(clk),
            .MEA(sram_io[2].wr),
            .ADRA({7'b0, sram_io[2].waddr}),
            //  PORT_B
            //  --
            //   - output
            .QPB({unused[20:14], sram_io[2].rdata[8:0]}),
            //   - input
            .PIPEMEB('1),
            .CLKB(clk),
            .MEB(sram_io[2].rd),
            .ADRB({7'b0, sram_io[2].raddr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sadglsph4s2p768x16m4b8w0c1p0d0r1s10 u_mem_3_0 (
            //  PORT_A
            //  --
            //   - output
            //   - input
            .WEA('1),
            .DA({7'b0, sram_io[3].wdata[8:0]}),
            .CLKA(clk),
            .MEA(sram_io[3].wr),
            .ADRA({7'b0, sram_io[3].waddr}),
            //  PORT_B
            //  --
            //   - output
            .QPB({unused[27:21], sram_io[3].rdata[8:0]}),
            //   - input
            .PIPEMEB('1),
            .CLKB(clk),
            .MEB(sram_io[3].rd),
            .ADRB({7'b0, sram_io[3].raddr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sadglsph4s2p768x16m4b8w0c1p0d0r1s10 u_mem_4_0 (
            //  PORT_A
            //  --
            //   - output
            //   - input
            .WEA('1),
            .DA({7'b0, sram_io[4].wdata[8:0]}),
            .CLKA(clk),
            .MEA(sram_io[4].wr),
            .ADRA({7'b0, sram_io[4].waddr}),
            //  PORT_B
            //  --
            //   - output
            .QPB({unused[34:28], sram_io[4].rdata[8:0]}),
            //   - input
            .PIPEMEB('1),
            .CLKB(clk),
            .MEB(sram_io[4].rd),
            .ADRB({7'b0, sram_io[4].raddr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sadglsph4s2p768x16m4b8w0c1p0d0r1s10 u_mem_5_0 (
            //  PORT_A
            //  --
            //   - output
            //   - input
            .WEA('1),
            .DA({7'b0, sram_io[5].wdata[8:0]}),
            .CLKA(clk),
            .MEA(sram_io[5].wr),
            .ADRA({7'b0, sram_io[5].waddr}),
            //  PORT_B
            //  --
            //   - output
            .QPB({unused[41:35], sram_io[5].rdata[8:0]}),
            //   - input
            .PIPEMEB('1),
            .CLKB(clk),
            .MEB(sram_io[5].rd),
            .ADRB({7'b0, sram_io[5].raddr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sadglsph4s2p768x16m4b8w0c1p0d0r1s10 u_mem_6_0 (
            //  PORT_A
            //  --
            //   - output
            //   - input
            .WEA('1),
            .DA({7'b0, sram_io[6].wdata[8:0]}),
            .CLKA(clk),
            .MEA(sram_io[6].wr),
            .ADRA({7'b0, sram_io[6].waddr}),
            //  PORT_B
            //  --
            //   - output
            .QPB({unused[48:42], sram_io[6].rdata[8:0]}),
            //   - input
            .PIPEMEB('1),
            .CLKB(clk),
            .MEB(sram_io[6].rd),
            .ADRB({7'b0, sram_io[6].raddr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sadglsph4s2p768x16m4b8w0c1p0d0r1s10 u_mem_7_0 (
            //  PORT_A
            //  --
            //   - output
            //   - input
            .WEA('1),
            .DA({7'b0, sram_io[7].wdata[8:0]}),
            .CLKA(clk),
            .MEA(sram_io[7].wr),
            .ADRA({7'b0, sram_io[7].waddr}),
            //  PORT_B
            //  --
            //   - output
            .QPB({unused[55:49], sram_io[7].rdata[8:0]}),
            //   - input
            .PIPEMEB('1),
            .CLKB(clk),
            .MEB(sram_io[7].rd),
            .ADRB({7'b0, sram_io[7].raddr}),
            //  light sleep
            .LS(1'b0)
        );

    //==========================================================================
    // Read out pipeline
    //--------------------------------------------------------------------------
        // rd_sel_pipe
            wire [2:0]   rd_sel_0;
            test_mem_a_pipe #(.WIDTH(3), .PIPE_STAGES(1+1+0)) rd_sel_pipe_0 (
                .d(raddr_from_inp0_0[5:3]),
                .q(rd_sel_0),
        .clk(clk)
    );
            wire [2:0]   rd_sel_1;
            test_mem_a_pipe #(.WIDTH(3), .PIPE_STAGES(1+1+0)) rd_sel_pipe_1 (
                .d(raddr_from_inp0_1[5:3]),
                .q(rd_sel_1),
                .clk(clk)
            );
            wire [2:0]   rd_sel_2;
            test_mem_a_pipe #(.WIDTH(3), .PIPE_STAGES(1+1+0)) rd_sel_pipe_2 (
                .d(raddr_from_inp0_2[5:3]),
                .q(rd_sel_2),
                .clk(clk)
            );
            wire [2:0]   rd_sel_3;
            test_mem_a_pipe #(.WIDTH(3), .PIPE_STAGES(1+1+0)) rd_sel_pipe_3 (
                .d(raddr_from_inp0_3[5:3]),
                .q(rd_sel_3),
                .clk(clk)
            );
            wire [2:0]   rd_sel_4;
            test_mem_a_pipe #(.WIDTH(3), .PIPE_STAGES(1+1+0)) rd_sel_pipe_4 (
                .d(raddr_from_inp0_4[5:3]),
                .q(rd_sel_4),
                .clk(clk)
            );
            wire [2:0]   rd_sel_5;
            test_mem_a_pipe #(.WIDTH(3), .PIPE_STAGES(1+1+0)) rd_sel_pipe_5 (
                .d(raddr_from_inp0_5[5:3]),
                .q(rd_sel_5),
                .clk(clk)
            );
        // rd dout mux
            wire [8:0] data_to_oup0_0;
            assign data_to_oup0_0 = sram_io[rd_sel_0].rdata;
            wire [8:0] data_to_oup0_1;
            assign data_to_oup0_1 = sram_io[rd_sel_1].rdata;
            wire [8:0] data_to_oup0_2;
            assign data_to_oup0_2 = sram_io[rd_sel_2].rdata;
            wire [8:0] data_to_oup0_3;
            assign data_to_oup0_3 = sram_io[rd_sel_3].rdata;
            wire [8:0] data_to_oup0_4;
            assign data_to_oup0_4 = sram_io[rd_sel_4].rdata;
            wire [8:0] data_to_oup0_5;
            assign data_to_oup0_5 = sram_io[rd_sel_5].rdata;
        //  out pipe 0
            wire [8:0] data_out_0;
            test_mem_a_pipe #(.WIDTH(9), .PIPE_STAGES(2-1)) pipe0_0 (
                .d(data_to_oup0_0),
                .q(data_out_0),
                .clk(clk)
            );
            wire [8:0] data_out_1;
            test_mem_a_pipe #(.WIDTH(9), .PIPE_STAGES(2-1)) pipe0_1 (
                .d(data_to_oup0_1),
                .q(data_out_1),
                .clk(clk)
            );
            wire [8:0] data_out_2;
            test_mem_a_pipe #(.WIDTH(9), .PIPE_STAGES(2-1)) pipe0_2 (
                .d(data_to_oup0_2),
                .q(data_out_2),
                .clk(clk)
            );
            wire [8:0] data_out_3;
            test_mem_a_pipe #(.WIDTH(9), .PIPE_STAGES(2-1)) pipe0_3 (
                .d(data_to_oup0_3),
                .q(data_out_3),
                .clk(clk)
            );
            wire [8:0] data_out_4;
            test_mem_a_pipe #(.WIDTH(9), .PIPE_STAGES(2-1)) pipe0_4 (
                .d(data_to_oup0_4),
                .q(data_out_4),
                .clk(clk)
            );
            wire [8:0] data_out_5;
            test_mem_a_pipe #(.WIDTH(9), .PIPE_STAGES(2-1)) pipe0_5 (
                .d(data_to_oup0_5),
                .q(data_out_5),
                .clk(clk)
            );
        //  out pipe 1
            wire [7:0] data_to_oup1_0;
            test_mem_a_pipe #(.WIDTH(8), .PIPE_STAGES(1)) pipe1_0 (
                .d(data_to_oup1_0),
                .q(rdata_0),
                .clk(clk)
            );
            wire [7:0] data_to_oup1_1;
            test_mem_a_pipe #(.WIDTH(8), .PIPE_STAGES(1)) pipe1_1 (
                .d(data_to_oup1_1),
                .q(rdata_1),
                .clk(clk)
            );
            wire [7:0] data_to_oup1_2;
            test_mem_a_pipe #(.WIDTH(8), .PIPE_STAGES(1)) pipe1_2 (
                .d(data_to_oup1_2),
                .q(rdata_2),
                .clk(clk)
            );
            wire [7:0] data_to_oup1_3;
            test_mem_a_pipe #(.WIDTH(8), .PIPE_STAGES(1)) pipe1_3 (
                .d(data_to_oup1_3),
                .q(rdata_3),
                .clk(clk)
            );
            wire [7:0] data_to_oup1_4;
            test_mem_a_pipe #(.WIDTH(8), .PIPE_STAGES(1)) pipe1_4 (
                .d(data_to_oup1_4),
                .q(rdata_4),
                .clk(clk)
            );
            wire [7:0] data_to_oup1_5;
            test_mem_a_pipe #(.WIDTH(8), .PIPE_STAGES(1)) pipe1_5 (
                .d(data_to_oup1_5),
                .q(rdata_5),
        .clk(clk)
    );

    //==========================================================================
    //  Protection
    //--------------------------------------------------------------------------
    //  Parity
    //  - gen -
            test_mem_a_m8_parity_gen u_gen_0 (
                .parity_to_sram(data_in_0[8:8]),
                .data_in(wdata_0)
            );
            test_mem_a_m8_parity_gen u_gen_1 (
                .parity_to_sram(data_in_1[8:8]),
                .data_in(wdata_1)
            );
            test_mem_a_m8_parity_gen u_gen_2 (
                .parity_to_sram(data_in_2[8:8]),
                .data_in(wdata_2)
            );
            test_mem_a_m8_parity_gen u_gen_3 (
                .parity_to_sram(data_in_3[8:8]),
                .data_in(wdata_3)
    );
    //  - chk -
            test_mem_a_m8_parity_chk u_chk_0 (
                .data_out(data_to_oup1_0),
                .err(),
                .parity_from_sram(data_out_0[8:8]),
                .data_from_sram(data_out_0[7:0])
            );
            test_mem_a_m8_parity_chk u_chk_1 (
                .data_out(data_to_oup1_1),
                .err(),
                .parity_from_sram(data_out_1[8:8]),
                .data_from_sram(data_out_1[7:0])
            );
            test_mem_a_m8_parity_chk u_chk_2 (
                .data_out(data_to_oup1_2),
        .err(),
                .parity_from_sram(data_out_2[8:8]),
                .data_from_sram(data_out_2[7:0])
            );
            test_mem_a_m8_parity_chk u_chk_3 (
                .data_out(data_to_oup1_3),
                .err(),
                .parity_from_sram(data_out_3[8:8]),
                .data_from_sram(data_out_3[7:0])
            );
            test_mem_a_m8_parity_chk u_chk_4 (
                .data_out(data_to_oup1_4),
                .err(),
                .parity_from_sram(data_out_4[8:8]),
                .data_from_sram(data_out_4[7:0])
            );
            test_mem_a_m8_parity_chk u_chk_5 (
                .data_out(data_to_oup1_5),
                .err(),
                .parity_from_sram(data_out_5[8:8]),
                .data_from_sram(data_out_5[7:0])
    );
    //  - hero -

    `ifdef TBV
        test_mem_a_pipe #(.WIDTH(1), .PIPE_STAGES(5)) rdata_vld_0 (
            .d(rd_0),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(6), .PIPE_STAGES(5)) raddr_pipe_0 (
            .d(raddr_0),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(1), .PIPE_STAGES(5)) rdata_vld_1 (
            .d(rd_1),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(6), .PIPE_STAGES(5)) raddr_pipe_1 (
            .d(raddr_1),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(1), .PIPE_STAGES(5)) rdata_vld_2 (
            .d(rd_2),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(6), .PIPE_STAGES(5)) raddr_pipe_2 (
            .d(raddr_2),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(1), .PIPE_STAGES(5)) rdata_vld_3 (
            .d(rd_3),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(6), .PIPE_STAGES(5)) raddr_pipe_3 (
            .d(raddr_3),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(1), .PIPE_STAGES(5)) rdata_vld_4 (
            .d(rd_4),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(6), .PIPE_STAGES(5)) raddr_pipe_4 (
            .d(raddr_4),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(1), .PIPE_STAGES(5)) rdata_vld_5 (
            .d(rd_5),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(6), .PIPE_STAGES(5)) raddr_pipe_5 (
            .d(raddr_5),
            .q(),
            .clk(clk)
        );
    `endif  //  TBV

endmodule : multiple_port_2p_mem


///////////////////////////////////////////////////////////////////////////////
// name: hero_fifo
// doc_summary: hero FIFO Memory

// width: 11  ==>  11
// depth: test_pkg_a::hero_write_t.width+18  ==>  64
// ports: 1p
// prot: ecc
// sram_cfg: sad2lsph4s1p784x16m4b1w0c1p0d0r3s10
// pipe0: 2
// pipe1: 1
// row: 8
// col: 1
// read_ports: 4
// write_ports: 6
// stage0: 0
// stage1: 1

module multiple_port_1p_mem(
    input  rd_0,
    input [5:0] raddr_0,
    output [10:0] rdata_0,
    input  wr_0,
    input [5:0] waddr_0,
    input [10:0] wdata_0,
    input  rd_1,
    input [5:0] raddr_1,
    output [10:0] rdata_1,
    input  wr_1,
    input [5:0] waddr_1,
    input [10:0] wdata_1,
    input  rd_2,
    input [5:0] raddr_2,
    output [10:0] rdata_2,
    input  wr_2,
    input [5:0] waddr_2,
    input [10:0] wdata_2,
    input  rd_3,
    input [5:0] raddr_3,
    output [10:0] rdata_3,
    input  wr_3,
    input [5:0] waddr_3,
    input [10:0] wdata_3,
    input  wr_4,
    input [5:0] waddr_4,
    input [10:0] wdata_4,
    input  wr_5,
    input [5:0] waddr_5,
    input [10:0] wdata_5,
    // DFT
    //
    input clk
);
    wire [111:0]  unused;
    wire unused_ok;
    assign unused_ok = |unused;

    typedef struct packed {
        logic [2:0] addr;
        logic  wr;
        logic [15:0] wdata;
        logic  rd;
        logic [15:0] rdata;
    }   sram_io_t;

    //==========================================================================
    //  SRAM instance
    //--------------------------------------------------------------------------
        // in rewiring
            //  -   data
            wire [15:0] data_in_0;
            assign data_in_0[10:0] = wdata_0;
            wire [15:0] data_in_1;
            assign data_in_1[10:0] = wdata_1;
            wire [15:0] data_in_2;
            assign data_in_2[10:0] = wdata_2;
            wire [15:0] data_in_3;
            assign data_in_3[10:0] = wdata_3;
            wire [15:0] data_in_4;
            assign data_in_4[10:0] = wdata_4;
            wire [15:0] data_in_5;
            assign data_in_5[10:0] = wdata_5;
            //  -   addr
            wire [5:0]  addr_0;
            assign addr_0 =wr_0 ? waddr_0 : raddr_0;
            wire [5:0]  addr_1;
            assign addr_1 =wr_1 ? waddr_1 : raddr_1;
            wire [5:0]  addr_2;
            assign addr_2 =wr_2 ? waddr_2 : raddr_2;
            wire [5:0]  addr_3;
            assign addr_3 =wr_3 ? waddr_3 : raddr_3;
            wire [5:0]  addr_4;
            assign addr_4 =waddr_4;
            wire [5:0]  addr_5;
            assign addr_5 =waddr_5;
        
        // addr decoder
            wire [7:0]    addr_decoder[5:0];
            assign addr_decoder[0] = 1'b1 << addr_0[5:3];
            assign addr_decoder[1] = 1'b1 << addr_1[5:3];
            assign addr_decoder[2] = 1'b1 << addr_2[5:3];
            assign addr_decoder[3] = 1'b1 << addr_3[5:3];
            assign addr_decoder[4] = 1'b1 << addr_4[5:3];
            assign addr_decoder[5] = 1'b1 << addr_5[5:3];
        // ctrl bits
            wire [7:0] rd_ctrl;
            wire [7:0] wr_ctrl;
            assign rd_ctrl =(addr_decoder[0] & { 8{rd_0} }) | (addr_decoder[1] & { 8{rd_1} }) | (addr_decoder[2] & { 8{rd_2} }) | (addr_decoder[3] & { 8{rd_3} }) ;
            assign wr_ctrl =(addr_decoder[0] & { 8{wr_0} }) | (addr_decoder[1] & { 8{wr_1} }) | (addr_decoder[2] & { 8{wr_2} }) | (addr_decoder[3] & { 8{wr_3} }) | (addr_decoder[4] & { 8{wr_4} }) | (addr_decoder[5] & { 8{wr_5} }) ;
        // ctrl/addr/data mux
            sram_io_t     sram_io_to_inp1 [7:0];
            assign sram_io_to_inp1[0].rd = rd_ctrl[0];
            assign sram_io_to_inp1[0].wr = wr_ctrl[0];
            assign sram_io_to_inp1[0].addr =
                addr_decoder[0][0] ? addr_0[2:0] :
                addr_decoder[1][0] ? addr_1[2:0] :
                addr_decoder[2][0] ? addr_2[2:0] :
                addr_decoder[3][0] ? addr_3[2:0] :
                addr_decoder[4][0] ? addr_4[2:0] :
                addr_decoder[5][0] ? addr_5[2:0] :
                'x;
            assign sram_io_to_inp1[0].wdata =
                addr_decoder[0][0] ? data_in_0 :
                addr_decoder[1][0] ? data_in_1 :
                addr_decoder[2][0] ? data_in_2 :
                addr_decoder[3][0] ? data_in_3 :
                addr_decoder[4][0] ? data_in_4 :
                addr_decoder[5][0] ? data_in_5 :
                'x;
            assign sram_io_to_inp1[1].rd = rd_ctrl[1];
            assign sram_io_to_inp1[1].wr = wr_ctrl[1];
            assign sram_io_to_inp1[1].addr =
                addr_decoder[0][1] ? addr_0[2:0] :
                addr_decoder[1][1] ? addr_1[2:0] :
                addr_decoder[2][1] ? addr_2[2:0] :
                addr_decoder[3][1] ? addr_3[2:0] :
                addr_decoder[4][1] ? addr_4[2:0] :
                addr_decoder[5][1] ? addr_5[2:0] :
                'x;
            assign sram_io_to_inp1[1].wdata =
                addr_decoder[0][1] ? data_in_0 :
                addr_decoder[1][1] ? data_in_1 :
                addr_decoder[2][1] ? data_in_2 :
                addr_decoder[3][1] ? data_in_3 :
                addr_decoder[4][1] ? data_in_4 :
                addr_decoder[5][1] ? data_in_5 :
                'x;
            assign sram_io_to_inp1[2].rd = rd_ctrl[2];
            assign sram_io_to_inp1[2].wr = wr_ctrl[2];
            assign sram_io_to_inp1[2].addr =
                addr_decoder[0][2] ? addr_0[2:0] :
                addr_decoder[1][2] ? addr_1[2:0] :
                addr_decoder[2][2] ? addr_2[2:0] :
                addr_decoder[3][2] ? addr_3[2:0] :
                addr_decoder[4][2] ? addr_4[2:0] :
                addr_decoder[5][2] ? addr_5[2:0] :
                'x;
            assign sram_io_to_inp1[2].wdata =
                addr_decoder[0][2] ? data_in_0 :
                addr_decoder[1][2] ? data_in_1 :
                addr_decoder[2][2] ? data_in_2 :
                addr_decoder[3][2] ? data_in_3 :
                addr_decoder[4][2] ? data_in_4 :
                addr_decoder[5][2] ? data_in_5 :
                'x;
            assign sram_io_to_inp1[3].rd = rd_ctrl[3];
            assign sram_io_to_inp1[3].wr = wr_ctrl[3];
            assign sram_io_to_inp1[3].addr =
                addr_decoder[0][3] ? addr_0[2:0] :
                addr_decoder[1][3] ? addr_1[2:0] :
                addr_decoder[2][3] ? addr_2[2:0] :
                addr_decoder[3][3] ? addr_3[2:0] :
                addr_decoder[4][3] ? addr_4[2:0] :
                addr_decoder[5][3] ? addr_5[2:0] :
                'x;
            assign sram_io_to_inp1[3].wdata =
                addr_decoder[0][3] ? data_in_0 :
                addr_decoder[1][3] ? data_in_1 :
                addr_decoder[2][3] ? data_in_2 :
                addr_decoder[3][3] ? data_in_3 :
                addr_decoder[4][3] ? data_in_4 :
                addr_decoder[5][3] ? data_in_5 :
                'x;
            assign sram_io_to_inp1[4].rd = rd_ctrl[4];
            assign sram_io_to_inp1[4].wr = wr_ctrl[4];
            assign sram_io_to_inp1[4].addr =
                addr_decoder[0][4] ? addr_0[2:0] :
                addr_decoder[1][4] ? addr_1[2:0] :
                addr_decoder[2][4] ? addr_2[2:0] :
                addr_decoder[3][4] ? addr_3[2:0] :
                addr_decoder[4][4] ? addr_4[2:0] :
                addr_decoder[5][4] ? addr_5[2:0] :
                'x;
            assign sram_io_to_inp1[4].wdata =
                addr_decoder[0][4] ? data_in_0 :
                addr_decoder[1][4] ? data_in_1 :
                addr_decoder[2][4] ? data_in_2 :
                addr_decoder[3][4] ? data_in_3 :
                addr_decoder[4][4] ? data_in_4 :
                addr_decoder[5][4] ? data_in_5 :
                'x;
            assign sram_io_to_inp1[5].rd = rd_ctrl[5];
            assign sram_io_to_inp1[5].wr = wr_ctrl[5];
            assign sram_io_to_inp1[5].addr =
                addr_decoder[0][5] ? addr_0[2:0] :
                addr_decoder[1][5] ? addr_1[2:0] :
                addr_decoder[2][5] ? addr_2[2:0] :
                addr_decoder[3][5] ? addr_3[2:0] :
                addr_decoder[4][5] ? addr_4[2:0] :
                addr_decoder[5][5] ? addr_5[2:0] :
                'x;
            assign sram_io_to_inp1[5].wdata =
                addr_decoder[0][5] ? data_in_0 :
                addr_decoder[1][5] ? data_in_1 :
                addr_decoder[2][5] ? data_in_2 :
                addr_decoder[3][5] ? data_in_3 :
                addr_decoder[4][5] ? data_in_4 :
                addr_decoder[5][5] ? data_in_5 :
                'x;
            assign sram_io_to_inp1[6].rd = rd_ctrl[6];
            assign sram_io_to_inp1[6].wr = wr_ctrl[6];
            assign sram_io_to_inp1[6].addr =
                addr_decoder[0][6] ? addr_0[2:0] :
                addr_decoder[1][6] ? addr_1[2:0] :
                addr_decoder[2][6] ? addr_2[2:0] :
                addr_decoder[3][6] ? addr_3[2:0] :
                addr_decoder[4][6] ? addr_4[2:0] :
                addr_decoder[5][6] ? addr_5[2:0] :
                'x;
            assign sram_io_to_inp1[6].wdata =
                addr_decoder[0][6] ? data_in_0 :
                addr_decoder[1][6] ? data_in_1 :
                addr_decoder[2][6] ? data_in_2 :
                addr_decoder[3][6] ? data_in_3 :
                addr_decoder[4][6] ? data_in_4 :
                addr_decoder[5][6] ? data_in_5 :
                'x;
            assign sram_io_to_inp1[7].rd = rd_ctrl[7];
            assign sram_io_to_inp1[7].wr = wr_ctrl[7];
            assign sram_io_to_inp1[7].addr =
                addr_decoder[0][7] ? addr_0[2:0] :
                addr_decoder[1][7] ? addr_1[2:0] :
                addr_decoder[2][7] ? addr_2[2:0] :
                addr_decoder[3][7] ? addr_3[2:0] :
                addr_decoder[4][7] ? addr_4[2:0] :
                addr_decoder[5][7] ? addr_5[2:0] :
                'x;
            assign sram_io_to_inp1[7].wdata =
                addr_decoder[0][7] ? data_in_0 :
                addr_decoder[1][7] ? data_in_1 :
                addr_decoder[2][7] ? data_in_2 :
                addr_decoder[3][7] ? data_in_3 :
                addr_decoder[4][7] ? data_in_4 :
                addr_decoder[5][7] ? data_in_5 :
                'x;
        // in stage1
            sram_io_t     sram_io [7:0];
            test_mem_a_pipe #(.WIDTH(37-16), .PIPE_STAGES(1)) in_stage1_0 (
                .d(sram_io_to_inp1[0][37-1:16]),
                .q(sram_io[0][37-1:16]),
                .clk(clk)
            );
            test_mem_a_pipe #(.WIDTH(37-16), .PIPE_STAGES(1)) in_stage1_1 (
                .d(sram_io_to_inp1[1][37-1:16]),
                .q(sram_io[1][37-1:16]),
                .clk(clk)
            );
            test_mem_a_pipe #(.WIDTH(37-16), .PIPE_STAGES(1)) in_stage1_2 (
                .d(sram_io_to_inp1[2][37-1:16]),
                .q(sram_io[2][37-1:16]),
                .clk(clk)
            );
            test_mem_a_pipe #(.WIDTH(37-16), .PIPE_STAGES(1)) in_stage1_3 (
                .d(sram_io_to_inp1[3][37-1:16]),
                .q(sram_io[3][37-1:16]),
                .clk(clk)
            );
            test_mem_a_pipe #(.WIDTH(37-16), .PIPE_STAGES(1)) in_stage1_4 (
                .d(sram_io_to_inp1[4][37-1:16]),
                .q(sram_io[4][37-1:16]),
                .clk(clk)
            );
            test_mem_a_pipe #(.WIDTH(37-16), .PIPE_STAGES(1)) in_stage1_5 (
                .d(sram_io_to_inp1[5][37-1:16]),
                .q(sram_io[5][37-1:16]),
                .clk(clk)
            );
            test_mem_a_pipe #(.WIDTH(37-16), .PIPE_STAGES(1)) in_stage1_6 (
                .d(sram_io_to_inp1[6][37-1:16]),
                .q(sram_io[6][37-1:16]),
                .clk(clk)
            );
            test_mem_a_pipe #(.WIDTH(37-16), .PIPE_STAGES(1)) in_stage1_7 (
                .d(sram_io_to_inp1[7][37-1:16]),
                .q(sram_io[7][37-1:16]),
        .clk(clk)
    );

    //==========================================================================
    // Read pipeline
    //--------------------------------------------------------------------------
        // sram
        `gumi_sad2lsph4s1p784x16m4b1w0c1p0d0r3s10 u_mem_0_0 (
            //  PORT_
            //  --
            //   - output
            .QP(sram_io[0].rdata[15:0]),
            //   - input
            .PIPEME('1),
            //   - input
            .WE(sram_io[0].wr),
            .D(sram_io[0].wdata[15:0]),
            .CLK(clk),
            .ME(sram_io[0].wr | sram_io[0].rd),
            .ADR({7'b0, sram_io[0].addr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sad2lsph4s1p784x16m4b1w0c1p0d0r3s10 u_mem_1_0 (
            //  PORT_
            //  --
            //   - output
            .QP(sram_io[1].rdata[15:0]),
            //   - input
            .PIPEME('1),
            //   - input
            .WE(sram_io[1].wr),
            .D(sram_io[1].wdata[15:0]),
            .CLK(clk),
            .ME(sram_io[1].wr | sram_io[1].rd),
            .ADR({7'b0, sram_io[1].addr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sad2lsph4s1p784x16m4b1w0c1p0d0r3s10 u_mem_2_0 (
            //  PORT_
            //  --
            //   - output
            .QP(sram_io[2].rdata[15:0]),
            //   - input
            .PIPEME('1),
            //   - input
            .WE(sram_io[2].wr),
            .D(sram_io[2].wdata[15:0]),
            .CLK(clk),
            .ME(sram_io[2].wr | sram_io[2].rd),
            .ADR({7'b0, sram_io[2].addr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sad2lsph4s1p784x16m4b1w0c1p0d0r3s10 u_mem_3_0 (
            //  PORT_
            //  --
            //   - output
            .QP(sram_io[3].rdata[15:0]),
            //   - input
            .PIPEME('1),
            //   - input
            .WE(sram_io[3].wr),
            .D(sram_io[3].wdata[15:0]),
            .CLK(clk),
            .ME(sram_io[3].wr | sram_io[3].rd),
            .ADR({7'b0, sram_io[3].addr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sad2lsph4s1p784x16m4b1w0c1p0d0r3s10 u_mem_4_0 (
            //  PORT_
            //  --
            //   - output
            .QP(sram_io[4].rdata[15:0]),
            //   - input
            .PIPEME('1),
            //   - input
            .WE(sram_io[4].wr),
            .D(sram_io[4].wdata[15:0]),
            .CLK(clk),
            .ME(sram_io[4].wr | sram_io[4].rd),
            .ADR({7'b0, sram_io[4].addr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sad2lsph4s1p784x16m4b1w0c1p0d0r3s10 u_mem_5_0 (
            //  PORT_
            //  --
            //   - output
            .QP(sram_io[5].rdata[15:0]),
            //   - input
            .PIPEME('1),
            //   - input
            .WE(sram_io[5].wr),
            .D(sram_io[5].wdata[15:0]),
            .CLK(clk),
            .ME(sram_io[5].wr | sram_io[5].rd),
            .ADR({7'b0, sram_io[5].addr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sad2lsph4s1p784x16m4b1w0c1p0d0r3s10 u_mem_6_0 (
            //  PORT_
            //  --
            //   - output
            .QP(sram_io[6].rdata[15:0]),
            //   - input
            .PIPEME('1),
            //   - input
            .WE(sram_io[6].wr),
            .D(sram_io[6].wdata[15:0]),
            .CLK(clk),
            .ME(sram_io[6].wr | sram_io[6].rd),
            .ADR({7'b0, sram_io[6].addr}),
            //  light sleep
            .LS(1'b0)
        );
        // sram
        `gumi_sad2lsph4s1p784x16m4b1w0c1p0d0r3s10 u_mem_7_0 (
            //  PORT_
            //  --
            //   - output
            .QP(sram_io[7].rdata[15:0]),
            //   - input
            .PIPEME('1),
            //   - input
            .WE(sram_io[7].wr),
            .D(sram_io[7].wdata[15:0]),
            .CLK(clk),
            .ME(sram_io[7].wr | sram_io[7].rd),
            .ADR({7'b0, sram_io[7].addr}),
            //  light sleep
            .LS(1'b0)
        );

    //==========================================================================
    // Read out pipeline
    //--------------------------------------------------------------------------
        // rd_sel_pipe
            wire [2:0]   rd_sel_0;
            test_mem_a_pipe #(.WIDTH(3), .PIPE_STAGES(1+1+1)) rd_sel_pipe_0 (
                .d(addr_0[5:3]),
                .q(rd_sel_0),
        .clk(clk)
    );
            wire [2:0]   rd_sel_1;
            test_mem_a_pipe #(.WIDTH(3), .PIPE_STAGES(1+1+1)) rd_sel_pipe_1 (
                .d(addr_1[5:3]),
                .q(rd_sel_1),
                .clk(clk)
            );
            wire [2:0]   rd_sel_2;
            test_mem_a_pipe #(.WIDTH(3), .PIPE_STAGES(1+1+1)) rd_sel_pipe_2 (
                .d(addr_2[5:3]),
                .q(rd_sel_2),
                .clk(clk)
            );
            wire [2:0]   rd_sel_3;
            test_mem_a_pipe #(.WIDTH(3), .PIPE_STAGES(1+1+1)) rd_sel_pipe_3 (
                .d(addr_3[5:3]),
                .q(rd_sel_3),
                .clk(clk)
            );
        // rd dout mux
            wire [15:0] data_to_oup0_0;
            assign data_to_oup0_0 = sram_io[rd_sel_0].rdata;
            wire [15:0] data_to_oup0_1;
            assign data_to_oup0_1 = sram_io[rd_sel_1].rdata;
            wire [15:0] data_to_oup0_2;
            assign data_to_oup0_2 = sram_io[rd_sel_2].rdata;
            wire [15:0] data_to_oup0_3;
            assign data_to_oup0_3 = sram_io[rd_sel_3].rdata;
        //  out pipe 0
            wire [15:0] data_out_0;
            test_mem_a_pipe #(.WIDTH(16), .PIPE_STAGES(2-1)) pipe0_0 (
                .d(data_to_oup0_0),
                .q(data_out_0),
                .clk(clk)
            );
            wire [15:0] data_out_1;
            test_mem_a_pipe #(.WIDTH(16), .PIPE_STAGES(2-1)) pipe0_1 (
                .d(data_to_oup0_1),
                .q(data_out_1),
                .clk(clk)
            );
            wire [15:0] data_out_2;
            test_mem_a_pipe #(.WIDTH(16), .PIPE_STAGES(2-1)) pipe0_2 (
                .d(data_to_oup0_2),
                .q(data_out_2),
                .clk(clk)
            );
            wire [15:0] data_out_3;
            test_mem_a_pipe #(.WIDTH(16), .PIPE_STAGES(2-1)) pipe0_3 (
                .d(data_to_oup0_3),
                .q(data_out_3),
                .clk(clk)
            );
        //  out pipe 1
            wire [10:0] data_to_oup1_0;
            test_mem_a_pipe #(.WIDTH(11), .PIPE_STAGES(1)) pipe1_0 (
                .d(data_to_oup1_0),
                .q(rdata_0),
                .clk(clk)
            );
            wire [10:0] data_to_oup1_1;
            test_mem_a_pipe #(.WIDTH(11), .PIPE_STAGES(1)) pipe1_1 (
                .d(data_to_oup1_1),
                .q(rdata_1),
                .clk(clk)
            );
            wire [10:0] data_to_oup1_2;
            test_mem_a_pipe #(.WIDTH(11), .PIPE_STAGES(1)) pipe1_2 (
                .d(data_to_oup1_2),
                .q(rdata_2),
        .clk(clk)
    );
            wire [10:0] data_to_oup1_3;
            test_mem_a_pipe #(.WIDTH(11), .PIPE_STAGES(1)) pipe1_3 (
                .d(data_to_oup1_3),
                .q(rdata_3),
                .clk(clk)
            );

    //==========================================================================
    //  Protection
    //--------------------------------------------------------------------------
        //  Ecc
        //  - gen -
            test_mem_a_m11_ecc_gen u_gen_0 (
                .ecc_to_sram(data_in_0[15:11]),
                .data_in(wdata_0)
            );
            test_mem_a_m11_ecc_gen u_gen_1 (
                .ecc_to_sram(data_in_1[15:11]),
                .data_in(wdata_1)
            );
            test_mem_a_m11_ecc_gen u_gen_2 (
                .ecc_to_sram(data_in_2[15:11]),
                .data_in(wdata_2)
            );
            test_mem_a_m11_ecc_gen u_gen_3 (
                .ecc_to_sram(data_in_3[15:11]),
                .data_in(wdata_3)
            );
            test_mem_a_m11_ecc_gen u_gen_4 (
                .ecc_to_sram(data_in_4[15:11]),
                .data_in(wdata_4)
            );
            test_mem_a_m11_ecc_gen u_gen_5 (
                .ecc_to_sram(data_in_5[15:11]),
                .data_in(wdata_5)
            );
        //  - chk -
            test_mem_a_m11_ecc_chk u_chk_0 (
                .data_out(data_to_oup1_0),
                .single_bit_err(),
                .double_bit_err(),
                .ecc_from_sram(data_out_0[15:11]),
                .data_from_sram(data_out_0[10:0])
            );
            test_mem_a_m11_ecc_chk u_chk_1 (
                .data_out(data_to_oup1_1),
                .single_bit_err(),
                .double_bit_err(),
                .ecc_from_sram(data_out_1[15:11]),
                .data_from_sram(data_out_1[10:0])
            );
            test_mem_a_m11_ecc_chk u_chk_2 (
                .data_out(data_to_oup1_2),
                .single_bit_err(),
                .double_bit_err(),
                .ecc_from_sram(data_out_2[15:11]),
                .data_from_sram(data_out_2[10:0])
            );
            test_mem_a_m11_ecc_chk u_chk_3 (
                .data_out(data_to_oup1_3),
                .single_bit_err(),
                .double_bit_err(),
                .ecc_from_sram(data_out_3[15:11]),
                .data_from_sram(data_out_3[10:0])
            );
        //  - hero -

    `ifdef TBV
        test_mem_a_pipe #(.WIDTH(1), .PIPE_STAGES(5)) rdata_vld_0 (
            .d(rd_0),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(6), .PIPE_STAGES(5)) raddr_pipe_0 (
            .d(addr_0),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(1), .PIPE_STAGES(5)) rdata_vld_1 (
            .d(rd_1),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(6), .PIPE_STAGES(5)) raddr_pipe_1 (
            .d(addr_1),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(1), .PIPE_STAGES(5)) rdata_vld_2 (
            .d(rd_2),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(6), .PIPE_STAGES(5)) raddr_pipe_2 (
            .d(addr_2),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(1), .PIPE_STAGES(5)) rdata_vld_3 (
            .d(rd_3),
            .q(),
            .clk(clk)
        );
        test_mem_a_pipe #(.WIDTH(6), .PIPE_STAGES(5)) raddr_pipe_3 (
            .d(addr_3),
            .q(),
            .clk(clk)
        );
    `endif  //  TBV

endmodule : multiple_port_1p_mem

