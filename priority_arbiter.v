`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:TSN@NNS
// Engineer:Wenxue Wu
// Create Date: 2024/05/15 16:43:21
// Module Name: priority_arbiter
// Target Devices:ZYNQ
// Tool Versions:VIVADO 2023.2
// Description:priority_arbiter for priority arbitration among multiple channels
//
//////////////////////////////////////////////////////////////////////////////////

module priority_arbiter #(
    parameter P_CHANEL_NUM = 4
  ) (
    input                         clk,
    input                         reset,
    input                         i_req_release,  //only one is valid
    input      [P_CHANEL_NUM-1:0] i_req_in,       // input
    output reg [P_CHANEL_NUM-1:0] o_grant_out
  );


  /***************reg*******************/
  reg ri_req_release;

  /***************function**************/


  always @(posedge clk)
  begin
    if (reset)
      ri_req_release <= 0;
    else
      ri_req_release <= i_req_release;
  end

  always @(posedge clk)
  begin
    if (reset)
      o_grant_out <= 0;
    else if (ri_req_release)
      o_grant_out <= i_req_in & ((~i_req_in) + 1);
    else
      o_grant_out <= o_grant_out;
  end

endmodule

