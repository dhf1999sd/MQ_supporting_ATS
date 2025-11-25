
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:TSN@NNS
// Engineer:Wenxue Wu
// Create Date: 2024/05/15 16:43:21
// Module Name: ethernet_parser
// Target Devices:ZYNQ
// Tool Versions:VIVADO 2023.2
// Description:parses the Ethernet header for a 32 or 64 bit datapath
//
//////////////////////////////////////////////////////////////////////////////////
module ethernet_parser #(
    parameter DATA_WIDTH = 64,
    parameter CTRL_WIDTH = DATA_WIDTH / 8,
    parameter NUM_IQ_BITS = 3,
    parameter INPUT_ARBITER_STAGE_NUM = 2,
    parameter NUM_QUEUES = 4
  ) (  // --- Interface to the previous stage
    input [DATA_WIDTH-1:0] in_data,
    input [CTRL_WIDTH-1:0] in_ctrl,
    input                  in_wr,
    input [NUM_QUEUES-1:0] in_scr_port,
    // --- Interface to output_port_lookup
    output wire [47:0] dst_mac,
    output wire [47:0] src_mac,
    output      [15:0] ethertype,
    output      [11:0] vlan_id,
    output             eth_done,
    output reg  [15:0] out_src_port,
    output             dst_lut_flag,
    output             src_lut_flag,
    output wire [ 9:0] se_hash,
    output wire        se_req,
    output reg         aging_req,
    // --- Misc
    input reset,
    input clk
  );


  wire [47:0] dst_mac_reg;
  wire [47:0] src_mac_reg;
  wire [15:0] src_port_reg;
  generate
    genvar i;
    if (DATA_WIDTH == 64)
    begin : ethernet_parser_64bit
      ethernet_parser_64bit #(
                              .NUM_IQ_BITS(NUM_IQ_BITS),
                              .INPUT_ARBITER_STAGE_NUM(INPUT_ARBITER_STAGE_NUM)
                            ) eth_parser (
                              .in_data(in_data),
                              .in_ctrl(in_ctrl),
                              .in_wr(in_wr),
                              .in_scr_port(in_scr_port),
                              .dst_mac(dst_mac_reg),
                              .dst_lut_flag(dst_lut_flag),
                              .src_lut_flag(src_lut_flag),
                              .src_mac(src_mac_reg),
                              .ethertype(ethertype),
                              .vlan_id(vlan_id),
                              .eth_done(eth_done),
                              .src_port(src_port_reg),
                              .reset(reset),
                              .clk(clk)
                            );
    end  // block: eth_parser_64bit

  endgenerate



  assign se_req  = dst_lut_flag;
  assign src_mac = src_mac_reg;
  assign dst_mac = dst_mac_reg;
  assign se_hash = dst_lut_flag ? dst_mac_reg : src_mac_reg ? src_mac_reg : 0;

  always @(posedge clk)
  begin
    if (reset)
    begin
      aging_req <= 0;
    end
    else
      if (dst_lut_flag)
      begin
      end
      else if (src_lut_flag)
      begin
        out_src_port <= src_port_reg;
      end
      else
      begin
        aging_req <= 0;
      end
  end

endmodule  // ethernet_parser_64bit
