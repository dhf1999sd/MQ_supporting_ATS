
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:TSN@NNS
// Engineer:Wenxue Wu
// Create Date: 2024/05/15 16:43:21
// Module Name: ethernet_parser_64bit
// Target Devices:ZYNQ
// Tool Versions:VIVADO 2023.2
// Description:parses the Ethernet header for a 64 bit datapath
//
//////////////////////////////////////////////////////////////////////////////////


module ethernet_parser_64bit #(
    parameter DATA_WIDTH = 64,
    parameter CTRL_WIDTH=DATA_WIDTH/8,
    parameter NUM_IQ_BITS = 3,
    parameter INPUT_ARBITER_STAGE_NUM = 2,
    parameter NUM_STATES  = 3,
    parameter READ_WORD_1 = 1,
    parameter READ_WORD_2 = 2,
    parameter WAIT_EOP    = 4,
    parameter NUM_QUEUES = 4
) (  // --- Interface to the previous stage
    input [DATA_WIDTH-1:0] in_data,
    input [CTRL_WIDTH-1:0] in_ctrl,
    input                  in_wr,
    input [NUM_QUEUES-1:0] in_scr_port,

    // --- Interface to output_port_lookup
    output reg [47:0] dst_mac,
    output reg        dst_lut_flag,
    output reg        src_lut_flag,
    output reg [47:0] src_mac,
    output reg [15:0] ethertype,
    output reg [11:0] vlan_id,
    output reg        eth_done,
    output reg [15:0] src_port,

    // --- Misc

    input reset,
    input clk
);


  // ------------ Internal Params --------



  // ------------- Regs/ wires -----------

  reg [NUM_STATES-1:0] state;
  reg [NUM_STATES-1:0] state_next;
  reg                  dst_lut_flag_next;
  reg                  src_lut_flag_next;


  reg [          47:0] dst_mac_next;
  reg [          47:0] src_mac_next;
  reg [          15:0] ethertype_next;
  reg                  eth_done_next;
  reg [          15:0] src_port_next;
  reg [          11:0] vlan_id_next;

  // ------------ Logic ----------------

  always @(*) begin
    dst_mac_next      = dst_mac;
    src_mac_next      = src_mac;
    ethertype_next    = ethertype;
    vlan_id_next      = vlan_id;
    eth_done_next     = eth_done;
    src_port_next     = src_port;
    state_next        = state;
    dst_lut_flag_next = 0;
    src_lut_flag_next = 0;
    case (state)
      /* read the input source header and get the first word */
      READ_WORD_1: begin
        if (in_wr == 1) begin
          src_port_next      = in_scr_port;  // `IO_QUEUE_PORT ;
          //           end
          //           else if(in_wr && in_ctrl==0) begin
          dst_mac_next       = in_data[47:0];
          src_mac_next[15:0] = in_data[63:48];
          state_next         = READ_WORD_2;
          dst_lut_flag_next  = 1;
        end
      end  // case: READ_WORD_1

      READ_WORD_2: begin
        if (in_wr) begin
          src_mac_next[47:16] = in_data[31:0];
          ethertype_next      = in_data[47:32];
          vlan_id_next        = {in_data[51:48], in_data[63:56]};
          state_next          = WAIT_EOP;
          eth_done_next       = 1;
          src_lut_flag_next   = 1;
        end
      end

      WAIT_EOP: begin
        if (in_wr != 1) begin
          eth_done_next = 0;
          state_next    = READ_WORD_1;
        end
      end
      default: begin
        state_next = READ_WORD_1;
      end
    endcase  // case(state)
  end  // always @ (*)

  always @(posedge clk) begin
    if (reset) begin
      src_mac   <= 0;
      dst_mac   <= 0;
      ethertype <= 0;
      eth_done  <= 0;
      vlan_id = 0;
      state        <= READ_WORD_1;
      src_port     <= 0;
      dst_lut_flag <= 0;
      src_lut_flag <= 0;
    end else begin
      src_mac   <= src_mac_next;
      dst_mac   <= dst_mac_next;
      ethertype <= ethertype_next;
      vlan_id = vlan_id_next;
      eth_done     <= eth_done_next;
      state        <= state_next;
      src_port     <= src_port_next;
      dst_lut_flag <= dst_lut_flag_next;
      src_lut_flag <= src_lut_flag_next;
    end  // else: !if(reset)
  end  // always @ (posedge clk)

endmodule  // ethernet_parser_64bit
