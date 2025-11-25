`timescale 1ns / 1ps
// ///////////////////////////////////////////////////////////////////////////
// Company:         NNS@TSN
// Engineer:        Wenxue Wu
// Create Date:     2023/11/02
// Design Name:     switch_post_top
// Module Name:     switch_post_top
// Project Name:    switch_post_top
// Target Devices:  Zynq
// Tool Versions:   VIVADO2023.2
// //////////////////////////////////////////////////////////////////////////


module switch_post_top (
    input clk,
    input clk_15_625,
    input reset,

    input [63:0] pktout_data_0,
    input [63:0] pktout_data_1,
    input [63:0] pktout_data_2,
    input [63:0] pktout_data_3,
    input pktout_data_wr_0,
    input pktout_data_wr_1,
    input pktout_data_wr_2,
    input pktout_data_wr_3,


    output          m_axis_tvalid_0,  // output wire m_axis_tvalid
    input           m_axis_tready_0,  // input wire m_axis_tready
    output [63 : 0] m_axis_tdata_0,   // output wire [63 : 0] m_axis_tdata
    output [ 7 : 0] m_axis_tkeep_0,   // output wire [7 : 0] m_axis_tkeep
    output          m_axis_tlast_0,   // output wire m_axis_tlast



    output          m_axis_tvalid_1,  // output wire m_axis_tvalid
    input           m_axis_tready_1,  // input wire m_axis_tready
    output [63 : 0] m_axis_tdata_1,   // output wire [63 : 0] m_axis_tdata
    output [ 7 : 0] m_axis_tkeep_1,   // output wire [7 : 0] m_axis_tkeep
    output          m_axis_tlast_1,   // output wire m_axis_tlast


    output          m_axis_tvalid_2,  // output wire m_axis_tvalid
    input           m_axis_tready_2,  // input wire m_axis_tready
    output [63 : 0] m_axis_tdata_2,   // output wire [63 : 0] m_axis_tdata
    output [ 7 : 0] m_axis_tkeep_2,   // output wire [7 : 0] m_axis_tkeep
    output          m_axis_tlast_2,   // output wire m_axis_tlast

    output          m_axis_tvalid_3,  // output wire m_axis_tvalid
    input           m_axis_tready_3,  // input wire m_axis_tready
    output [63 : 0] m_axis_tdata_3,   // output wire [63 : 0] m_axis_tdata
    output [ 7 : 0] m_axis_tkeep_3,   // output wire [7 : 0] m_axis_tkeep
    output          m_axis_tlast_3,   // output wire m_axis_tlast

    input o_cell_first,
    input o_cell_last,
    input [2:0] o_pad_num_64,
    input [3:0] o_vaild,
    output [3:0] o_cell_bp
  );


  wire o_cell_bp_0;
  wire o_cell_bp_1;
  wire o_cell_bp_2;
  wire o_cell_bp_3;

  assign o_cell_bp = {o_cell_bp_3, o_cell_bp_2, o_cell_bp_1, o_cell_bp_0};

  switch_post post_0 (
                .clk(clk),
                .clk_15_625(clk_15_625),
                .reset(reset),
                .o_cell_first(o_cell_first),
                .o_cell_last(o_cell_last),
                .o_pad_num_64(o_pad_num_64),
                .o_vaild(o_vaild),
                .o_cell_bp(o_cell_bp_0),
                .o_cell_data_fifo_wr(pktout_data_wr_0),
                .o_cell_data_fifo_din(pktout_data_0),
                .m_axis_tvalid(m_axis_tvalid_0),  // output wire m_axis_tvalid
                .m_axis_tready(m_axis_tready_0),  // input wire m_axis_tready
                .m_axis_tdata(m_axis_tdata_0),  // output wire [63 : 0] m_axis_tdata
                .m_axis_tkeep(m_axis_tkeep_0),  // output wire [7 : 0] m_axis_tkeep
                .m_axis_tlast(m_axis_tlast_0)  // output wire m_axis_tlast

              );


  switch_post post_1 (
                .clk(clk),
                .clk_15_625(clk_15_625),
                .reset(reset),
                .o_cell_first(o_cell_first),
                .o_cell_last(o_cell_last),
                .o_pad_num_64(o_pad_num_64),
                .o_vaild(o_vaild),
                .o_cell_bp(o_cell_bp_1),
                .o_cell_data_fifo_wr(pktout_data_wr_1),
                .o_cell_data_fifo_din(pktout_data_1),
                .m_axis_tvalid(m_axis_tvalid_1),  // output wire m_axis_tvalid
                .m_axis_tready(m_axis_tready_1),  // input wire m_axis_tready
                .m_axis_tdata(m_axis_tdata_1),  // output wire [63 : 0] m_axis_tdata
                .m_axis_tkeep(m_axis_tkeep_1),  // output wire [7 : 0] m_axis_tkeep
                .m_axis_tlast(m_axis_tlast_1)  // output wire m_axis_tlast
              );

  switch_post post_2 (
                .clk(clk),
                .clk_15_625(clk_15_625),
                .reset(reset),
                .o_cell_first(o_cell_first),
                .o_cell_last(o_cell_last),
                .o_pad_num_64(o_pad_num_64),
                .o_vaild(o_vaild),
                .o_cell_bp(o_cell_bp_2),
                .o_cell_data_fifo_wr(pktout_data_wr_2),
                .o_cell_data_fifo_din(pktout_data_2),
                .m_axis_tvalid(m_axis_tvalid_2),  // output wire m_axis_tvalid
                .m_axis_tready(m_axis_tready_2),  // input wire m_axis_tready
                .m_axis_tdata(m_axis_tdata_2),  // output wire [63 : 0] m_axis_tdata
                .m_axis_tkeep(m_axis_tkeep_2),  // output wire [7 : 0] m_axis_tkeep
                .m_axis_tlast(m_axis_tlast_2)  // output wire m_axis_tlast
              );

  switch_post post_3 (
                .clk(clk),
                .clk_15_625(clk_15_625),
                .reset(reset),
                .o_cell_first(o_cell_first),
                .o_cell_last(o_cell_last),
                .o_pad_num_64(o_pad_num_64),
                .o_vaild(o_vaild),
                .o_cell_bp(o_cell_bp_3),
                .o_cell_data_fifo_wr(pktout_data_wr_3),
                .o_cell_data_fifo_din(pktout_data_3),
                .m_axis_tvalid(m_axis_tvalid_3),  // output wire m_axis_tvalid
                .m_axis_tready(m_axis_tready_3),  // input wire m_axis_tready
                .m_axis_tdata(m_axis_tdata_3),  // output wire [63 : 0] m_axis_tdata
                .m_axis_tkeep(m_axis_tkeep_3),  // output wire [7 : 0] m_axis_tkeep
                .m_axis_tlast(m_axis_tlast_3)  // output wire m_axis_tlast
              );





endmodule
