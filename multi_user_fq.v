`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:TSN@NNS
// Engineer:Wenxue Wu
// Create Date:  2023/11/14
// Module Name: module multi_user_fq (
// Target Devices:ZYNQ
// Tool Versions:VIVADO 2023.2
// Description:
//////////////////////////////////////////////////////////////////////////////////
module multi_user_fq (
    input        clk,
    input        reset,
    input        FQ_wr,
    input        FQ_rd,
    input  [8:0] ptr_din,
    output       ptr_fifo_empty,
    output [8:0] ptr_dout_s

);
  reg    ptr_fifo_wr;
  reg  [2:0] cnt ;
  reg   [2:0]  FQ_state;
  reg   [9:0]  addr_cnt;
  reg   [8:0]  fq_ptr_fifo_din;

  always @(posedge clk)
    if (reset) begin
      FQ_state <= 0;
      addr_cnt <= 0;
      ptr_fifo_wr <= 0;
      cnt <= 0;
      fq_ptr_fifo_din <= 0;
    end else begin
      ptr_fifo_wr <= 0;
      fq_ptr_fifo_din <= ptr_din[8:0];
      case (FQ_state)
        0: FQ_state <= 1;
        1: FQ_state <= 2;
        2: FQ_state <= 3;
        3:
        if (cnt < 7) begin
          FQ_state <= 3;
          cnt <= cnt + 1;
        end else FQ_state <= 4;
        4: begin
          fq_ptr_fifo_din <= addr_cnt;
          if (addr_cnt < 9'h1ff) addr_cnt <= addr_cnt + 1;
          if (fq_ptr_fifo_din < 9'h1ff) ptr_fifo_wr <= 1;
          else begin
            FQ_state <= 5;
            ptr_fifo_wr <= 0;
          end
        end
        5: begin
          if (FQ_wr) ptr_fifo_wr <= 1;
        end
        default: begin
          FQ_state <= 0;
        end
      endcase
    end

  fifo_ft_w_d u1_ft_ptr_fifo (
      .clk(clk),
      .rst(reset),
      .din(fq_ptr_fifo_din[8:0]),
      .wr_en(ptr_fifo_wr),
      .rd_en(FQ_rd),
      .dout(ptr_dout_s[8:0]),
      .empty(ptr_fifo_empty),
      .full(),
      .data_count()
  );





endmodule
