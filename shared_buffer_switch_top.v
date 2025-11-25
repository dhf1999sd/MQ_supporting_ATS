`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:TSN@NNS
// Engineer:Wenxue Wu
// Create Date:  2024/8/6
// Module Name: shared_buffer_switch_top
// Target Devices:ZYNQ
// Tool Versions:VIVADO 2023.2
// Description:
//
//////////////////////////////////////////////////////////////////////////////////


module shared_buffer_switch_top #(
    parameter                           DATA_WIDTH                  = 64    ,
    parameter                           CTRL_WIDTH                  = DATA_WIDTH / 8
  ) (                                                               // --- register interface
    // --- output to data path interface
    output                              mac_tx_valid_4             ,//
    output               [DATA_WIDTH-1: 0]      mac_tx_data_4              ,//
    output               [CTRL_WIDTH-1: 0]      mac_tx_keep_4              ,//
    output                              mac_tx_last_4              ,//
    input                               mac_tx_ready_4             ,

    output                              mac_tx_valid_3             ,//
    output               [DATA_WIDTH-1: 0]      mac_tx_data_3              ,//
    output               [CTRL_WIDTH-1: 0]      mac_tx_keep_3              ,//
    output                              mac_tx_last_3              ,//
    input                               mac_tx_ready_3             ,


    output                              mac_tx_valid_2             ,//
    output               [DATA_WIDTH-1: 0]      mac_tx_data_2              ,//
    output               [CTRL_WIDTH-1: 0]      mac_tx_keep_2              ,//
    output                              mac_tx_last_2              ,//
    input                               mac_tx_ready_2             ,

    output                              mac_tx_valid_1             ,//
    output               [DATA_WIDTH-1: 0]      mac_tx_data_1              ,//
    output               [CTRL_WIDTH-1: 0]      mac_tx_keep_1              ,//
    output                              mac_tx_last_1              ,//
    input                               mac_tx_ready_1             ,
    // --- input from data path interface
    input                [DATA_WIDTH-1: 0]      in_data                    ,
    input                [CTRL_WIDTH-1: 0]      in_ctrl                    ,
    input                [  15: 0]      ethertype                  ,
    input                [  11: 0]      vlan_id                    ,
    output wire                         in_rdy                     ,
    input                [   3: 0]      search_result              ,
    input                               eop                        ,
    input                               sof                        ,
    input                [  15: 0]      in_src_port                ,
    input                               clk                        ,
    input                               reset                      ,
    input                               clk_15_625
  );




  wire               [  63: 0]        i_cell_data_fifo_dout       ;
  wire               [   3: 0]        group_id                    ;
  wire               [  63: 0]        o_cell_fifo_din             ;
  wire                                i_cell_ptr_fifo_wr          ;
  wire                                i_cell_data_fifo_wr         ;
  wire               [  22: 0]        i_cell_ptr_fifo_dout        ;
  wire               [  31: 0]        flow_ID                     ;
  wire               [   2: 0]        priority                    ;
  wire               [   3: 0]        o_cell_fifo_sel             ;

  wire               [   3: 0]        o_vaild                     ;
  wire               [   2: 0]        o_pad_num_64                ;
  wire               [   3: 0]        o_cell_bp                   ;




  assign                              in_rdy                      = 1;




  switch_pre u_switch_pre (
               .clk                                (clk                       ),
               .reset                              (reset                     ),
               .sof                                (sof                       ),
               .ethertype                          (ethertype[15:0]           ),
               .vlan_id                            (vlan_id[11:0]             ),
               .group_id                           (group_id[3:0]             ),
               .eop                                (eop                       ),
               .din                                (in_data                   ),
               .in_ctrl                            (in_ctrl                   ),
               .in_src_port                        (in_src_port               ),
               .search_result                      (search_result             ),
               .flow_ID                            (flow_ID[31:0]             ),
               .priority                           (priority[2:0]             ),
               .i_cell_data_fifo_dout              (i_cell_data_fifo_dout     ),
               .i_cell_data_fifo_wr                (i_cell_data_fifo_wr       ),
               .i_cell_ptr_fifo_dout               (i_cell_ptr_fifo_dout      ),
               .i_cell_ptr_fifo_wr                 (i_cell_ptr_fifo_wr        ),
               .i_cell_bp                          (i_cell_bp                 )
             );


  shared_buffer_core u_shared_buffer_core(
                       .clk                                (clk                       ),
                       .reset                              (reset                     ),
                       .in_flow_ID                         (flow_ID[31:0]             ),
                       .priority                           (priority[2:0]             ),
                       .i_cell_data_fifo_din               (i_cell_data_fifo_dout     ),
                       .i_cell_data_fifo_wr                (i_cell_data_fifo_wr       ),
                       .i_cell_ptr_fifo_din                (i_cell_ptr_fifo_dout      ),
                       .i_cell_ptr_fifo_wr                 (i_cell_ptr_fifo_wr        ),
                       .i_cell_bp                          (i_cell_bp                 ),
                       .group_id                           (group_id[3:0]             ),
                       .o_cell_fifo_wr                     (o_cell_fifo_wr            ),
                       .o_cell_fifo_sel                    (o_cell_fifo_sel           ),
                       .o_cell_fifo_din                    (o_cell_fifo_din           ),
                       .o_cell_first                       (o_cell_first              ),
                       .o_cell_last                        (o_cell_last               ),
                       .o_pad_num_64                       (o_pad_num_64[2:0]         ),
                       .o_cell_bp                          (o_cell_bp[3:0]            ),
                       .o_vaild                            (o_vaild[3:0]              )
                     );


  switch_post_top u_switch_post_top (
                    .clk                                (clk                       ),
                    .clk_15_625                         (clk_15_625                ),
                    .reset                              (reset                     ),
                    .o_cell_first                       (o_cell_first              ),
                    .o_cell_last                        (o_cell_last               ),
                    .o_pad_num_64                       (o_pad_num_64              ),
                    .o_cell_bp                          (o_cell_bp[3:0]            ),
                    .o_vaild                            (o_vaild[3:0]              ),
                    .pktout_data_wr_0                   (o_cell_fifo_sel[0]&o_cell_fifo_wr),
                    .pktout_data_0                      (o_cell_fifo_din           ),
                    .pktout_data_wr_1                   (o_cell_fifo_sel[1]&o_cell_fifo_wr),
                    .pktout_data_1                      (o_cell_fifo_din           ),
                    .pktout_data_wr_2                   (o_cell_fifo_sel[2]&o_cell_fifo_wr),
                    .pktout_data_2                      (o_cell_fifo_din           ),
                    .pktout_data_wr_3                   (o_cell_fifo_sel[3]&o_cell_fifo_wr),
                    .pktout_data_3                      (o_cell_fifo_din           ),

                    .m_axis_tready_0                    (mac_tx_ready_1            ),
                    .m_axis_tready_1                    (mac_tx_ready_2            ),
                    .m_axis_tready_2                    (mac_tx_ready_3            ),
                    .m_axis_tready_3                    (mac_tx_ready_4            ),

                    .m_axis_tvalid_0                    (mac_tx_valid_1            ),
                    .m_axis_tdata_0                     (mac_tx_data_1             ),
                    .m_axis_tkeep_0                     (mac_tx_keep_1             ),
                    .m_axis_tlast_0                     (mac_tx_last_1             ),

                    .m_axis_tvalid_1                    (mac_tx_valid_2            ),
                    .m_axis_tdata_1                     (mac_tx_data_2[63 : 0]     ),
                    .m_axis_tkeep_1                     (mac_tx_keep_2[7 : 0]      ),
                    .m_axis_tlast_1                     (mac_tx_last_2             ),

                    .m_axis_tvalid_2                    (mac_tx_valid_3            ),
                    .m_axis_tdata_2                     (mac_tx_data_3[63 : 0]     ),
                    .m_axis_tkeep_2                     (mac_tx_keep_3[7 : 0]      ),
                    .m_axis_tlast_2                     (mac_tx_last_3             ),

                    .m_axis_tvalid_3                    (mac_tx_valid_4            ),
                    .m_axis_tdata_3                     (mac_tx_data_4[63 : 0]     ),
                    .m_axis_tkeep_3                     (mac_tx_keep_4[7 : 0]      ),
                    .m_axis_tlast_3                     (mac_tx_last_4             )

                  );
endmodule

