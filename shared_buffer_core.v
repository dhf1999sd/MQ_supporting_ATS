`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:          TSN@NNS
// Engineer:         Wenxue Wu
// Create Date:      2024/8/6
// Module Name:      shared_buffer_core
// Target Devices:   ZYNQ
// Tool Versions:    VIVADO 2023.2
// Description:      Shared buffer core for packet switching with ATS support
//////////////////////////////////////////////////////////////////////////////////

module shared_buffer_core #( 
    parameter NUM_PORT = 4,
    parameter TIMESTAMP_WIDTH = 59
  ) (
    input                               clk,
    input                               reset,
    input                               i_cell_data_fifo_wr,
    input                               i_cell_ptr_fifo_wr,
    input  [2:0]                        priority,
    input  [3:0]                        o_cell_bp,
    input  [22:0]                       i_cell_ptr_fifo_din,
    input  [31:0]                       in_flow_ID,
    input  [63:0]                       i_cell_data_fifo_din,
    input  [3:0]                        group_id,
    output                              i_cell_bp,
    output reg                          o_cell_fifo_wr,
    output                              o_cell_first,
    output                              o_cell_last,
    output [2:0]                        o_pad_num_64,
    output reg [3:0]                    o_cell_fifo_sel,
    output [3:0]                        o_vaild,
    output [63:0]                       o_cell_fifo_din
  );

  //================================================================
  // Internal Registers
  //================================================================
  reg                                 i_cell_ptr_fifo_rd;
  reg                                 i_cell_data_fifo_rd;
  reg                                 i_cell_last;
  reg                                 i_cell_first;
  reg                                 FQ_wr;
  reg                                 FQ_rd;
  reg [2:0]                           sram_cnt_a;
  reg [2:0]                           sram_cnt_b;
  reg [2:0]                           pad_num;
  reg [3:0]                           qm_portmap;
  reg [4:0]                           cell_number;
  reg [19:0]                          FQ_din;
  reg [8:0]                           FQ_dout;
  reg                                 sram_rd;
  reg [3:0]                           rd_state;
  reg [3:0]                           wr_state;
  reg [3:0]                           input_metadata_wr_en;
  reg [20:0]                          in_metadata;
  reg [31:0]                          flow_id[NUM_PORT-1:0];
  reg [3:0]                           group_id_in[NUM_PORT-1:0];
  reg [2:0]                           pcp[NUM_PORT-1:0];
  reg [3:0]                           in_port[NUM_PORT-1:0];
  reg [31:0]                          flow_id_reg;
  reg [2:0]                           pcp_reg;
  reg [3:0]                           in_port_reg;
  reg [8:0]                           MC_ram_addra;
  reg [3:0]                           MC_ram_dina;
  reg                                 MC_ram_wra;
  reg                                 MC_ram_wrb;
  reg [3:0]                           MC_ram_dinb;
  reg [3:0]                           valid;
  reg                                 i_cell_ptr_fifo_wr_reg;
  reg [2:0]                           priority_reg;
  reg [3:0]                           group_id_reg;
  reg [3:0]                           group_id_reg_reg;
  reg [31:0]                          in_flow_ID_reg;
  reg [22:0]                          i_cell_ptr_fifo_din_reg;
  reg [15:0]                          frame_length;
  reg                                 read_end_flag;
  reg [1:0]                           RR;
  reg [3:0]                           ptr_ack;
  reg [3:0]                           ptr_rd_req_pre;
  reg [TIMESTAMP_WIDTH-1:0]           arrival_time;
  reg [2:0]                           discard_counter;
  reg [NUM_PORT-1:0]                  start_flag;
  reg [2:0]                           port_map;

  //================================================================
  // Internal Wires
  //================================================================
  wire                                qm_ptr_full_0;
  wire                                qm_ptr_full_1;
  wire                                qm_ptr_full_2;
  wire                                qm_ptr_full_3;
  wire                                qm_ptr_full;
  wire                                sram_wr_a;
  wire                                i_cell_ptr_fifo_full;
  wire                                i_cell_ptr_fifo_empty;
  wire [63:0]                         i_cell_data_fifo_dout;
  wire [9:0]                          i_cell_data_fifo_depth;
  wire [11:0]                         sram_addr_a;
  wire [11:0]                         sram_addr_b;
  wire [61:0]                         i_cell_ptr_fifo_dout;
  wire [63:0]                         sram_din_a;
  wire [63:0]                         sram_dout_b;
  wire [8:0]                          ptr_dout_s;
  wire                                FQ_empty;
  wire [3:0]                          MC_ram_doutb;
  wire [TIMESTAMP_WIDTH-1:0]          local_clock;
  wire [NUM_PORT-1:0]                 frame_eligible_time_OK;
  wire [NUM_PORT-1:0]                 frame_discard_flag;
  wire [TIMESTAMP_WIDTH-1:0]          frame_eligible_time[NUM_PORT-1:0]  ;
  wire [19:0]                         qm_rd_ptr_dout_0, qm_rd_ptr_dout_1, qm_rd_ptr_dout_2, qm_rd_ptr_dout_3;
  wire                                ptr_rdy0, ptr_rdy1, ptr_rdy2, ptr_rdy3;
  wire                                ptr_ack0, ptr_ack1, ptr_ack2, ptr_ack3;

  //================================================================
  // Assignments
  //================================================================
  assign qm_ptr_full   = ({qm_ptr_full_3, qm_ptr_full_2, qm_ptr_full_1, qm_ptr_full_0} == 4'b0) ? 0 : 1;
  assign i_cell_bp     = (i_cell_data_fifo_depth > 10'd322) | i_cell_ptr_fifo_full;
  assign {ptr_ack3, ptr_ack2, ptr_ack1, ptr_ack0} = ptr_ack;
  assign sram_addr_b   = {FQ_din[8:0], sram_cnt_b[2:0]};
  assign o_cell_last   = FQ_din[15];
  assign o_cell_first  = FQ_din[14];
  assign o_pad_num_64  = FQ_din[12:10];
  assign o_vaild       = FQ_din[19:16];
  assign o_cell_fifo_din[63:0] = sram_dout_b[63:0];
  assign sram_wr_a     = i_cell_data_fifo_rd && (wr_state != 9);
  assign sram_addr_a   = {FQ_dout[8:0], sram_cnt_a[2:0]};
  assign sram_din_a    = i_cell_data_fifo_dout[63:0];

  //================================================================
  // Input Register Pipeline
  //================================================================
  always @(posedge clk)
  begin
    if (reset)
    begin
      i_cell_ptr_fifo_wr_reg      <= 0;
      in_flow_ID_reg              <= 0;
      i_cell_ptr_fifo_din_reg     <= 0;
      priority_reg                <= 0;
      group_id_reg                <= 0;
    end
    else
    begin
      i_cell_ptr_fifo_wr_reg      <= i_cell_ptr_fifo_wr;
      priority_reg                <= priority;
      group_id_reg                <= group_id;
      in_flow_ID_reg              <= in_flow_ID;
      i_cell_ptr_fifo_din_reg[22:0] <= i_cell_ptr_fifo_din[22:0];
    end
  end

  //================================================================
  // Write State Machine
  //================================================================
  always @(posedge clk)
  begin
    if (reset)
    begin
      wr_state                    <= 0;
      FQ_rd                       <= 0;
      MC_ram_wra                  <= 0;
      sram_cnt_a                  <= 0;
      i_cell_data_fifo_rd         <= 0;
      i_cell_ptr_fifo_rd          <= 0;
      input_metadata_wr_en        <= 0;
      in_metadata                 <= 0;
      FQ_dout                     <= 0;
      qm_portmap                  <= 0;
      cell_number                 <= 0;
      i_cell_last                 <= 0;
      i_cell_first                <= 0;
      MC_ram_addra                <= 0;
      valid                       <= 0;
      pad_num                     <= 0;
      discard_counter             <= 0;
      MC_ram_dina                 <= 0;
      pcp[0]                      <= 0;
      pcp[1]                      <= 0;
      pcp[2]                      <= 0;
      pcp[3]                      <= 0;
      in_port[0]                  <= 0;
      in_port[1]                  <= 0;
      in_port[2]                  <= 0;
      in_port[3]                  <= 0;
      flow_id[0]                  <= 0;
      flow_id[1]                  <= 0;
      flow_id[2]                  <= 0;
      flow_id[3]                  <= 0;
      group_id_in[0]              <= 0;
      group_id_in[1]              <= 0;
      group_id_in[2]              <= 0;
      group_id_in[3]              <= 0;
      flow_id_reg                 <= 0;
      in_port_reg                 <= 0;
      pcp_reg                     <= 0;
      start_flag                  <= 4'b0000;
      frame_length                <= 0;
      read_end_flag               <= 0;
      group_id_reg_reg            <= 0;
      arrival_time                <= 0;
      port_map                    <= 0;
    end
    else
    begin
      MC_ram_wra                  <= 0;
      FQ_rd                       <= 0;
      input_metadata_wr_en        <= 0;
      i_cell_ptr_fifo_rd          <= 0;
      MC_ram_addra                <= {FQ_dout[8:0]};
      MC_ram_dina                 <= qm_portmap[0] + qm_portmap[1] + qm_portmap[2] + qm_portmap[3];

      case (wr_state)
        0:
        begin
          sram_cnt_a <= 0;
          if (qm_portmap[0])
          begin
            flow_id[0]     <= i_cell_ptr_fifo_dout[54:23];
            group_id_in[0] <= i_cell_ptr_fifo_dout[61:58];
          end
          else if (qm_portmap[1])
          begin
            flow_id[1]     <= i_cell_ptr_fifo_dout[54:23];
            group_id_in[1] <= i_cell_ptr_fifo_dout[61:58];
          end
          else if (qm_portmap[2])
          begin
            flow_id[2]     <= i_cell_ptr_fifo_dout[54:23];
            group_id_in[2] <= i_cell_ptr_fifo_dout[61:58];
          end
          else if (qm_portmap[3])
          begin
            flow_id[3]     <= i_cell_ptr_fifo_dout[54:23];
            group_id_in[3] <= i_cell_ptr_fifo_dout[61:58];
          end

          if (!i_cell_ptr_fifo_empty & !qm_ptr_full & !FQ_empty)
          begin
            arrival_time                <= local_clock[TIMESTAMP_WIDTH-1:0];
            i_cell_ptr_fifo_rd          <= 1;
            start_flag                  <= i_cell_ptr_fifo_dout[11:8];
            qm_portmap[3:0]             <= i_cell_ptr_fifo_dout[11:8];
            pcp_reg                     <= i_cell_ptr_fifo_dout[57:55];
            group_id_reg_reg            <= i_cell_ptr_fifo_dout[61:58];
            in_port_reg[3:0]            <= i_cell_ptr_fifo_dout[22:19];
            flow_id_reg                 <= i_cell_ptr_fifo_dout[54:23];
            FQ_dout                     <= ptr_dout_s;
            frame_length[15:0]          <= i_cell_ptr_fifo_dout[7:3] << 6;
            cell_number[4:0]            <= i_cell_ptr_fifo_dout[7:3];
            pad_num[2:0]                <= i_cell_ptr_fifo_dout[2:0];
            valid[3:0]                  <= i_cell_ptr_fifo_dout[15:12];
            i_cell_first                <= 1;
            port_map[2:0]            <= i_cell_ptr_fifo_dout[8]?0:i_cell_ptr_fifo_dout[9]? 1:i_cell_ptr_fifo_dout[10]?2:3;
            if (i_cell_ptr_fifo_dout[7:3] == 'd1)
              i_cell_last <= 1;

            if (frame_eligible_time_OK[port_map] && ~frame_discard_flag[port_map])
            begin
              wr_state                <= 1;
              start_flag              <= 0;
              read_end_flag           <= 1;
              FQ_rd                   <= 1;
              i_cell_data_fifo_rd     <= 1;
              i_cell_ptr_fifo_rd      <= 1;
            end
            else if (frame_discard_flag[port_map])
            begin
              wr_state                <= 9;
              cell_number             <= cell_number;
              start_flag              <= 0;
              read_end_flag           <= 1;
              i_cell_ptr_fifo_rd      <= 1;
            end
            else
            begin
              wr_state                <= 0;
              i_cell_ptr_fifo_rd      <= 0;
            end
          end
        end

        1:
        begin
          cell_number                     <= cell_number - 1;
          read_end_flag                   <= 0;
          sram_cnt_a                      <= 1;
          in_metadata                     <= {valid[3:0], i_cell_last, i_cell_first, 1'b0, pad_num[2:0], 1'b0, FQ_dout[8:0]};

          if (qm_portmap[0])
          begin
            input_metadata_wr_en[0]     <= 1;
            pcp[0]                      <= pcp_reg;
            in_port[0]                  <= in_port_reg;
          end
          if (qm_portmap[1])
          begin
            input_metadata_wr_en[1]     <= 1;
            pcp[1]                      <= pcp_reg;
            in_port[1]                  <= in_port_reg;
          end
          if (qm_portmap[2])
          begin
            input_metadata_wr_en[2]     <= 1;
            pcp[2]                      <= pcp_reg;
            in_port[2]                  <= in_port_reg;
          end
          if (qm_portmap[3])
          begin
            input_metadata_wr_en[3]     <= 1;
            pcp[3]                      <= pcp_reg;
            in_port[3]                  <= in_port_reg;
          end
          MC_ram_wra                      <= 1;
          wr_state                        <= 2;
        end

        2:
        begin
          i_cell_last                     <= 0;
          i_cell_first                    <= 0;
          sram_cnt_a                      <= 2;
          wr_state                        <= 3;
        end

        3:
        begin
          sram_cnt_a                      <= 3;
          wr_state                        <= 4;
        end

        4:
        begin
          sram_cnt_a                      <= 4;
          wr_state                        <= 5;
        end

        5:
        begin
          sram_cnt_a                      <= 5;
          wr_state                        <= 6;
        end

        6:
        begin
          sram_cnt_a                      <= 6;
          wr_state                        <= 7;
        end

        7:
        begin
          sram_cnt_a                      <= 7;
          wr_state                        <= 8;
        end

        8:
        begin
          i_cell_first                    <= 0;
          if (cell_number)
          begin
            if (!FQ_empty)
            begin
              FQ_rd                   <= 1;
              FQ_dout                 <= ptr_dout_s;
              sram_cnt_a              <= 0;
              wr_state                <= 1;
              if (cell_number == 1)
                i_cell_last         <= 1;
              else
                i_cell_last         <= 0;
            end
          end
          else
          begin
            i_cell_data_fifo_rd         <= 0;
            wr_state                    <= 0;
          end
        end

        9:
        begin
          i_cell_last                     <= 0;
          i_cell_first                    <= 0;
          if (cell_number)
          begin
            if (discard_counter == 3'd7)
            begin
              i_cell_ptr_fifo_rd      <= 1;
              discard_counter         <= 0;
              cell_number             <= cell_number - 1;
              if (cell_number == 1)
                i_cell_data_fifo_rd <= 0;
            end
            else
            begin
              i_cell_ptr_fifo_rd      <= 0;
              discard_counter         <= discard_counter + 1;
            end
            i_cell_data_fifo_rd         <= 1;
          end
          else
          begin
            i_cell_ptr_fifo_rd          <= 0;
            i_cell_data_fifo_rd         <= 0;
            discard_counter             <= 0;
            wr_state                    <= 0;
          end
        end

        default:
          wr_state <= 0;
      endcase
    end
  end

  //================================================================
  // Read State Machine
  //================================================================
  always @(posedge clk)
  begin
    ptr_rd_req_pre[3:0] <= ({ptr_rdy3, ptr_rdy2, ptr_rdy1, ptr_rdy0} & (~o_cell_bp));
  end

  always @(posedge clk)
  begin
    if (reset)
    begin
      rd_state                    <= 'd0;
      FQ_wr                       <= 0;
      FQ_din                      <= 0;
      MC_ram_wrb                  <= 0;
      MC_ram_dinb                 <= 0;
      RR                          <= 0;
      ptr_ack                     <= 0;
      sram_rd                     <= 0;
      sram_cnt_b                  <= 0;
      o_cell_fifo_wr              <= 0;
      o_cell_fifo_sel             <= 0;
    end
    else
    begin
      FQ_wr                       <= 0;
      MC_ram_wrb                  <= 0;
      o_cell_fifo_wr              <= sram_rd;

      case (rd_state)
        0:
        begin
          sram_rd                 <= 0;
          sram_cnt_b              <= 0;
          if (ptr_rd_req_pre)
            rd_state            <= 'd1;
        end

        1:
        begin
          rd_state                <= 'd2;
          sram_rd                 <= 1;
          RR                      <= RR + 2'b01;
          case (RR)
            0:
            begin
              casex (ptr_rd_req_pre[3:0])
                4'bxxx1:
                begin
                  FQ_din          <= qm_rd_ptr_dout_0;
                  o_cell_fifo_sel <= 4'b0001;
                  ptr_ack         <= 4'b0001;
                end
                4'bxx10:
                begin
                  FQ_din          <= qm_rd_ptr_dout_1;
                  o_cell_fifo_sel <= 4'b0010;
                  ptr_ack         <= 4'b0010;
                end
                4'bx100:
                begin
                  FQ_din          <= qm_rd_ptr_dout_2;
                  o_cell_fifo_sel <= 4'b0100;
                  ptr_ack         <= 4'b0100;
                end
                4'b1000:
                begin
                  FQ_din          <= qm_rd_ptr_dout_3;
                  o_cell_fifo_sel <= 4'b1000;
                  ptr_ack         <= 4'b1000;
                end
              endcase
            end
            1:
            begin
              casex ({ptr_rd_req_pre[0], ptr_rd_req_pre[3:1]})
                4'bxxx1:
                begin
                  FQ_din          <= qm_rd_ptr_dout_1;
                  o_cell_fifo_sel <= 4'b0010;
                  ptr_ack         <= 4'b0010;
                end
                4'bxx10:
                begin
                  FQ_din          <= qm_rd_ptr_dout_2;
                  o_cell_fifo_sel <= 4'b0100;
                  ptr_ack         <= 4'b0100;
                end
                4'bx100:
                begin
                  FQ_din          <= qm_rd_ptr_dout_3;
                  o_cell_fifo_sel <= 4'b1000;
                  ptr_ack         <= 4'b1000;
                end
                4'b1000:
                begin
                  FQ_din          <= qm_rd_ptr_dout_0;
                  o_cell_fifo_sel <= 4'b0001;
                  ptr_ack         <= 4'b0001;
                end
              endcase
            end
            2:
            begin
              casex ({ptr_rd_req_pre[1:0], ptr_rd_req_pre[3:2]})
                4'bxxx1:
                begin
                  FQ_din          <= qm_rd_ptr_dout_2;
                  o_cell_fifo_sel <= 4'b0100;
                  ptr_ack         <= 4'b0100;
                end
                4'bxx10:
                begin
                  FQ_din          <= qm_rd_ptr_dout_3;
                  o_cell_fifo_sel <= 4'b1000;
                  ptr_ack         <= 4'b1000;
                end
                4'bx100:
                begin
                  FQ_din          <= qm_rd_ptr_dout_0;
                  o_cell_fifo_sel <= 4'b0001;
                  ptr_ack         <= 4'b0001;
                end
                4'b1000:
                begin
                  FQ_din          <= qm_rd_ptr_dout_1;
                  o_cell_fifo_sel <= 4'b0010;
                  ptr_ack         <= 4'b0010;
                end
              endcase
            end
            3:
            begin
              casex ({ptr_rd_req_pre[2:0], ptr_rd_req_pre[3]})
                4'bxxx1:
                begin
                  FQ_din          <= qm_rd_ptr_dout_3;
                  o_cell_fifo_sel <= 4'b1000;
                  ptr_ack         <= 4'b1000;
                end
                4'bxx10:
                begin
                  FQ_din          <= qm_rd_ptr_dout_0;
                  o_cell_fifo_sel <= 4'b0001;
                  ptr_ack         <= 4'b0001;
                end
                4'bx100:
                begin
                  FQ_din          <= qm_rd_ptr_dout_1;
                  o_cell_fifo_sel <= 4'b0010;
                  ptr_ack         <= 4'b0010;
                end
                4'b1000:
                begin
                  FQ_din          <= qm_rd_ptr_dout_2;
                  o_cell_fifo_sel <= 4'b0100;
                  ptr_ack         <= 4'b0100;
                end
              endcase
            end
          endcase
        end

        'd2:
        begin
          ptr_ack                 <= 0;
          sram_cnt_b              <= sram_cnt_b + 1;
          rd_state                <= 'd3;
        end

        'd3:
        begin
          sram_cnt_b              <= sram_cnt_b + 1;
          rd_state                <= 'd4;
        end

        'd4:
        begin
          sram_cnt_b              <= sram_cnt_b + 1;
          rd_state                <= 'd5;
        end

        'd5:
        begin
          sram_cnt_b              <= sram_cnt_b + 1;
          rd_state                <= 'd6;
        end

        'd6:
        begin
          sram_cnt_b              <= sram_cnt_b + 1;
          rd_state                <= 'd7;
        end

        'd7:
        begin
          sram_cnt_b              <= sram_cnt_b + 1;
          MC_ram_wrb              <= 1;
          if (MC_ram_doutb == 1)
          begin
            MC_ram_dinb         <= 0;
            FQ_wr               <= 1;
          end
          else
            MC_ram_dinb         <= MC_ram_doutb - 1;
          rd_state                <= 'd8;
        end

        'd8:
        begin
          sram_cnt_b              <= sram_cnt_b + 1;
          rd_state                <= 'd0;
        end

        default:
          rd_state <= 0;
      endcase
    end
  end

  //================================================================
  // Data FIFO Instances
  //================================================================
  fifo_ft_w64_d512 u_fifo_ft_w64_d512 (
                     .clk                (clk),
                     .rst                (reset),
                     .din                (i_cell_data_fifo_din[63:0]),
                     .wr_en              (i_cell_data_fifo_wr),
                     .rd_en              (i_cell_data_fifo_rd),
                     .dout               (i_cell_data_fifo_dout[63:0]),
                     .full               (),
                     .empty              (),
                     .data_count         (i_cell_data_fifo_depth)
                   );

  ptr_fifo u_ptr_fifo_ft (
             .clk                (clk),
             .rst                (reset),
             .din                ({group_id_reg[3:0], priority_reg, in_flow_ID_reg, i_cell_ptr_fifo_din_reg[22:0]}),
             .wr_en              (i_cell_ptr_fifo_wr_reg),
             .rd_en              (i_cell_ptr_fifo_rd),
             .dout               (i_cell_ptr_fifo_dout[61:0]),
             .full               (i_cell_ptr_fifo_full),
             .empty              (i_cell_ptr_fifo_empty),
             .data_count         ()
           );

  //================================================================
  // Free Queue and Memory Instances
  //================================================================
  multi_user_fq u_multi_user_fq (
                  .clk                (clk),
                  .reset              (reset),
                  .ptr_din            (FQ_din[9:0]),
                  .FQ_wr              (FQ_wr),
                  .FQ_rd              (FQ_rd),
                  .ptr_dout_s         (ptr_dout_s),
                  .ptr_fifo_empty     (FQ_empty)
                );

  dpsram_w4_d512 u_multport_dpram (
                   .clka               (clk),
                   .wea                (MC_ram_wra),
                   .addra              (MC_ram_addra[8:0]),
                   .dina               (MC_ram_dina),
                   .douta              (),
                   .clkb               (clk),
                   .web                (MC_ram_wrb),
                   .addrb              (FQ_din[8:0]),
                   .dinb               (MC_ram_dinb),
                   .doutb              (MC_ram_doutb)
                 );

  block_ram_w64 shared_buffer (
                  .clka               (clk),
                  .wea                (sram_wr_a),
                  .addra              (sram_addr_a[11:0]),
                  .dina               (sram_din_a),
                  .douta              (),
                  .clkb               (clk),
                  .web                (1'b0),
                  .addrb              (sram_addr_b[11:0]),
                  .dinb               (64'b0),
                  .doutb              (sram_dout_b)
                );

  //================================================================
  // Switch Queue Management Instances
  //================================================================
  switch_qm u_switch_qm_0 (
              .clk                (clk),
              .reset              (reset),
              .in_metadata        (in_metadata[19:0]),
              .frame_elig_time_ok_w (frame_eligible_time_OK[0] && ~frame_discard_flag[0]),
              .group_id           (group_id_in[0]),
              .frame_eligible_time (frame_eligible_time[0][TIMESTAMP_WIDTH-1:0]),
              .in_metadata_wr      (input_metadata_wr_en[0]),
              .pcp                (pcp[0]),
              .input_flow_ID      (flow_id[0]),
              .input_data_full    (qm_ptr_full_0),
              .ptr_rdy            (ptr_rdy0),
              .ptr_ack            (ptr_ack0),
              .ptr_dout           (qm_rd_ptr_dout_0),
              .local_clock        (local_clock)
            );

  switch_qm u_switch_qm_1 (
              .clk                (clk),
              .reset              (reset),
              .in_metadata        (in_metadata[19:0]),
              .frame_elig_time_ok_w (frame_eligible_time_OK[1]&& ~frame_discard_flag[1]),
              .group_id           (group_id_in[1]),
              .frame_eligible_time (frame_eligible_time[1][TIMESTAMP_WIDTH-1:0]),
              .in_metadata_wr      (input_metadata_wr_en[1]),
              .pcp                (pcp[1]),
              .input_flow_ID      (flow_id[1]),
              .input_data_full    (qm_ptr_full_1),
              .ptr_rdy            (ptr_rdy1),
              .ptr_ack            (ptr_ack1),
              .ptr_dout           (qm_rd_ptr_dout_1),
              .local_clock        (local_clock)
            );

  switch_qm u_switch_qm_2 (
              .clk                (clk),
              .reset              (reset),
              .in_metadata        (in_metadata[19:0]),
              .frame_elig_time_ok_w (frame_eligible_time_OK[2] && ~frame_discard_flag[2]),
              .group_id           (group_id_in[2]),
              .frame_eligible_time (frame_eligible_time[2][TIMESTAMP_WIDTH-1:0]),
              .in_metadata_wr      (input_metadata_wr_en[2]),
              .pcp                (pcp[2]),
              .input_flow_ID      (flow_id[2]),
              .input_data_full    (qm_ptr_full_2),
              .ptr_rdy            (ptr_rdy2),
              .ptr_ack            (ptr_ack2),
              .ptr_dout           (qm_rd_ptr_dout_2),
              .local_clock        (local_clock)
            );

  switch_qm u_switch_qm_3 (
              .clk                (clk),
              .reset              (reset),
              .in_metadata        (in_metadata[19:0]),
              .frame_elig_time_ok_w (frame_eligible_time_OK[3] && ~frame_discard_flag[3]),
              .group_id           (group_id_in[3]),
              .frame_eligible_time (frame_eligible_time[3][TIMESTAMP_WIDTH-1:0]),
              .in_metadata_wr      (input_metadata_wr_en[3]),
              .pcp                (pcp[3]),
              .input_flow_ID      (flow_id[3]),
              .input_data_full    (qm_ptr_full_3),
              .ptr_rdy            (ptr_rdy3),
              .ptr_ack            (ptr_ack3),
              .ptr_dout           (qm_rd_ptr_dout_3),
              .local_clock        (local_clock)
            );

  //================================================================
  // Frame Eligibility Calculator Instances
  //================================================================
  frame_eligbility_calculator u_frame_eligbility_calculator_0 (
                                .clk                (clk),
                                .reset              (reset),
                                .read_end_flag      (read_end_flag),
                                .group_id           (group_id_in[0]),
                                .arrival_time       (arrival_time),
                                .frame_length       (frame_length),
                                .start_flag         (start_flag[0]),
                                .flow_id            (flow_id[0][31:0]),
                                .frame_eligible_time (frame_eligible_time[0][TIMESTAMP_WIDTH-1:0]),
                                .frame_eligible_time_OK (frame_eligible_time_OK[0]),
                                .frame_discard_flag (frame_discard_flag[0])
                              );

  frame_eligbility_calculator u_frame_eligbility_calculator_1 (
                                .clk                (clk),
                                .reset              (reset),
                                .read_end_flag      (read_end_flag),
                                .group_id           (group_id_in[1]),
                                .arrival_time       (arrival_time),
                                .frame_length       (frame_length),
                                .start_flag         (start_flag[1]),
                                .flow_id            (flow_id[1][31:0]),
                                .frame_eligible_time (frame_eligible_time[1][TIMESTAMP_WIDTH-1:0]),
                                .frame_eligible_time_OK (frame_eligible_time_OK[1]),
                                .frame_discard_flag (frame_discard_flag[1])
                              );

  frame_eligbility_calculator u_frame_eligbility_calculator_2 (
                                .clk                (clk),
                                .reset              (reset),
                                .read_end_flag      (read_end_flag),
                                .group_id           (group_id_in[2]),
                                .arrival_time       (arrival_time),
                                .frame_length       (frame_length),
                                .start_flag         (start_flag[2]),
                                .flow_id            (flow_id[2][31:0]),
                                .frame_eligible_time (frame_eligible_time[2][TIMESTAMP_WIDTH-1:0]),
                                .frame_eligible_time_OK (frame_eligible_time_OK[2]),
                                .frame_discard_flag (frame_discard_flag[2])
                              );

  frame_eligbility_calculator u_frame_eligbility_calculator_3 (
                                .clk                (clk),
                                .reset              (reset),
                                .read_end_flag      (read_end_flag),
                                .group_id           (group_id_in[3]),
                                .arrival_time       (arrival_time),
                                .frame_length       (frame_length),
                                .start_flag         (start_flag[3]),
                                .flow_id            (flow_id[3][31:0]),
                                .frame_eligible_time (frame_eligible_time[3][TIMESTAMP_WIDTH-1:0]),
                                .frame_eligible_time_OK (frame_eligible_time_OK[3]),
                                .frame_discard_flag (frame_discard_flag[3])
                              );

  //================================================================
  // Local Clock Instance
  //================================================================
  local_clock u_local_clock (
                .clk                (clk),
                .reset              (reset),
                .local_clock        (local_clock)
              );

endmodule
