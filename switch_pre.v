`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         TSN@NNS
// Engineer:        Wenxue Wu
// Create Date:     2024/8/6
// Module Name:     switch_pre
// Target Devices:  ZYNQ
// Tool Versions:   VIVADO 2023.2
// Description:     TSN switch packet preprocess
//////////////////////////////////////////////////////////////////////////////////
module switch_pre #(
        parameter                           DATA_WIDTH                  = 64    ,
        parameter                           CTRL_WIDTH                  = DATA_WIDTH / 8,
        parameter                           PORT_NUM                    = 4     ,
        parameter                           ETHER_TYPE                  = 16'h8100,
        parameter                           ETHER_TYPE_2                = 16'h0800
    )(
        input                               clk                        ,
        input                               reset                      ,
        input                               sof                        ,
        input                               eop                        ,
        input                [DATA_WIDTH-1: 0]      din                        ,
        input                [CTRL_WIDTH-1: 0]      in_ctrl                    ,
        input                [  15: 0]      ethertype                  ,
        input                [  11: 0]      vlan_id                    ,
        input                [PORT_NUM-1: 0]      search_result              ,
        input                               i_cell_bp                  ,
        input                [   3: 0]      in_src_port                ,// 0~3，代表端口序号
        output wire          [   3: 0]      group_id                   ,
        output reg           [  31: 0]      flow_ID                    ,
        output reg           [   2: 0]      priority                   ,
        output reg           [DATA_WIDTH-1: 0]      i_cell_data_fifo_dout      ,
        output reg                          i_cell_data_fifo_wr        ,
        output reg           [  22: 0]      i_cell_ptr_fifo_dout       ,
        output reg                          i_cell_ptr_fifo_wr
    );

    // ------------------------ 内部信号定义 ------------------------
    reg                [   7: 0]        word_num                    ;
    reg                [   3: 0]        pre_state                   ;
    reg                [PORT_NUM-1: 0]        i_cell_portmap              ;
    reg                [   3: 0]        valid                       ;
    reg                [ 127: 0]        flow_id_128                 ;
    reg                                 flow_id_en                  ;
    reg                                 flow_id_end                 ;
    reg                [   2: 0]        pad_cnt                     ;
    reg                [   2: 0]        pad_num                     ;
    reg                [DATA_WIDTH-1: 0]        i_cell_data_fifo_dout_reg_1  ;
    reg                [DATA_WIDTH-1: 0]        i_cell_data_fifo_dout_reg_2  ;
    reg                [DATA_WIDTH-1: 0]        i_cell_data_fifo_dout_reg_3  ;


    //    one-hot src_port解码（如in_src_port==2，输出4'b0100）
    reg                [   3: 0]        src_port_onehot             ;
    always @(*) begin
        case (in_src_port)
            4'd0:
                src_port_onehot = 4'b0001;
            4'd1:
                src_port_onehot = 4'b0010;
            4'd2:
                src_port_onehot = 4'b0100;
            4'd3:
                src_port_onehot = 4'b1000;
            default:
                src_port_onehot = 4'b0000;
        endcase
    end

    // --------------------- 数据输入状态机 ----------------------
    always @(posedge clk) begin
        if (reset) begin
            word_num <= 0;
            pre_state <= 0;
            i_cell_data_fifo_dout <= 0;
            i_cell_portmap <= 0;
            i_cell_data_fifo_wr <= 0;
            i_cell_ptr_fifo_dout <= 0;
            i_cell_ptr_fifo_wr <= 0;
            pad_cnt <= 0;
            pad_num <= 0;
            i_cell_data_fifo_dout_reg_1 <= 0;
            i_cell_data_fifo_dout_reg_2 <= 0;
            i_cell_data_fifo_dout_reg_3 <= 0;
        end
        else begin
            i_cell_data_fifo_wr <= 0;
            i_cell_ptr_fifo_wr <= 0;
            case (pre_state)
                0: begin                                                       // 等待SOF
                    word_num <= 0;
                    if (sof & !i_cell_bp) begin
                        i_cell_data_fifo_dout_reg_1 <= din;
                        pre_state <= 2;
                    end
                end
                2: begin
                    i_cell_data_fifo_dout_reg_1 <= din;
                    i_cell_data_fifo_dout_reg_2 <= i_cell_data_fifo_dout_reg_1;
                    i_cell_data_fifo_dout_reg_3 <= i_cell_data_fifo_dout_reg_2;
                    pre_state <= 3;
                end
                3: begin
                    i_cell_data_fifo_dout_reg_1 <= din;
                    i_cell_data_fifo_dout_reg_2 <= i_cell_data_fifo_dout_reg_1;
                    i_cell_data_fifo_dout_reg_3 <= i_cell_data_fifo_dout_reg_2;
                    pre_state <= 4;
                end
                4: begin
                    // 前3个字处理
                    if(word_num == 0) begin
                        i_cell_data_fifo_dout <= i_cell_data_fifo_dout_reg_3;
                        i_cell_data_fifo_wr   <= (({ethertype[7:0], ethertype[15:8]} == ETHER_TYPE || {ethertype[7:0], ethertype[15:8]} == ETHER_TYPE_2) ? 1'b1 : 1'b0);
                        i_cell_data_fifo_dout_reg_3 <= din;
                    end
                    else if(word_num == 1) begin
                        i_cell_data_fifo_dout <= i_cell_data_fifo_dout_reg_2;
                        i_cell_data_fifo_wr   <= (({ethertype[7:0], ethertype[15:8]} == ETHER_TYPE || {ethertype[7:0], ethertype[15:8]} == ETHER_TYPE_2) ? 1'b1 : 1'b0);
                        i_cell_data_fifo_dout_reg_2 <= din;
                    end
                    else if(word_num == 2) begin
                        i_cell_data_fifo_dout <= i_cell_data_fifo_dout_reg_1;
                        i_cell_data_fifo_wr   <= (({ethertype[7:0], ethertype[15:8]} == ETHER_TYPE || {ethertype[7:0], ethertype[15:8]} == ETHER_TYPE_2) ? 1'b1 : 1'b0);
                        i_cell_data_fifo_dout_reg_1 <= din;
                    end
                    else begin
                        i_cell_data_fifo_dout <= i_cell_data_fifo_dout_reg_3;
                        i_cell_data_fifo_wr   <= (({ethertype[7:0], ethertype[15:8]} == ETHER_TYPE || {ethertype[7:0], ethertype[15:8]} == ETHER_TYPE_2) ? 1'b1 : 1'b0);
                        pre_state <= 5;
                        i_cell_data_fifo_dout_reg_3 <= i_cell_data_fifo_dout_reg_2;
                        i_cell_data_fifo_dout_reg_2 <= i_cell_data_fifo_dout_reg_1;
                        i_cell_data_fifo_dout_reg_1 <= din;
                    end
                    word_num <= word_num + 1;
                end
                5: begin                                                       // 中间字节流
                    i_cell_data_fifo_dout_reg_3 <= i_cell_data_fifo_dout_reg_2;
                    i_cell_data_fifo_dout_reg_2 <= i_cell_data_fifo_dout_reg_1;
                    i_cell_data_fifo_dout_reg_1 <= din;
                    i_cell_data_fifo_dout <= i_cell_data_fifo_dout_reg_3;
                    i_cell_data_fifo_wr   <= (({ethertype[7:0], ethertype[15:8]} == ETHER_TYPE || {ethertype[7:0], ethertype[15:8]} == ETHER_TYPE_2) ? 1'b1 : 1'b0);
                    word_num <= word_num + 1;
                    if (!eop)
                        pre_state <= 5;
                    else
                        pre_state <= 6;
                    i_cell_portmap <= 4'b0001;                                // TODO: 可用search_result
                end
                6: begin
                    i_cell_data_fifo_dout <= i_cell_data_fifo_dout_reg_3;
                    i_cell_data_fifo_wr   <= (({ethertype[7:0], ethertype[15:8]} == ETHER_TYPE || {ethertype[7:0], ethertype[15:8]} == ETHER_TYPE_2) ? 1'b1 : 1'b0);
                    pre_state <= 7;
                    word_num <= word_num + 1;
                end
                7: begin
                    i_cell_data_fifo_dout <= i_cell_data_fifo_dout_reg_2;
                    i_cell_data_fifo_wr   <= (({ethertype[7:0], ethertype[15:8]} == ETHER_TYPE || {ethertype[7:0], ethertype[15:8]} == ETHER_TYPE_2) ? 1'b1 : 1'b0);
                    pre_state <= 8;
                    word_num <= word_num + 1;
                end
                8: begin
                    i_cell_data_fifo_dout <= i_cell_data_fifo_dout_reg_1;
                    i_cell_data_fifo_wr   <= (({ethertype[7:0], ethertype[15:8]} == ETHER_TYPE || {ethertype[7:0], ethertype[15:8]} == ETHER_TYPE_2) ? 1'b1 : 1'b0);
                    pre_state <= 9;
                    word_num <= word_num + 1;
                end
                9: begin                                                       // 计算padding
                    pad_cnt <= ~word_num[2:0];
                    pad_num <= ~word_num[2:0] + 1'b1;
                    pre_state <= 10;
                end
                10: begin
                    if (pad_cnt == 7) begin
                        pre_state <= 11;
                    end
                    else begin
                        i_cell_data_fifo_dout <= 64'hFFEEDDCCBBAA9988;          // pad magic
                        i_cell_data_fifo_wr   <= (({ethertype[7:0], ethertype[15:8]} == ETHER_TYPE || {ethertype[7:0], ethertype[15:8]} == ETHER_TYPE_2) ? 1'b1 : 1'b0);
                        if (pad_cnt > 0) begin
                            pad_cnt <= pad_cnt - 1'b1;
                            pre_state <= 10;
                        end
                        else begin
                            pre_state <= 11;
                            word_num[7:3] <= word_num[7:3] + 1'b1;
                        end
                    end
                end
                11: begin
                    i_cell_data_fifo_wr <= 0;
                    i_cell_ptr_fifo_dout <= {in_src_port[3:0], priority[2:0], valid[3:0], i_cell_portmap[3:0], word_num[7:3], pad_num[2:0]};
                    i_cell_ptr_fifo_wr <= (({ethertype[7:0], ethertype[15:8]} == ETHER_TYPE || {ethertype[7:0], ethertype[15:8]} == ETHER_TYPE_2) ? 1'b1 : 1'b0);
                    pre_state <= 0;
                end
                default: begin
                    pre_state <= 0;
                end
            endcase
        end
    end

    // --------- 优先级/流ID组合逻辑（可进一步同步化） ---------
    always @(*) begin
        if (reset) begin
            priority = 0;
            flow_id_128 = 0;
            flow_id_end = 0;
            flow_id_en = 0;
            flow_ID = 0;
        end
        else if (word_num == 1) begin
            flow_id_128[DATA_WIDTH-1:0] = i_cell_data_fifo_dout;
        end
        else if (word_num == 2) begin
            case ({i_cell_data_fifo_dout[39:32], i_cell_data_fifo_dout[47:40]})
                ETHER_TYPE:
                    priority = i_cell_data_fifo_dout[55:53];
                16'h0800:
                    priority = 0;
                default:
                    priority = 0;
            endcase
            flow_id_128[127:64] = i_cell_data_fifo_dout;
            flow_id_en = 1;
            flow_id_end = 0;
        end
        else begin
            // 保持原值
            priority = priority;
            flow_id_128 = flow_id_128;
            flow_id_en = (word_num > 4 || word_num == 0) ? 0 : 1;
            flow_id_end = (word_num > 4) ? 1 : 0;
            flow_ID = (word_num == 4) ? vlan_id : flow_ID;
        end
    end

    // ----------- valid信号赋值 -----------
    always @(posedge clk) begin
        if (eop) begin
            case (in_ctrl)
                8'b0000_0000:
                    valid <= 0;
                8'b0000_0001:
                    valid <= 1;
                8'b0000_0011:
                    valid <= 2;
                8'b0000_0111:
                    valid <= 3;
                8'b0000_1111:
                    valid <= 4;
                8'b0001_1111:
                    valid <= 5;
                8'b0011_1111:
                    valid <= 6;
                8'b0111_1111:
                    valid <= 7;
                8'b1111_1111:
                    valid <= 8;
                default:
                    valid <= 0;
            endcase
        end
    end

    // ---------------- group id 逻辑 ----------------
    group_id_simple_map u_group_id_simple_map (
                            .dst_port                           (4'b0001                   ),// 目标端口，直接使用
                            .src_port                           (src_port_onehot           ),// 源端口，已解码为one-hot
                            .pri                                (priority                  ),
                            .group_id                           (group_id                  )
                        );



endmodule
