`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         TSN@NNS
// Engineer:        Wenxue Wu
//
// Create Date:     2024/07/15
// Design Name:     Flow Entry Manager
// Module Name:     flow_entry_manager
// Project Name:    ATS_with_mult_queue_v11
// Target Devices:  ZYNQ
// Tool Versions:   VIVADO 2023.2
// Description:     This module manages flow entries using RAM-based storage.
//                  It provides flow parameter lookup and update functionality
//                  with support for multiple groups and flows per group.
//
// Dependencies:    flow_para_ram.v
//
// Revision:     v1.0
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module flow_entry_manager#(
        parameter       MATCH_ADDR_WIDTH = 8,    // 8位地址，支持12组×16个flow = 192个条目
        parameter       NUM_FLOW         = 16,   // 每组16个flow
        parameter       GROUP_NUMBER     = 12,
        parameter       TIME_WIDTH       = 59,
        parameter       CAM_ENTRY_WIDTH  = 123   // 保持与原CAM一致，包含flow_id字段
    )(
        input  wire                  clk,
        input  wire                  reset,
        input  wire [31:0]           flow_id,
        input  wire                  update_flag,
        input  wire [3:0]            group_id,
        input  wire                  start_match_flag,
        input  wire [TIME_WIDTH-1:0] update_bucket_empty_time,
        input  wire [TIME_WIDTH-1:0] update_group_eligibility_time,
        output reg                   match_finish_flag,
        output reg  [31:0]           bucket_size,
        output reg  [31:0]           token_rate,
        output reg  [TIME_WIDTH-1:0] bucket_empty_time,
        output reg  [TIME_WIDTH-1:0] group_eligibility_time,
        output reg  [TIME_WIDTH-1:0] max_residence_time
    );

    /***************function**************/
    function [MATCH_ADDR_WIDTH-1:0] calc_addr;
        input [3:0] group;
        input [3:0] flow_index;
        begin
            calc_addr = {group, flow_index};  // 简单拼接：高4位group，低4位flow_index
        end
    endfunction

    /***************parameter*************/
    localparam IDLE        = 3'd0;
    localparam INIT        = 3'd1;
    localparam SEARCHING   = 3'd2;
    localparam MATCH_FOUND = 3'd3;
    localparam UPDATING    = 3'd4;

    /***************port******************/

    /***************mechine***************/

    /***************reg*******************/
    reg [3:0] state;
    reg match_flag;
    reg [MATCH_ADDR_WIDTH-1:0] init_addr_counter;
    reg init_done;
    reg  wea;
    reg  [MATCH_ADDR_WIDTH-1:0] addra;
    reg  [CAM_ENTRY_WIDTH-1:0] dina;
    reg [TIME_WIDTH-1:0] group_max_residence_time[GROUP_NUMBER-1:0];
    reg [TIME_WIDTH-1:0] group_eligibility_time_reg[GROUP_NUMBER-1:0];

    /***************wire******************/
    wire [CAM_ENTRY_WIDTH-1:0] douta;
    wire clka;

    /***************component*************/
    flow_para_ram u_flow_para_ram (
                      .clka(clk),
                      .wea(wea),
                      .addra(addra),
                      .dina(dina),
                      .douta(douta)
                  );

    /***************assign****************/
    assign clka = clk;

    /***************always****************/
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            state <= INIT;
            match_flag <= 1'b0;
            match_finish_flag <= 1'b0;
            bucket_size <= 0;
            token_rate <= 0;
            bucket_empty_time <= 0;
            group_eligibility_time <= 0;
            max_residence_time <= 0;

            init_addr_counter <= 0;
            init_done <= 1'b0;

            wea <= 1'b0;
            addra <= 0;
            dina <= 0;

            // 初始化所有group寄存器
            for (i = 0; i < GROUP_NUMBER; i = i + 1) begin
                group_max_residence_time[i] <= {TIME_WIDTH{1'b0}};
                group_eligibility_time_reg[i] <= {TIME_WIDTH{1'b0}};
            end
        end
        else begin
            case(state)
                INIT: begin
                    if (!init_done) begin
                        wea <= 1'b1;
                        addra <= init_addr_counter;

                        // 使用地址计算来初始化特定位置
                        case(init_addr_counter)
                            // Group 3, flow_index 7: flow_id 0x007
                            // calc_addr(4'd3, 4'h7): dina <= {59'h0, 32'd40000, 32'd512};
                            // Group 7, flow_index 0-3: flow_id 0x000-0x003
                            // calc_addr(4'd7, 4'h0): dina <= {59'h0, 32'd40000, 32'd512};    // 200Mbps
                            // calc_addr(4'd7, 4'h1): dina <= {59'h0, 32'd80000, 32'd512};    //100Mbps
                            // calc_addr(4'd7, 4'h2): dina <= {59'h0, 32'd320000, 32'd1600};  //  25Mbps
                            calc_addr(4'd7, 4'h3): dina <= {59'h0, 32'd8000, 32'd3200};  //  50Mbps
                            // Group 8, flow_index 4-5: flow_id 0x004-0x005
                            calc_addr(4'd8, 4'h4): dina <= {59'h0, 32'd160000, 32'd3200};   //  25Mbps
                            // calc_addr(4'd8, 4'h5): dina <= {59'h0, 32'd80000, 32'd512};    // 100Mbps
                            // Group 9, flow_index 4-5: flow_id 0x004-0x005
                            calc_addr(4'd9, 4'h4): dina <= {59'h0, 32'd320000, 32'd3200};    // 100Mbps
                            // Group 9, flow_index 0-3: flow_id 0x000
                            // 其他地址初始化为0
                            default:
                                dina <= 0;
                        endcase

                        init_addr_counter <= init_addr_counter + 1;

                        if (init_addr_counter == GROUP_NUMBER * NUM_FLOW - 1) begin
                            init_done <= 1'b1;
                            state <= IDLE;
                            wea <= 1'b0;
                        end
                    end
                    else begin
                        state <= IDLE;
                        wea <= 1'b0;
                    end
                end

                IDLE: begin
                    match_finish_flag <= 1'b0;
                    wea <= 1'b0;

                    if (update_flag) begin
                        state <= UPDATING;
                        addra <= calc_addr(group_id, flow_id[3:0]);  // 计算更新地址
                    end
                    else if (start_match_flag) begin
                        state <= 5;
                        addra <= calc_addr(group_id, flow_id[3:0]);  // 计算搜索地址
                    end
                end

                5:  // RAM读取延迟周期1
                begin
                    state <= 6;
                end

                6:  // RAM读取延迟周期2
                begin
                    state <= 7;
                end

                7:  // RAM读取延迟周期3
                begin
                    state <= SEARCHING;
                end

                UPDATING: begin
                    // 更新操作：直接地址访问
                    wea <= 1'b1;
                    addra <= calc_addr(group_id, flow_id[3:0]);
                    // 只更新bucket_empty_time字段，保持其他字段不变
                    dina <= {update_bucket_empty_time, douta[63:0]};
                    group_eligibility_time_reg[group_id] <= update_group_eligibility_time;
                    state <= IDLE;
                end

                SEARCHING: begin
                    wea <= 1'b0;
                    match_flag <= 1'b1;
                    bucket_size <= douta[31:0];
                    token_rate <= douta[63:32];
                    bucket_empty_time <= douta[122:64];
                    group_eligibility_time <= group_eligibility_time_reg[group_id];
                    max_residence_time <= group_max_residence_time[group_id];
                    match_finish_flag <= 1'b1;
                    state <= MATCH_FOUND;
                end

                MATCH_FOUND: begin
                    state <= 8;
                    match_flag <= 1'b0;
                    match_finish_flag <= 1'b1;
                end

                8: begin
                    match_finish_flag <= 1'b0;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
