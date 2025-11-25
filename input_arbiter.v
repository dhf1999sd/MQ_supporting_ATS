`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:TSN@NNS
// Engineer:Wenxue Wu
// Create Date:  2023/11/14
// Module Name: input_arbiter
// Target Devices:ZYNQ
// Tool Versions:VIVADO 2023.2
// Description:Goes round-robin around the input queues and services one pkt
//              out of each (if available). Note that this is unfair for queues
//              that always receive small packets since they pile up!
//
//////////////////////////////////////////////////////////////////////////////////



module input_arbiter #(
    parameter                           DATA_WIDTH                 = 64    ,
    parameter                           CTRL_WIDTH                 = DATA_WIDTH / 8,
    parameter                           UDP_REG_SRC_WIDTH          = 2     ,
    parameter                           STAGE_NUMBER               = 3     ,
    parameter                           NUM_QUEUES                 = 4     ,
    parameter                           NUM_QUEUES_WIDTH           = log2(NUM_QUEUES),
    parameter                           NUM_STATES                 = 2     ,
    parameter                           IDLE                       = 0     ,
    parameter                           WR_PKT                     = 1     ,
    parameter                           WR_IFG                     = 2
  ) (                                                                 // --- data path interface
    output reg         [DATA_WIDTH-1: 0]        out_data                   ,
    output reg         [CTRL_WIDTH-1: 0]        out_ctrl                   ,
    output reg                          out_wr                     ,
    input                               out_rdy                    ,
    output reg         [NUM_QUEUES-1: 0]        in_scr_port                ,
    output reg                          eop                        ,
    output reg                          sof                        ,

    // interface to rx port1 queues

    input              [DATA_WIDTH-1: 0]        in_data_1                  ,
    input              [CTRL_WIDTH-1: 0]        in_ctrl_1                  ,
    input                               in_wr_1                    ,
    output                              in_rdy_1                   ,
    input                               in_last_1                  ,
    // interface to rx port2 queues
    input              [DATA_WIDTH-1: 0]        in_data_2                  ,
    input              [CTRL_WIDTH-1: 0]        in_ctrl_2                  ,
    input                               in_wr_2                    ,
    output                              in_rdy_2                   ,
    input                               in_last_2                  ,
    // interface to rx port3 queues
    input              [DATA_WIDTH-1: 0]        in_data_3                  ,
    input              [CTRL_WIDTH-1: 0]        in_ctrl_3                  ,
    input                               in_wr_3                    ,
    output                              in_rdy_3                   ,
    input                               in_last_3                  ,
    // interface to rx port4 queues
    input              [DATA_WIDTH-1: 0]        in_data_4                  ,
    input              [CTRL_WIDTH-1: 0]        in_ctrl_4                  ,
    input                               in_wr_4                    ,
    output                              in_rdy_4                   ,
    input                               in_last_4                  ,
    // --- Register interface
    // --- Misc
    input                               reset                      ,
    input                               clk
  );


  function integer log2;                                            //log functio
    input                               integer number             ;
    begin
      log2 = 0;
      while (2 ** log2 < number)
      begin
        log2 = log2 + 1;
      end
    end
  endfunction                                                       // log2

  // ------------ Internal Params --------


  // ------------- Regs/ wires -----------
  wire               [NUM_QUEUES-1: 0]        nearly_full                 ;
  wire               [NUM_QUEUES-1: 0]        empty                       ;
  wire               [DATA_WIDTH-1: 0]        in_data[NUM_QUEUES-1:0]  ;
  wire               [CTRL_WIDTH-1: 0]        in_ctrl[NUM_QUEUES-1:0]  ;
  wire                                in_last[NUM_QUEUES-1:0]  ;
  wire               [NUM_QUEUES-1: 0]        in_wr                       ;
  wire               [CTRL_WIDTH-1: 0]        fifo_out_ctrl[NUM_QUEUES-1:0]  ;
  wire               [DATA_WIDTH-1: 0]        fifo_out_data[NUM_QUEUES-1:0]  ;
  wire                                fifo_out_last[NUM_QUEUES-1:0]  ;
  reg                [NUM_QUEUES-1: 0]        rd_en                       ;
  wire               [NUM_QUEUES-1: 0]        cur_queue_plus1             ;
  reg                [NUM_QUEUES-1: 0]        cur_queue_next              ;
  reg                [NUM_STATES-1: 0]        state                       ;
  reg                [NUM_STATES-1: 0]        state_next                  ;
  reg                [CTRL_WIDTH-1: 0]        fifo_out_ctrl_prev          ;
  reg                [CTRL_WIDTH-1: 0]        fifo_out_ctrl_prev_next     ;
  wire               [CTRL_WIDTH-1: 0]        fifo_out_ctrl_sel           ;
  wire               [DATA_WIDTH-1: 0]        fifo_out_data_sel           ;
  wire                                fifo_out_last_sel           ;
  reg                [DATA_WIDTH-1: 0]        out_data_next               ;
  reg                [CTRL_WIDTH-1: 0]        out_ctrl_next               ;
  reg                                 out_wr_next                 ;
  reg                [NUM_QUEUES-1: 0]        cur_queue                   ;
  reg                                 eop_reg                     ;
  reg                                 sof_reg                     ;
  reg                                 sof_reg2                    ;
  reg                [   3: 0]        counter                     ;
  // ------------ Modules -------------
  generate                                                          //Cyclic treatment
    genvar i;
    for (i = 0; i < NUM_QUEUES; i = i + 1)
    begin : in_arb_queues
      in_arb_queues_fifo in_arb_fifo (
                           .clk                                (clk                       ),// input wire clk
                           .rst                                (reset                     ),// input wire rst
                           .din                                ({in_last[i], in_ctrl[i], in_data[i]}),// input wire [72 : 0] din
                           .wr_en                              (in_wr[i]                  ),// input wire wr_en
                           .rd_en                              (rd_en[i]                  ),// input wire rd_en
                           .dout({
                                   fifo_out_last[i], fifo_out_ctrl[i], fifo_out_data[i]
                                 }),                                                       // output wire [73 : 0] dout
                           .full                               (                          ),// output wire full
                           .almost_full                        (nearly_full[i]            ),// output wire almost_full
                           .empty                              (empty[i]                  ) // output wire empty
                         );
    end                                                             // block: in_arb_queues
  endgenerate
  // ------------- Logic ------------
  assign                              in_data[0]                  = in_data_1;
  assign                              in_ctrl[0]                  = in_ctrl_1;
  assign                              in_wr[0]                    = in_wr_1;
  assign                              in_rdy_1                    = !nearly_full[0];
  assign                              in_last[0]                  = in_last_1;
  assign                              in_data[1]                  = in_data_2;
  assign                              in_ctrl[1]                  = in_ctrl_2;
  assign                              in_wr[1]                    = in_wr_2;
  assign                              in_rdy_2                    = !nearly_full[1];
  assign                              in_last[1]                  = in_last_2;
  assign                              in_data[2]                  = in_data_3;
  assign                              in_ctrl[2]                  = in_ctrl_3;
  assign                              in_wr[2]                    = in_wr_3;
  assign                              in_rdy_3                    = !nearly_full[2];
  assign                              in_last[2]                  = in_last_3;
  assign                              in_data[3]                  = in_data_4;
  assign                              in_ctrl[3]                  = in_ctrl_4;
  assign                              in_wr[3]                    = in_wr_4;
  assign                              in_rdy_4                    = !nearly_full[3];
  assign                              in_last[3]                  = in_last_4;


  /* disable regs for this module */
  assign                              cur_queue_plus1             = (cur_queue == NUM_QUEUES - 1) ? 0 : cur_queue + 1;
  assign                              fifo_out_ctrl_sel           = fifo_out_ctrl[cur_queue];
  assign                              fifo_out_data_sel           = fifo_out_data[cur_queue];
  assign                              fifo_out_last_sel           = fifo_out_last[cur_queue];

  always @(*)
  begin
    state_next              = state;
    cur_queue_next          = cur_queue;
    fifo_out_ctrl_prev_next = fifo_out_ctrl_prev;
    out_wr_next             = 0;
    out_ctrl_next           = fifo_out_ctrl_sel;
    out_data_next           = fifo_out_data_sel;
    rd_en                   = 0;
    eop_reg                 = 0;
    sof_reg2                = 0;

    case (state)
      /* cycle between input queues until one is not empty */
      IDLE:
      begin
        if (!empty[cur_queue] && out_rdy)
        begin                     //
          state_next = WR_PKT;
          rd_en[cur_queue] = 1;
          fifo_out_ctrl_prev_next = STAGE_NUMBER;
          sof_reg2 = 1;

        end
        if (empty[cur_queue] && out_rdy)
        begin
          cur_queue_next = cur_queue_plus1;
        end
      end
      /* wait until eop */
      WR_PKT:
      begin
        /* if this is the last word then write it and get out */
        if (out_rdy & fifo_out_last_sel)
        begin                      //
          out_wr_next = 1;
          state_next = WR_IFG;
          cur_queue_next = cur_queue_plus1;
          eop_reg = 1;
        end        /* otherwise read and write as usual */
        else if (out_rdy & !empty[cur_queue])
        begin
          fifo_out_ctrl_prev_next = fifo_out_ctrl_sel;
          out_wr_next = 1;
          rd_en[cur_queue] = 1;
          //             eop_reg = 1;
        end
      end                                                           // case: WR_PKT

      WR_IFG:
      begin
        if (counter == 15)
          state_next = IDLE;
        else
          state_next = WR_IFG;
      end
      default:
      begin
        state_next = IDLE;
      end
    endcase                                                         // case(state)
  end                                                               // always @ (*)




  always @(posedge clk)
  begin
    if (reset)
      counter <= 0;
    else if (state_next == WR_IFG)
      counter <= counter + 1;
    else
      counter <= 0;
  end

  always @(posedge clk)
  begin
    if (reset)
    begin
      state <= IDLE;
      cur_queue <= 0;
      fifo_out_ctrl_prev <= 1;
      out_wr <= 0;
      out_ctrl <= 1;
      out_data <= 0;
      eop <= 0;
      in_scr_port <= 0;
      sof_reg <= 0;
      sof <= 0;
    end
    else
    begin
      state <= state_next;
      cur_queue <= cur_queue_next;
      fifo_out_ctrl_prev <= fifo_out_ctrl_prev_next;
      out_wr <= out_wr_next;
      out_ctrl <= out_ctrl_next;
      out_data <= out_data_next;
      eop <= eop_reg;
      sof_reg <= sof_reg2;
      sof <= sof_reg;
      in_scr_port <= cur_queue;
    end
  end

endmodule                                                           // input_arbiter
