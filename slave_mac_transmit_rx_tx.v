`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:TSN@NNS
// Engineer:Wenxue Wu
// Create Date:  2024/8/6
// Module Name: slave_mac_transmit_rx_tx
// Target Devices:ZYNQ
// Tool Versions:VIVADO 2023.2
// Description:
//
//////////////////////////////////////////////////////////////////////////////////


module slave_mac_transmit_rx_tx (

    //           gtx_clk,
    //       gtx_clk90,

    clk_125,  //mmcm_clk_125m
    clk_125_90,
    clk_15_625,  //mmcm_clk_15.625m
    mmcm_locked,  //mmcm_clk_locked
    reset,  //�ⲿ��λ�ź�
    core_reset,
    rgmii_rxd,
    rgmii_rx_ctl,
    rgmii_rxc,
    rgmii_txd,
    rgmii_tx_ctl,
    rgmii_txc,

    mac_rx_valid,  // output wire m_axis_tvalidָʾ Master
    mac_rx_data,  // output wire [63 : 0] m_axis_tdata
    mac_rx_keep,  // output wire [7 : 0] m_axis_tkeep
    mac_rx_last,  // output wire m_axis_tlast ָʾ packet
    mac_rx_ready,
    mac_tx_valid,
    mac_tx_data,  //
    mac_tx_keep,  //
    mac_tx_last,
    mac_tx_ready

  );

  //------------------------------ports----------------------------------//

  input clk_125;
  input clk_125_90;

  input clk_15_625;
  //  input                   gtx_clk;
  //input                   gtx_clk90;
  input mmcm_locked;
  input reset;  //high
  output core_reset;


  input [3:0] rgmii_rxd;
  input rgmii_rx_ctl;
  input rgmii_rxc;
  output [3:0] rgmii_txd;
  output rgmii_tx_ctl;
  output rgmii_txc;

  //-------------------------------------inter_data----------------------//

  output mac_rx_valid;  // output wire m_axis_tvalidָʾ Master ׼������

  output  [63:0]  mac_rx_data;  // output wire [63 : 0] m_axis_tdata��Ч������
  output [7:0] mac_rx_keep;  // output wire [7 : 0] m_axis_tkeep
  output mac_rx_last;  // output wire m_axis_tlast ָʾ packet �ı߽�
  input mac_rx_ready;
  input [63:0] mac_tx_data;
  input mac_tx_valid;
  input [7:0] mac_tx_keep;  //
  input mac_tx_last;
  output mac_tx_ready;






  //------------------------------regs-----------------------------------//

  //------------------------------wires----------------------------------//
  wire        tx_reset;
  wire        rx_reset;
  wire        glbl_rst_intn;
  wire        gtx_resetn;
  wire        s_axi_resetn;
  wire        core_reset;
  wire        rx_mac_aclk;  // MAC Rx clock
  wire        tx_mac_aclk;  // MAC Tx clock
  // MAC receiver client I/F
  wire [ 7:0] rx_axis_mac_tdata;
  wire        rx_axis_mac_tvalid;
  wire        rx_axis_mac_tlast;
  wire        rx_axis_mac_tuser;
  // MAC transmitter client I/F
  wire [ 7:0] tx_axis_mac_tdata;
  wire        tx_axis_mac_tvalid;
  wire        tx_axis_mac_tready;
  wire        tx_axis_mac_tlast;
  // AXI-Lite interface
  wire [11:0] s_axi_awaddr;
  wire        s_axi_awvalid;
  wire        s_axi_awready;
  wire [31:0] s_axi_wdata;
  wire        s_axi_wvalid;
  wire        s_axi_wready;
  wire [ 1:0] s_axi_bresp;
  wire        s_axi_bvalid;
  wire        s_axi_bready;
  wire [11:0] s_axi_araddr;
  wire        s_axi_arvalid;
  wire        s_axi_arready;
  wire [31:0] s_axi_rdata;
  wire [ 1:0] s_axi_rresp;
  wire        s_axi_rvalid;
  wire        s_axi_rready;

  wire        m_axis_tvalid1;
  wire [63:0] m_axis_tdata1;
  wire [ 7:0] m_axis_tkeep1;
  wire        m_axis_tready1;
  wire        m_axis_tlast1;
  wire        m_axis_tvalid2;
  wire [63:0] m_axis_tdata2;
  wire [ 7:0] m_axis_tkeep2;
  wire        m_axis_tready2;
  wire        m_axis_tlast2;
  wire        m_axis_tvalid3;
  wire [63:0] m_axis_tdata3;
  wire [ 7:0] m_axis_tkeep3;
  wire        m_axis_tready3;
  wire        m_axis_tlast3;
  wire        m_axis_tvalid4;
  wire [63:0] m_axis_tdata4;
  wire [ 7:0] m_axis_tkeep4;
  wire        m_axis_tready4;
  wire        m_axis_tlast4;

  wire        m_axis_tvalid5;
  wire [ 7:0] m_axis_tdata5;
  wire [ 0:0] m_axis_tkeep5;
  wire        m_axis_tready5;
  wire        m_axis_tlast5;


  wire        mac_tx_ready;

  //-----------------------------assigns---------------------------------//

  //----------------------------instances--------------------------------//

  /*********************************************************************
  --tri_mode_ethernet_mac_0_example_design_resets
  --
  --	
  *********************************************************************/
  tri_mode_ethernet_mac_0_example_design_resets system_resets (
                                                  // clocks
                                                  .s_axi_aclk (clk_125),
                                                  .gtx_clk    (clk_125),
                                                  .core_clk   (clk_15_625),
                                                  // asynchronous resets
                                                  .glbl_rst   (reset),       //
                                                  .reset_error(1'b0),
                                                  .rx_reset   (rx_reset),    //tx_reset
                                                  .tx_reset   (tx_reset),

                                                  .dcm_locked(mmcm_locked),
                                                  // synchronous reset outputs
                                                  .glbl_rst_intn(glbl_rst_intn),
                                                  .gtx_resetn(gtx_resetn),
                                                  .s_axi_resetn(s_axi_resetn),
                                                  .phy_resetn(),
                                                  .chk_resetn(),
                                                  .core_reset(core_reset)
                                                );
  /*********************************************************************
  --Instantiate the Tri-Mode Ethernet MAC core
  --
  --	
  *********************************************************************/
  tri_mode_ethernet_mac_slave u_tri_mode_ethernet_mac (
                                .gtx_clk    (clk_125),        // input wire gtx_clk
                                .gtx_clk90  (clk_125_90),     // input wire gtx_clk90
                                // asynchronous reset
                                .glbl_rstn  (glbl_rst_intn),
                                .rx_axi_rstn(1'b1),
                                .tx_axi_rstn(1'b1),

                                // Receiver Interface
                                .rx_statistics_vector(),
                                .rx_statistics_valid (),

                                .rx_mac_aclk       (rx_mac_aclk),
                                .rx_reset          (rx_reset),
                                .rx_axis_mac_tdata (rx_axis_mac_tdata),
                                .rx_axis_mac_tvalid(rx_axis_mac_tvalid),
                                .rx_axis_mac_tlast (rx_axis_mac_tlast),
                                .rx_axis_mac_tuser (rx_axis_mac_tuser),

                                // Transmitter Interface
                                .tx_ifg_delay        (8'd0),
                                .tx_statistics_vector(),
                                .tx_statistics_valid (),

                                .tx_mac_aclk       (tx_mac_aclk),
                                .tx_reset          (tx_reset),
                                .tx_axis_mac_tdata (tx_axis_mac_tdata),
                                .tx_axis_mac_tvalid(tx_axis_mac_tvalid),
                                .tx_axis_mac_tlast (tx_axis_mac_tlast),
                                .tx_axis_mac_tuser (1'b0),
                                .tx_axis_mac_tready(tx_axis_mac_tready),
                                // Flow Control
                                .pause_req         (1'b0),
                                .pause_val         (16'd0),
                                // Speed Control
                                .speedis100        (),
                                .speedis10100      (),

                                // RGMII Interface
                                .rgmii_txd           (rgmii_txd),
                                .rgmii_tx_ctl        (rgmii_tx_ctl),
                                .rgmii_txc           (rgmii_txc),
                                .rgmii_rxd           (rgmii_rxd),
                                .rgmii_rx_ctl        (rgmii_rx_ctl),
                                .rgmii_rxc           (rgmii_rxc),
                                .inband_link_status  (),
                                .inband_clock_speed  (),
                                .inband_duplex_status(),

                                // AXI lite interface
                                .s_axi_aclk   (clk_125),
                                .s_axi_resetn (s_axi_resetn),
                                .s_axi_awaddr (s_axi_awaddr),
                                .s_axi_awvalid(s_axi_awvalid),
                                .s_axi_awready(s_axi_awready),
                                .s_axi_wdata  (s_axi_wdata),
                                .s_axi_wvalid (s_axi_wvalid),
                                .s_axi_wready (s_axi_wready),
                                .s_axi_bresp  (s_axi_bresp),
                                .s_axi_bvalid (s_axi_bvalid),
                                .s_axi_bready (s_axi_bready),
                                .s_axi_araddr (s_axi_araddr),
                                .s_axi_arvalid(s_axi_arvalid),
                                .s_axi_arready(s_axi_arready),
                                .s_axi_rdata  (s_axi_rdata),
                                .s_axi_rresp  (s_axi_rresp),
                                .s_axi_rvalid (s_axi_rvalid),
                                .s_axi_rready (s_axi_rready),
                                .mac_irq      ()
                              );







  reg error_flag;


  iput_buffer_data_fifo_rx rx_indicated_error (
                             .s_axis_aresetn(gtx_resetn),          // input wire s_axis_aresetn
                             .s_axis_aclk   (rx_mac_aclk),         // input wire s_axis_aclk
                             .s_axis_tvalid (rx_axis_mac_tvalid),  // input wire s_axis_tvalid
                             .s_axis_tready (),                    // output wire s_axis_tready
                             .s_axis_tdata  (rx_axis_mac_tdata),   // input wire [63 : 0] s_axis_tdata
                             .s_axis_tkeep  (1),                   // input wire [7 : 0] s_axis_tkeep
                             .s_axis_tlast  (rx_axis_mac_tlast),   // input wire s_axis_tlast
                             .m_axis_tvalid (m_axis_tvalid5),      // output wire m_axis_tvalid
                             .m_axis_tready (m_axis_tready5),      // input wire m_axis_tready
                             .m_axis_tdata  (m_axis_tdata5),       // output wire [63 : 0] m_axis_tdata
                             .m_axis_tkeep  (m_axis_tkeep5),       // output wire [7 : 0] m_axis_tkeep
                             .m_axis_tlast  (m_axis_tlast5)        // output wire m_axis_tlast
                           );


  always @(rx_axis_mac_tlast)
  begin
    if (rx_axis_mac_tlast)
      error_flag = rx_axis_mac_tlast & rx_axis_mac_tuser;
  end




  /*********************************************************************
  --rx_axis_dwidth_converter
  --
  --	
  *********************************************************************/
  axis_dwidth_converter_RX rx_axis_dwidth_converter0 (   //��������λ��ת��
                             .aclk(rx_mac_aclk),  // input wire aclk   ���ն�ʱ��
                             .aresetn(gtx_resetn),  // input wire aresetn
                             .s_axis_tvalid(m_axis_tvalid5 & !error_flag),  // input wire s_axis_tvalid
                             .s_axis_tready(m_axis_tready5),  // output wire s_axis_tready
                             .s_axis_tdata(m_axis_tdata5),  // input wire [7 : 0] s_axis_tdata
                             .s_axis_tkeep(m_axis_tkeep5),  // input wire [0 : 0] s_axis_tkeep
                             .s_axis_tlast(m_axis_tlast5),  // input wire s_axis_tlast
                             .m_axis_tvalid(m_axis_tvalid3),  // output wire m_axis_tvalid
                             .m_axis_tready(m_axis_tready3),  // input wire m_axis_tready
                             .m_axis_tdata(m_axis_tdata3),  // output wire [63 : 0] m_axis_tdata
                             .m_axis_tkeep(m_axis_tkeep3),  // output wire [7 : 0] m_axis_tkeep
                             .m_axis_tlast(m_axis_tlast3)  // output wire m_axis_tlast

                           );



  /*********************************************************************
  --rx_async_fifo
  --
  --	
  *********************************************************************/
  axis_data_fifo_rx_async rx_fifo_0 (  //�첽FIFO
                            .s_axis_aresetn(gtx_resetn),      // input wire s_axis_aresetn
                            //
                            .s_axis_aclk   (rx_mac_aclk),     // input wire s_axis_aclk
                            .s_axis_tvalid (m_axis_tvalid3),  // input wire s_axis_tvalid
                            .s_axis_tready (m_axis_tready3),  // output wire s_axis_tready
                            .s_axis_tdata  (m_axis_tdata3),   // input wire [63 : 0] s_axis_tdata
                            .s_axis_tkeep  (m_axis_tkeep3),   // input wire [7 : 0] s_axis_tkeep
                            .s_axis_tlast  (m_axis_tlast3),   // input wire s_axis_tlast

                            .m_axis_aclk  (clk_15_625),      // input wire m_axis_aclk
                            .m_axis_tvalid(m_axis_tvalid4),  // output wire m_axis_tvalid
                            .m_axis_tready(m_axis_tready4),  // input wire m_axis_tready
                            .m_axis_tdata (m_axis_tdata4),   // output wire [63 : 0] m_axis_tdata
                            .m_axis_tkeep (m_axis_tkeep4),   // output wire [7 : 0] m_axis_tkeep
                            .m_axis_tlast (m_axis_tlast4)    // output wire m_axis_tlast
                            // output wire [31 : 0] axis_rd_data_count
                          );
  /*********************************************************************
  --rx_packet_fifo
  --
  --	
  *********************************************************************/
  axis_data_fifo_rx_async_buffer rx_fifo_1 (
                                   .s_axis_aresetn(~core_reset),     // input wire s_axis_aresetn
                                   .s_axis_aclk   (clk_15_625),      // input wire s_axis_aclk
                                   .s_axis_tvalid (m_axis_tvalid4),  // input wire s_axis_tvalid
                                   .s_axis_tready (m_axis_tready4),  // output wire s_axis_tready
                                   .s_axis_tdata  (m_axis_tdata4),   // input wire [63 : 0] s_axis_tdata
                                   .s_axis_tkeep  (m_axis_tkeep4),   // input wire [7 : 0] s_axis_tkeep
                                   .s_axis_tlast  (m_axis_tlast4),   // input wire s_axis_tlast

                                   .m_axis_aclk(clk_125),
                                   .m_axis_tvalid     (mac_rx_valid),    // output wire m_axis_tvalidָʾ Master ׼������
                                   .m_axis_tready     (mac_rx_ready),// (1'b1),            // input wire m_axis_tready//ָʾ Slave ׼������
                                   .m_axis_tdata      (mac_rx_data),     // output wire [63 : 0] m_axis_tdata��Ч������
                                   .m_axis_tkeep(mac_rx_keep),  // output wire [7 : 0] m_axis_tkeep
                                   .m_axis_tlast(mac_rx_last)  // output wire [0 : 0] m_axis_tuser

                                 );

  /*********************************************************************
  --axis_data_fifo_1
  *********************************************************************/
  axis_data_fifo_tx_inter tx_async_fifo_0 (  //asyn FIFO
                            .s_axis_aresetn(~core_reset),     // input wire s_axis_aresetn
                            .s_axis_aclk   (clk_15_625),      // input wire s_axis_aclk
                            .s_axis_tvalid (mac_tx_valid),    // input wire s_axis_tvalid
                            .s_axis_tready (mac_tx_ready),    // output wire s_axis_tready
                            .s_axis_tdata  (mac_tx_data),     // input wire [63 : 0] s_axis_tdata
                            .s_axis_tkeep  (mac_tx_keep),     // input wire [7 : 0] s_axis_tkeep
                            .s_axis_tlast  (mac_tx_last),     // input wire s_axis_tlast
                            .s_axis_tuser  (1'b0),            // input wire [0 : 0] s_axis_tuser
                            .m_axis_aclk   (tx_mac_aclk),     // input wire m_axis_aclk
                            .m_axis_tvalid (m_axis_tvalid1),  // output wire m_axis_tvalid
                            .m_axis_tready (m_axis_tready1),  // input wire m_axis_tready
                            .m_axis_tdata  (m_axis_tdata1),   // output wire [63 : 0] m_axis_tdata
                            .m_axis_tkeep  (m_axis_tkeep1),   // output wire [7 : 0] m_axis_tkeep
                            .m_axis_tlast  (m_axis_tlast1)    // output wire m_axis_tlast
                            // output wire [31 : 0] axis_wr_data_count
                          );
  /*********************************************************************
  --tx_packet_fifo
  *********************************************************************/
  axis_data_fifo_tx tx_packet_fifo_1 (  //
                      .s_axis_aresetn(gtx_resetn),      // input wire s_axis_aresetn
                      .s_axis_aclk   (tx_mac_aclk),     // input wire s_axis_aclk
                      .s_axis_tvalid (m_axis_tvalid1),  // input wire s_axis_tvalid
                      .s_axis_tready (m_axis_tready1),  // output wire s_axis_tready
                      .s_axis_tdata  (m_axis_tdata1),   // input wire [63 : 0] s_axis_tdata
                      .s_axis_tkeep  (m_axis_tkeep1),   // input wire [7 : 0] s_axis_tkeep
                      .s_axis_tlast  (m_axis_tlast1),   // input wire s_axis_tlast
                      .s_axis_tuser  (1'b0),            // input wire [0 : 0] s_axis_tuser
                      .m_axis_tvalid (m_axis_tvalid2),  // output wire m_axis_tvalid
                      .m_axis_tready (m_axis_tready2),  // input wire m_axis_tready
                      .m_axis_tdata  (m_axis_tdata2),   // output wire [63 : 0] m_axis_tdata
                      .m_axis_tkeep  (m_axis_tkeep2),   // output wire [7 : 0] m_axis_tkeep
                      .m_axis_tlast  (m_axis_tlast2)    // output wire m_axis_tlast
                      // output wire [0 : 0] m_axis_tuser
                    );
  /*********************************************************************
  --tx_axis_dwidth_converter  --64-8
  *********************************************************************/
  axis_dwidth_converter_TX tx_converter (
                             .aclk         (tx_mac_aclk),         // input wire aclk
                             .aresetn      (gtx_resetn),          // input wire aresetn
                             .s_axis_tvalid(m_axis_tvalid2),      // input wire s_axis_tvalid
                             .s_axis_tready(m_axis_tready2),      // output wire s_axis_tready
                             .s_axis_tdata (m_axis_tdata2),       // input wire [63 : 0] s_axis_tdata
                             .s_axis_tkeep (m_axis_tkeep2),       // input wire [7 : 0] s_axis_tkeep
                             .s_axis_tlast (m_axis_tlast2),       // input wire s_axis_tlast
                             .m_axis_tvalid(tx_axis_mac_tvalid),  // output wire m_axis_tvalid
                             .m_axis_tready(tx_axis_mac_tready),  // input wire m_axis_tready
                             .m_axis_tdata (tx_axis_mac_tdata),   // output wire [7 : 0] m_axis_tdata
                             .m_axis_tkeep (),                    // output wire [0 : 0] m_axis_tkeep
                             .m_axis_tlast (tx_axis_mac_tlast)    // output wire m_axis_tlast
                           );
  /*********************************************************************
  --Instantiate the AXI-LITE Controller
  *********************************************************************/
  tri_mode_ethernet_mac_0_axi_lite_sm axi_lite_controller_0 (
                                        .s_axi_aclk     (clk_125),
                                        .s_axi_resetn   (s_axi_resetn),
                                        .mac_speed      (2'b10),
                                        .update_speed   (1'b0),           // may need glitch protection on this..
                                        .serial_command (1'b0),
                                        .serial_response(),
                                        .s_axi_awaddr   (s_axi_awaddr),
                                        .s_axi_awvalid  (s_axi_awvalid),
                                        .s_axi_awready  (s_axi_awready),
                                        .s_axi_wdata    (s_axi_wdata),
                                        .s_axi_wvalid   (s_axi_wvalid),
                                        .s_axi_wready   (s_axi_wready),
                                        .s_axi_bresp    (s_axi_bresp),
                                        .s_axi_bvalid   (s_axi_bvalid),
                                        .s_axi_bready   (s_axi_bready),
                                        .s_axi_araddr   (s_axi_araddr),
                                        .s_axi_arvalid  (s_axi_arvalid),
                                        .s_axi_arready  (s_axi_arready),
                                        .s_axi_rdata    (s_axi_rdata),
                                        .s_axi_rresp    (s_axi_rresp),
                                        .s_axi_rvalid   (s_axi_rvalid),
                                        .s_axi_rready   (s_axi_rready)
                                      );


endmodule
