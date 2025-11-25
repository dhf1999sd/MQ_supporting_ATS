`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:TSN@NNS
// Engineer:Wenxue Wu
// Create Date:  2024/8/6
// Module Name: top
// Target Devices:ZYNQ
// Tool Versions:VIVADO 2023.2
// Description:
//
//////////////////////////////////////////////////////////////////////////////////

module top #(
    parameter IO_INTER_DATA_WIDTH = 64,
    parameter GMII_DATA_WIDTH     = 8
  ) (
    sys_clk,  //SYSTEM CLK
    sys_reset,
    //rgmii	  port_1
    rgmii_rxd_1,
    rgmii_rx_ctl_1,
    rgmii_rxc_1,
    rgmii_txd_1,
    rgmii_tx_ctl_1,
    rgmii_txc_1,
    phy_resetn_1,
    //rgmii	  port_2
    rgmii_rxd_2,
    rgmii_rx_ctl_2,
    rgmii_rxc_2,
    rgmii_txd_2,
    rgmii_tx_ctl_2,
    rgmii_txc_2,
    phy_resetn_2,
    //rgmii	  port_3
    rgmii_rxd_3,
    rgmii_rx_ctl_3,
    rgmii_rxc_3,
    rgmii_txd_3,
    rgmii_tx_ctl_3,
    rgmii_txc_3,
    phy_resetn_3,
    //rgmii	  port_4
    rgmii_rxd_4,
    rgmii_rx_ctl_4,
    rgmii_rxc_4,
    rgmii_txd_4,
    rgmii_tx_ctl_4,
    rgmii_txc_4,
    phy_resetn_4
  );

  //---------------------------parameters--------------------------------//

  //------------------------------ports_1----------------------------------//
  input sys_clk;
  input sys_reset;
  input [3:0] rgmii_rxd_1;
  input rgmii_rx_ctl_1;
  input rgmii_rxc_1;

  output [3:0] rgmii_txd_1;
  output rgmii_tx_ctl_1;
  output rgmii_txc_1;
  output phy_resetn_1;

  //------------------------------ports_2----------------------------------//
  input [3:0] rgmii_rxd_2;
  input rgmii_rx_ctl_2;
  input rgmii_rxc_2;

  output [3:0] rgmii_txd_2;
  output rgmii_tx_ctl_2;
  output rgmii_txc_2;
  output phy_resetn_2;
  //------------------------------ports_3----------------------------------//
  input [3:0] rgmii_rxd_3;
  input rgmii_rx_ctl_3;
  input rgmii_rxc_3;

  output [3:0] rgmii_txd_3;
  output rgmii_tx_ctl_3;
  output rgmii_txc_3;
  output phy_resetn_3;
  //------------------------------ports_4----------------------------------//
  input [3:0] rgmii_rxd_4;
  input rgmii_rx_ctl_4;
  input rgmii_rxc_4;

  output [3:0] rgmii_txd_4;
  output rgmii_tx_ctl_4;
  output rgmii_txc_4;
  output phy_resetn_4;



  //------------------------------regs-----------------------------------//

  //------------------------------wires----------------------------------//
  wire clk_15_625;
  wire clk_125;
  wire clk_200;
  wire mmcm_locked;
  wire core_reset_1;
  wire core_reset_2;
  wire core_reset_3;
  wire core_reset_4;
  wire clk_125_90_master_out;
  wire clk_125_master_out;
  wire mac_rx_valid_1;  // output wire m_axis_tvalidָʾ Master ׼������
  wire [IO_INTER_DATA_WIDTH-1 : 0] mac_rx_data_1;  // output wire [IO_INTER_DATA_WIDTH-1 : 0] m_axis_tdata��Ч������
  wire [GMII_DATA_WIDTH-1 : 0] mac_rx_keep_1;  // output wire [GMII_DATA_WIDTH-1 : 0] m_axis_tkeep
  wire mac_rx_last_1;  // output wire m_axis_tlast ָʾ packet �ı߽�


  wire mac_rx_ready_1;
  wire mac_rx_ready_2;
  wire mac_rx_ready_3;
  wire mac_rx_ready_4;

  wire mac_rx_valid_2;  // output wire m_axis_tvalidָʾ Master ׼������
  wire [IO_INTER_DATA_WIDTH-1 : 0] mac_rx_data_2;  // output wire [IO_INTER_DATA_WIDTH-1 : 0] m_axis_tdata��Ч������
  wire [GMII_DATA_WIDTH-1 : 0] mac_rx_keep_2;  // output wire [GMII_DATA_WIDTH-1 : 0] m_axis_tkeep
  wire mac_rx_last_2;  // output wire m_axis_tlast ָʾ packet �ı߽�


  wire mac_rx_valid_3;  // output wire m_axis_tvalidָʾ Master ׼������
  wire [IO_INTER_DATA_WIDTH-1 : 0] mac_rx_data_3;  // output wire [IO_INTER_DATA_WIDTH-1 : 0] m_axis_tdata��Ч������
  wire [GMII_DATA_WIDTH-1 : 0] mac_rx_keep_3;  // output wire [GMII_DATA_WIDTH-1 : 0] m_axis_tkeep
  wire mac_rx_last_3;  // output wire m_axis_tlast ָʾ packet �ı߽�



  wire mac_rx_valid_4;  // output wire m_axis_tvalidָʾ Master ׼������
  wire [IO_INTER_DATA_WIDTH-1 : 0] mac_rx_data_4;  // output wire [IO_INTER_DATA_WIDTH-1 : 0] m_axis_tdata��Ч������
  wire [GMII_DATA_WIDTH-1 : 0] mac_rx_keep_4;  // output wire [GMII_DATA_WIDTH-1 : 0] m_axis_tkeep
  wire mac_rx_last_4;  // output wire m_axis_tlast ָʾ packet �ı߽�



  wire mac_tx_valid_1;
  wire [IO_INTER_DATA_WIDTH-1 : 0] mac_tx_data_1;  //
  wire [GMII_DATA_WIDTH-1 : 0] mac_tx_keep_1;  //
  wire mac_tx_last_1;


  wire mac_tx_valid_2;
  wire [IO_INTER_DATA_WIDTH-1 : 0] mac_tx_data_2;  //
  wire [GMII_DATA_WIDTH-1 : 0] mac_tx_keep_2;  //
  wire mac_tx_last_2;

  wire mac_tx_valid_3;
  wire [IO_INTER_DATA_WIDTH-1 : 0] mac_tx_data_3;  //
  wire [GMII_DATA_WIDTH-1 : 0] mac_tx_keep_3;  //
  wire mac_tx_last_3;

  wire mac_tx_valid_4;
  wire [IO_INTER_DATA_WIDTH-1 : 0] mac_tx_data_4;  //
  wire [GMII_DATA_WIDTH-1 : 0] mac_tx_keep_4;  //

  wire mac_tx_last_4;
  wire mac_tx_ready_4;
  wire mac_tx_ready_3;
  wire mac_tx_ready_2;
  wire mac_tx_ready_1;

  wire [47:0] sour_mac_addr;
  wire [47:0] dest_mac_addr;
  wire [IO_INTER_DATA_WIDTH-1:0] arbiter_inout_data;
  wire arbiter_inout_wr;
  wire [GMII_DATA_WIDTH-1:0] arbiter_inout_ctrl;
  wire [3:0] in_scr_port;
  wire [15:0] out_src_port;
  wire [9:0] se_hash;
  wire se_req;
  wire src_lut_flag;
  wire [3:0] search_result;
  wire inout_rdy;
  wire [15:0] ethertype;
  wire [11:0] vlan_id;

  //-----------------------------assigns---------------------------------//


  reg [15:0] delay_cnt;





















  assign  phy_resetn_1 = (delay_cnt == 10'd50)? 1'b1 : 1'b0;//PHYоƬ��λ�źţ��͵�ƽ��Ч
  assign phy_resetn_2 = (delay_cnt == 10'd50) ? 1'b1 : 1'b0;
  assign phy_resetn_3 = (delay_cnt == 10'd50) ? 1'b1 : 1'b0;
  assign phy_resetn_4 = (delay_cnt == 10'd50) ? 1'b1 : 1'b0;

  assign reset = (delay_cnt == 10'd50) ? 1'b0 : 1'b1;  //�ⲿ��λ�źţ��ߵ�ƽ��Ч



  always @(posedge clk_125)
  begin
    if (!mmcm_locked)
      delay_cnt <= 10'd0;
    else
    begin
      if (delay_cnt == 10'd50)
        delay_cnt <= delay_cnt;
      else
        delay_cnt <= delay_cnt + 1'b1;
    end
  end




  //----------------------------instances--------------------------------//
  /*********************************************************************
  --clk_wiz_0
  --
  --	
  *********************************************************************/
  clk_wiz_0 u_clk (
              .clk_in1 (sys_clk),
              .clk_out1(clk_15_625),
              .clk_out2(clk_125),
              .clk_out3(clk_200),
              .clk_out4(clk_125_90),
              .locked  (mmcm_locked)
            );

  /*********************************************************************
  --_transmit_port_1
  --
  --	
  *********************************************************************/
  master_mac_transmit_rx_tx u_port_1 (
                              .clk_125(clk_125),
                              .clk_15_625(clk_15_625),
                              .clk_200(clk_200),
                              .clk_125_master_out(clk_125_master_out),
                              .clk_125_90_master_out(clk_125_90_master_out),
                              .mmcm_locked(mmcm_locked),
                              .reset(!mmcm_locked),
                              .core_reset(core_reset_1),
                              //rgmii_1
                              .rgmii_rxd(rgmii_rxd_1),
                              .rgmii_rx_ctl(rgmii_rx_ctl_1),
                              .rgmii_rxc(rgmii_rxc_1),
                              .rgmii_txd(rgmii_txd_1),
                              .rgmii_tx_ctl(rgmii_tx_ctl_1),
                              .rgmii_txc(rgmii_txc_1),
                              .mac_rx_valid(mac_rx_valid_1),  // output wire m_axis_tvalidָʾ Master ׼������
                              .mac_rx_data (mac_rx_data_1),   // output wire [IO_INTER_DATA_WIDTH-1 : 0] m_axis_tdata��Ч������
                              .mac_rx_keep(mac_rx_keep_1),  // output wire [GMII_DATA_WIDTH-1 : 0] m_axis_tkeep
                              .mac_rx_last(mac_rx_last_1),  // output wire m_axis_tlast ָʾ packet �ı߽�
                              .mac_rx_ready(mac_rx_ready_1),

                              .mac_tx_valid(mac_tx_valid_1),
                              .mac_tx_data (mac_tx_data_1),   //
                              .mac_tx_keep (mac_tx_keep_1),   //
                              .mac_tx_last (mac_tx_last_1),
                              .mac_tx_ready(mac_tx_ready_1)
                            );


  /*********************************************************************
  --_transmit_port_2
  --
  --	clk_125
  *********************************************************************/
  slave_mac_transmit_rx_tx u_port_2 (

                             .clk_125(clk_125_master_out),  //(clk_125_master_out),
                             .clk_125_90(clk_125_90_master_out),
                             .clk_15_625(clk_15_625),
                             .mmcm_locked(mmcm_locked),
                             .reset(!mmcm_locked),
                             .core_reset(core_reset_2),
                             //rgmii_2
                             .rgmii_rxd(rgmii_rxd_2),
                             .rgmii_rx_ctl(rgmii_rx_ctl_2),
                             .rgmii_rxc(rgmii_rxc_2),
                             .rgmii_txd(rgmii_txd_2),
                             .rgmii_tx_ctl(rgmii_tx_ctl_2),
                             .rgmii_txc(rgmii_txc_2),

                             .mac_rx_valid(mac_rx_valid_2),  // output wire m_axis_tvalidָʾ Master ׼������
                             .mac_rx_data (mac_rx_data_2),   // output wire [IO_INTER_DATA_WIDTH-1 : 0] m_axis_tdata��Ч������
                             .mac_rx_keep(mac_rx_keep_2),  // output wire [GMII_DATA_WIDTH-1 : 0] m_axis_tkeep
                             .mac_rx_last(mac_rx_last_2),  // output wire m_axis_tlast ָʾ packet �ı߽�
                             .mac_rx_ready(mac_rx_ready_2),
                             .mac_tx_valid(mac_tx_valid_2),  //input   data vaild
                             .mac_tx_data(mac_tx_data_2),  //  input   data
                             .mac_tx_keep(mac_tx_keep_2),  // input
                             .mac_tx_last(mac_tx_last_2),  //input ָ
                             .mac_tx_ready(mac_tx_ready_2)
                           );


  /*********************************************************************
  --_transmit_port_3
  --
  --	
  *********************************************************************/
  slave_mac_transmit_rx_tx u_port_3 (

                             .clk_125(clk_125_master_out),
                             .clk_125_90(clk_125_90_master_out),
                             .clk_15_625(clk_15_625),
                             .mmcm_locked(mmcm_locked),
                             .reset(!mmcm_locked),
                             .core_reset(core_reset_3),
                             //rgmii_3
                             .rgmii_rxd(rgmii_rxd_3),
                             .rgmii_rx_ctl(rgmii_rx_ctl_3),
                             .rgmii_rxc(rgmii_rxc_3),
                             .rgmii_txd(rgmii_txd_3),
                             .rgmii_tx_ctl(rgmii_tx_ctl_3),
                             .rgmii_txc(rgmii_txc_3),
                             .mac_rx_valid(mac_rx_valid_3),  // output wire m_axis_tvalidָʾ Master ׼������
                             .mac_rx_data (mac_rx_data_3),   // output wire [IO_INTER_DATA_WIDTH-1 : 0] m_axis_tdata��Ч������
                             .mac_rx_keep(mac_rx_keep_3),  // output wire [GMII_DATA_WIDTH-1 : 0] m_axis_tkeep
                             .mac_rx_last(mac_rx_last_3),  // output wire m_axis_tlast ָʾ packet �ı߽�
                             .mac_rx_ready(mac_rx_ready_3),
                             .mac_tx_valid(mac_tx_valid_3),  //input   data vaild
                             .mac_tx_data(mac_tx_data_3),  //  input   data
                             .mac_tx_keep(mac_tx_keep_3),  // input �ֽ�ʹ��
                             .mac_tx_last(mac_tx_last_3),  //input ָʾ���ݽ���
                             .mac_tx_ready(mac_tx_ready_3)
                           );
  /*********************************************************************
  --_transmit_port_4
  --
  --	
  *********************************************************************/
  slave_mac_transmit_rx_tx u_port_4 (
                             .clk_125(clk_125_master_out),
                             .clk_125_90(clk_125_90_master_out),
                             .clk_15_625(clk_15_625),
                             .mmcm_locked(mmcm_locked),
                             .reset(!mmcm_locked),
                             .core_reset(core_reset_4),
                             //rgmii_4
                             .rgmii_rxd(rgmii_rxd_4),
                             .rgmii_rx_ctl(rgmii_rx_ctl_4),
                             .rgmii_rxc(rgmii_rxc_4),
                             .rgmii_txd(rgmii_txd_4),
                             .rgmii_tx_ctl(rgmii_tx_ctl_4),
                             .rgmii_txc(rgmii_txc_4),

                             .mac_rx_valid(mac_rx_valid_4),  // output wire m_axis_tvalidָʾ Master ׼������
                             .mac_rx_data (mac_rx_data_4),   // output wire [IO_INTER_DATA_WIDTH-1 : 0] m_axis_tdata��Ч������
                             .mac_rx_keep(mac_rx_keep_4),  // output wire [GMII_DATA_WIDTH-1 : 0] m_axis_tkeep
                             .mac_rx_last(mac_rx_last_4),  // output wire m_axis_tlast ָʾ packet �ı߽�
                             .mac_rx_ready(mac_rx_ready_4),
                             .mac_tx_valid(mac_tx_valid_4),  //input   data vaild
                             .mac_tx_data(mac_tx_data_4),  //  input   data
                             .mac_tx_keep(mac_tx_keep_4),  // input
                             .mac_tx_last(mac_tx_last_4),  //input
                             .mac_tx_ready(mac_tx_ready_4)
                           );



  input_arbiter u_input_arbiter (
                  .in_rdy_1 (mac_rx_ready_1),
                  .in_rdy_2 (mac_rx_ready_2),
                  .in_rdy_3 (mac_rx_ready_3),
                  .in_rdy_4 (mac_rx_ready_4),
                  .in_last_1(mac_rx_last_1),
                  .in_last_2(mac_rx_last_2),
                  .in_last_3(mac_rx_last_3),
                  .in_last_4(mac_rx_last_4),
                  .in_data_1(mac_rx_data_1),
                  .in_ctrl_1(mac_rx_keep_1),
                  .in_wr_1  (mac_rx_valid_1),
                  .in_data_2(mac_rx_data_2),
                  .in_ctrl_2(mac_rx_keep_2),
                  .in_wr_2  (mac_rx_valid_2),
                  .in_data_3(mac_rx_data_3),
                  .in_ctrl_3(mac_rx_keep_3),
                  .in_wr_3  (mac_rx_valid_3),
                  .in_data_4(mac_rx_data_4),
                  .in_ctrl_4(mac_rx_keep_4),
                  .in_wr_4  (mac_rx_valid_4),
                  .reset  (!mmcm_locked),
                  .clk   (clk_125),
                  .out_data (arbiter_inout_data),
                  .out_ctrl (arbiter_inout_ctrl),
                  .out_wr   (arbiter_inout_wr),
                  .out_rdy  (inout_rdy),
                  .eop(eop),
                  .sof(sof),
                  .in_scr_port(in_scr_port)

                );


  ethernet_parser u_ethernet_parser (
                    .in_scr_port (in_scr_port),
                    .in_data     (arbiter_inout_data),
                    .in_ctrl     (arbiter_inout_ctrl),
                    .in_wr       (arbiter_inout_wr),
                    .reset       (!mmcm_locked),
                    .clk         (clk_125),
                    .dst_mac     (dest_mac_addr),
                    .dst_lut_flag(),
                    .src_lut_flag(src_lut_flag),
                    .src_mac     (sour_mac_addr),
                    .out_src_port(out_src_port[15:0]),
                    .ethertype   (ethertype[15:0]),
                    .vlan_id     (vlan_id[11:0]),
                    .eth_done    (),
                    .se_hash     (se_hash[9:0]),
                    .se_req      (se_req),
                    .aging_req   ()
                  );


  mac_addr_lut u_mac_addr_lut (
                 .clk          (clk_125),
                 .reset        (!mmcm_locked),
                 .src_lut_flag (src_lut_flag),
                 .dst_mac      (dest_mac_addr[47:0]),
                 .src_mac      (sour_mac_addr[47:0]),
                 .se_portmap   (out_src_port[15:0]),
                 .se_hash      (se_hash[9:0]),
                 .se_req       (se_req),
                 .aging_req    (),
                 .se_ack       (),
                 .se_nak       (),
                 .search_result(search_result),
                 .aging_ack    ()
               );




  shared_buffer_switch_top u_switch_top (
                             .mac_tx_valid_4(mac_tx_valid_4),  //input   data vaild
                             .mac_tx_data_4 (mac_tx_data_4),   //  input   data
                             .mac_tx_keep_4 (mac_tx_keep_4),   // input �ֽ�ʹ��
                             .mac_tx_last_4 (mac_tx_last_4),   //input ָʾ���ݽ���
                             .mac_tx_ready_4(mac_tx_ready_4),
                             .mac_tx_valid_3(mac_tx_valid_3),  //input   data vaild
                             .mac_tx_data_3 (mac_tx_data_3),   //  input   data
                             .mac_tx_keep_3 (mac_tx_keep_3),   // input �ֽ�ʹ��
                             .mac_tx_last_3 (mac_tx_last_3),   //input ָʾ���ݽ���
                             .mac_tx_ready_3(mac_tx_ready_3),

                             .mac_tx_valid_2(mac_tx_valid_2),  //input   data vaild
                             .mac_tx_data_2 (mac_tx_data_2),   //  input   data
                             .mac_tx_keep_2 (mac_tx_keep_2),   // input �ֽ�ʹ��
                             .mac_tx_last_2 (mac_tx_last_2),   //input ָʾ���ݽ���
                             .mac_tx_ready_2(mac_tx_ready_2),

                             .mac_tx_valid_1(mac_tx_valid_1),      //input   data vaild
                             .mac_tx_data_1 (mac_tx_data_1),       //  input   data
                             .mac_tx_keep_1 (mac_tx_keep_1),       // input �ֽ�ʹ��
                             .mac_tx_last_1 (mac_tx_last_1),       //input ָʾ���ݽ���
                             .mac_tx_ready_1(mac_tx_ready_1),
                             .clk           (clk_125),
                             .clk_15_625    (clk_15_625),
                             .reset         (!mmcm_locked),
                             .eop           (eop),
                             .sof           (sof),
                             .ethertype     (ethertype[15:0]),
                             .vlan_id       (vlan_id[11:0]),
                             .in_src_port   (out_src_port),
                             .search_result (search_result),
                             .in_data       (arbiter_inout_data),
                             .in_ctrl       (arbiter_inout_ctrl),
                             .in_rdy        (inout_rdy)
                           );















endmodule
