`timescale 1ns / 1ps
// ///////////////////////////////////////////////////////////////////////////
// Company:         NNS@TSN
// Engineer:        Wenxue Wu
// Create Date:     2023/11/03
// Design Name:     switch_post
// Module Name:     switch_post
// Project Name:    switch_post
// Target Devices:  Zynq
// Tool Versions:   VIVADO2023.2
// Revision:     v0.1
// Revision 0.01 - File Created
// Additional Comments:
//
// //////////////////////////////////////////////////////////////////////////
module switch_post (
    input        clk,
    input        clk_15_625,
    input        reset,
    input        phy_reset,
    input        o_cell_data_fifo_wr,
    input [63:0] o_cell_data_fifo_din,
    input        o_cell_first,
    input        o_cell_last,
    input [ 2:0] o_pad_num_64,
    input [ 3:0] o_vaild,

    //USE AXI-4STREAM  FIFO inferace
    output               m_axis_tvalid,  // output wire m_axis_tvalid
    input  wire          m_axis_tready,  // input wire m_axis_tready
    output wire [63 : 0] m_axis_tdata,   // output wire [63 : 0] m_axis_tdata
    output wire [ 7 : 0] m_axis_tkeep,   // output wire [7 : 0] m_axis_tkeep
    output wire          m_axis_tlast,   // output wire m_axis_tlast
    output reg           o_cell_bp

  );

  reg         o_cell_data_fifo_rd;
  wire [72:0] o_cell_data_fifo_dout;
  wire        o_cell_data_fifo_empty;
  wire [ 9:0] o_cell_data_fifo_data_count;
  reg         s_axis_tvalid;
  reg  [63:0] s_axis_tdata;
  reg  [ 7:0] s_axis_tkeep;
  reg         s_axis_tlast;
  wire        s_axis_tready;
  reg  [ 3:0] mstate;
  wire [31:0] axis_wr_data_count;
  reg  [ 2:0] pad_num;
  reg  [ 3:0] vaild_num;
  reg  [ 3:0] read_counter;
  wire        bp;


  fifo_ft_w73_d512 u_o_cell_fifo (
                     .clk(clk),
                     .rst(reset),
                     .din({
                            o_cell_first, o_cell_last, o_vaild[3:0], o_pad_num_64[2:0], o_cell_data_fifo_din[63:0]
                          }),
                     .wr_en(o_cell_data_fifo_wr),
                     .rd_en(o_cell_data_fifo_rd),
                     .dout(o_cell_data_fifo_dout[72:0]),
                     .full(),
                     .empty(o_cell_data_fifo_empty),
                     .almost_empty(),
                     .data_count(o_cell_data_fifo_data_count[9:0])
                   );

  always @(posedge clk)
  begin
    o_cell_bp <= (o_cell_data_fifo_data_count > 322) ? 1 : 0;
  end

  assign bp = axis_wr_data_count > 322 ? 1 : 0;



  always @(posedge clk)
    if (reset)
    begin
      mstate <= 0;
      o_cell_data_fifo_rd <= 0;
      s_axis_tdata <= 0;
      s_axis_tlast <= 0;
      s_axis_tkeep <= 0;
      pad_num <= 0;
      read_counter <= 0;
      vaild_num <= 0;
      s_axis_tvalid <= 0;
    end
    else
    begin
      o_cell_data_fifo_rd <= 0;
      s_axis_tlast <= 0;
      s_axis_tvalid <= 0;
      case (mstate)
        0:
        begin
          if (s_axis_tready&!bp&!o_cell_data_fifo_empty & o_cell_data_fifo_dout[72]=='b1)//first  cell
          begin
            mstate <= 1;
          end
        end
        1:
        begin
          vaild_num[3:0] <= 8 - o_cell_data_fifo_dout[66:64];
          mstate <= 2;
        end
        2:
        begin
          mstate <= o_cell_data_fifo_dout[72] && o_cell_data_fifo_dout[71] ? 7 : 3;
          o_cell_data_fifo_rd <= 1;
        end
        3:
        begin
          if (!o_cell_data_fifo_empty)
          begin
            read_counter <= read_counter + 1;
            if (o_cell_data_fifo_dout[71] == 'b0)
            begin
              s_axis_tdata <= o_cell_data_fifo_dout[63:0];
              s_axis_tkeep <= 8'b11111111;
              s_axis_tvalid <= 1;
              o_cell_data_fifo_rd <= 1;
              if (read_counter == 7)
              begin
                mstate <= 5;
                read_counter <= 0;
                o_cell_data_fifo_rd <= 0;
              end
            end
            else if (o_cell_data_fifo_dout[71] == 'b1)
            begin  //?��????????????cell
              o_cell_data_fifo_rd <= 1;
              if (vaild_num > 0)
              begin
                vaild_num <= vaild_num - 1;
                s_axis_tdata <= o_cell_data_fifo_dout[63:0];
                s_axis_tvalid <= 1;

                if (vaild_num == 1)
                begin
                  s_axis_tkeep<=(o_cell_data_fifo_dout[70:67]==0)? 8'b0000_0000:  (o_cell_data_fifo_dout[70:67]==1)? 8'b0000_0001: (o_cell_data_fifo_dout[70:67]==2)? 8'b0000_0011:
                        (o_cell_data_fifo_dout[70:67]==3)? 8'b0000_0111:(o_cell_data_fifo_dout[70:67]==4)? 8'b0000_1111:(o_cell_data_fifo_dout[70:67]==5)? 8'b0001_1111:
                              (o_cell_data_fifo_dout[70:67]==6)? 8'b0011_1111:(o_cell_data_fifo_dout[70:67]==7)? 8'b0111_1111:8'b1111_1111;
                  s_axis_tlast <= 1;
                end
              end
              if (read_counter == 7)
              begin
                mstate <= 0;
                read_counter <= 0;
                o_cell_data_fifo_rd <= 0;
              end
            end
          end
          else
            mstate <= 3;
        end
        4:
        begin
          if (!o_cell_data_fifo_empty)
          begin
            read_counter <= read_counter + 1;
            if (o_cell_data_fifo_dout[71] == 'b0)
            begin
              s_axis_tdata <= o_cell_data_fifo_dout[63:0];
              s_axis_tkeep <= 8'b11111111;
              s_axis_tvalid <= 1;
              o_cell_data_fifo_rd <= 1;
              if (read_counter == 7)
              begin
                mstate <= 6;
                read_counter <= 0;
                o_cell_data_fifo_rd <= 0;
              end
            end
            else if (o_cell_data_fifo_dout[71] == 'b1)
            begin  //?��????????????cell
              o_cell_data_fifo_rd <= 1;
              if (vaild_num > 0)
              begin
                vaild_num <= vaild_num - 1;
                s_axis_tdata <= o_cell_data_fifo_dout[63:0];
                s_axis_tvalid <= 1;

                if (vaild_num == 1)
                begin
                  s_axis_tkeep<=(o_cell_data_fifo_dout[70:67]==0)? 8'b0000_0000:  (o_cell_data_fifo_dout[70:67]==1)? 8'b0000_0001: (o_cell_data_fifo_dout[70:67]==2)? 8'b0000_0011:
                        (o_cell_data_fifo_dout[70:67]==3)? 8'b0000_0111:(o_cell_data_fifo_dout[70:67]==4)? 8'b0000_1111:(o_cell_data_fifo_dout[70:67]==5)? 8'b0001_1111:
                              (o_cell_data_fifo_dout[70:67]==6)? 8'b0011_1111:(o_cell_data_fifo_dout[70:67]==7)? 8'b0111_1111:8'b1111_1111;
                  s_axis_tlast <= 1;
                end
              end
              if (read_counter == 7)
              begin
                mstate <= 0;
                read_counter <= 0;
                o_cell_data_fifo_rd <= 0;
              end
            end
          end
          else
            mstate <= 4;
        end
        5:
        begin
          if (!o_cell_data_fifo_empty)
          begin
            mstate <= 4;
            o_cell_data_fifo_rd <= 1;
          end
          else
          begin
            o_cell_data_fifo_rd <= 0;
            mstate <= 5;
          end
        end
        6:
        begin
          if (!o_cell_data_fifo_empty)
          begin
            mstate <= 3;
            o_cell_data_fifo_rd <= 1;
          end
          else
          begin
            o_cell_data_fifo_rd <= 0;
            mstate <= 6;
          end
        end
        7:
        begin
          if (!o_cell_data_fifo_empty)
          begin
            read_counter <= read_counter + 1;

            if (o_cell_data_fifo_dout[71] == 'b1)
            begin  //
              o_cell_data_fifo_rd <= 1;
              if (vaild_num > 0)
              begin
                vaild_num <= vaild_num - 1;
                s_axis_tdata <= o_cell_data_fifo_dout[63:0];
                s_axis_tvalid <= 1;
                s_axis_tkeep <= 8'b1111_1111;
                if (vaild_num == 1)
                begin
                  s_axis_tlast <= 1;
                  s_axis_tkeep<=(o_cell_data_fifo_dout[70:67]==0)? 8'b0000_0000:  (o_cell_data_fifo_dout[70:67]==1)? 8'b0000_0001: (o_cell_data_fifo_dout[70:67]==2)? 8'b0000_0011:
                        (o_cell_data_fifo_dout[70:67]==3)? 8'b0000_0111:(o_cell_data_fifo_dout[70:67]==4)? 8'b0000_1111:(o_cell_data_fifo_dout[70:67]==5)? 8'b0001_1111:
                              (o_cell_data_fifo_dout[70:67]==6)? 8'b0011_1111:(o_cell_data_fifo_dout[70:67]==7)? 8'b0111_1111:8'b1111_1111;

                end
              end
              if (read_counter == 7)
              begin
                mstate <= 0;
                read_counter <= 0;
                o_cell_data_fifo_rd <= 0;
              end
            end
          end
          else
            mstate <= 7;
        end
        default:
          mstate <= 0;
      endcase
    end




  post_axi_data_fifo u_axi_data_fifo_d512_w64 (
                       .s_axis_aresetn    (!reset),              // input wire s_axis_aresetn
                       .s_axis_aclk       (clk),                 // input wire s_axis_aclk
                       .s_axis_tvalid     (s_axis_tvalid),       // input wire s_axis_tvalid
                       .s_axis_tready     (s_axis_tready),       // output wire s_axis_tready
                       .s_axis_tdata      (s_axis_tdata),        // input wire [63 : 0] s_axis_tdata
                       .s_axis_tkeep      (s_axis_tkeep),        // input wire [7 : 0] s_axis_tkeep
                       .s_axis_tlast      (s_axis_tlast),        // input wire s_axis_tlast
                       .s_axis_tuser      (1'b0),
                       .m_axis_aclk       (clk_15_625),          // input wire m_axis_aclk
                       .m_axis_tvalid     (m_axis_tvalid),       // output wire m_axis_tvalid
                       .m_axis_tready     (m_axis_tready),       // input wire m_axis_tready
                       .m_axis_tdata      (m_axis_tdata),        // output wire [63 : 0] m_axis_tdata
                       .m_axis_tkeep      (m_axis_tkeep),        // output wire [7 : 0] m_axis_tkeep
                       .m_axis_tlast      (m_axis_tlast),        // output wire m_axis_tlast
                       .axis_wr_data_count(axis_wr_data_count),  // output wire [31 : 0] axis_wr_data_count
                       .m_axis_tuser      ()
                     );







endmodule
