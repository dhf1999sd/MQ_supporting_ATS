//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         TSN@NNS
// Engineer:        Wenxue Wu
//
// Create Date:     2024/8/6
// Design Name:     Queue Management Module
// Module Name:     switch_qm
// Project Name:    ATS_with_mult_queue_v11
// Target Devices:  ZYNQ
// Tool Versions:   VIVADO 2023.2
// Description:     Queue Management Module
//
// Dependencies:    comparator.v, dequeue_process.v, priority_arbiter.v
//
// Revision:     v1.0
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module switch_qm#(
        parameter       NUM_FLOW_QUEUES   = 12,
        parameter       NUM_PRIORITY      = 4,
        parameter       DEPTH_FLOW_QUEUES = 8,     // 队列深度
        parameter       TIMESTAMP_WIDTH   = 59,    // 时间戳位宽从72改为59
        parameter       PORT_NUM          = 4,
        parameter       ADDR_WIDTH        = 10,    // Pointer RAM address width
        parameter       METADATA_WIDTH    = 20
    )(
        input  wire                               clk,
        input  wire                               reset,
        input  wire                               in_metadata_wr,
        input  wire [TIMESTAMP_WIDTH-1:0]         frame_eligible_time,
        input  wire                               frame_elig_time_ok_w,
        input  wire [3:0]                         group_id,
        input  wire                               ptr_ack,
        input  wire [2:0]                         pcp,
        input  wire [METADATA_WIDTH-1:0]         in_metadata,
        input  wire [31:0]                        input_flow_ID,
        input  wire [TIMESTAMP_WIDTH-1:0]         local_clock, // 位宽从72改为59
        output wire                               input_data_full,
        output wire                               ptr_rdy,
        output wire [METADATA_WIDTH-1:0]         ptr_dout
    );

    /***************function**************/

    /***************parameter*************/

    /***************port******************/

    /***************mechine***************/

    /***************reg*******************/
    reg                                       ptr_wr;
    reg                                       input_data_rd;
    reg                                       parameter_fifo_rd;
    reg                                       ptr_wr_ack;
    reg  [1:0]                                qm_wr_state;
    reg  [2:0]                                wr_pcp;
    reg  [22:0]                               ptr_din;
    reg  [31:0]                               flow_id_search_r;
    reg  [3:0]                                wr_group_id;
    reg  [58:0]                               frame_elig_time_r; // 位宽从64改为59
    reg                                       wr_finish_flag;
    reg  [METADATA_WIDTH-1:0]                 tail[NUM_FLOW_QUEUES-1:0];
    reg  [METADATA_WIDTH-1:0]                 head[NUM_FLOW_QUEUES-1:0];
    reg  [METADATA_WIDTH-1:0]                 ptr_ram_din;
    reg  [15:0]                               depth_cell[NUM_FLOW_QUEUES-1:0];
    reg  [15:0]                               depth_frame[NUM_FLOW_QUEUES-1:0];
    reg  [15:0]                               frame_length[NUM_FLOW_QUEUES-1:0];
    reg  [9:0]                                ptr_ram_addr;
    reg  [3:0]                                rd_pri_id;
    reg  [3:0]                                qm_mstate;
    reg                                       ptr_ram_wr;
    reg                                       depth_flag[NUM_FLOW_QUEUES-1:0];
    reg                                       wr_flag;
    reg  [TIMESTAMP_WIDTH-1:0]                frame_elig_time_queue_r[NUM_FLOW_QUEUES-1:0][DEPTH_FLOW_QUEUES-1:0]; // 从72位改为59位
    reg                                       ptr_rd;
    reg  [METADATA_WIDTH-1:0]                 pcp_queue_din[NUM_PRIORITY-1:0];
    reg  [NUM_PRIORITY-1:0]                   pcp_queue_wr;
    reg  [3:0]                                rd_group_id;
    reg                                       start_dequeue;
    reg  [NUM_FLOW_QUEUES-1:0]                shift_en;
    reg                                       head_update_finish_flag;
    reg  [METADATA_WIDTH-1:0]                 out_mb_md;
    reg                                       out_mb_md_wr;
    reg [2:0]                                 re_comparator_counter;
    reg                                       stop_dequeue_flag;
    reg                                       dequeue_valid;

    /***************wire******************/
    wire                                      input_data_empty;
    wire [26:0]                               input_data_dout;
    wire [90:0]                               parameter_fifo_out; // 位宽从104改为91 (32 + 59 = 91)
    wire [1:0]                                min_index_out_0;
    wire [1:0]                                min_index_out_1;
    wire [1:0]                                min_index_out_2;
    wire [1:0]                                min_index_out_3;
    wire [9:0]                                ptr_ram_addr_rd;
    wire [METADATA_WIDTH-1:0]                 ptr_ram_dout;
    wire [METADATA_WIDTH-1:0]                 new_head;
    wire [NUM_PRIORITY-1:0]                   pcp_queue_full;
    wire [NUM_PRIORITY-1:0]                   pcp_queue_empty;
    wire [4:0]                                pcp_queue_cnt[NUM_PRIORITY-1:0];
    wire [NUM_PRIORITY-1:0]                   pcp_queue_ack;
    wire                                      q0_flag;
    wire                                      q1_flag;
    wire                                      q2_flag;
    wire                                      q3_flag;
    wire [METADATA_WIDTH-1:0]                 pcp_queue_dout[NUM_PRIORITY-1:0];
    wire                                      output_queue_empty;
    wire [NUM_PRIORITY-1:0]                   priority_request;
    wire                                      dequeue_done;
    wire [15:0]                               rd_depth_cell_reg;
    wire [METADATA_WIDTH-1:0]                 pcp_queue_din_muxed;
    wire                                      pcp_queue_wr_muxed;
    wire                                      min_index_out_flag_0;
    wire                                      min_index_out_flag_1;
    wire                                      min_index_out_flag_2;
    wire                                      min_index_out_flag_3;

    /***************component*************/
    fifo_d64_in_queue_port u_ptr_group_wr_fifo (
                               .clk        (clk),
                               .rst        (reset),
                               .din        ({group_id[3:0], pcp[2:0], in_metadata[METADATA_WIDTH-1:0]}),
                               .wr_en      (in_metadata_wr),
                               .rd_en      (input_data_rd),
                               .dout       (input_data_dout),
                               .full       (input_data_full),
                               .empty      (input_data_empty),
                               .data_count ()
                           );

    parameter_fifo u_flow_fifo_ft (
                       .clk    (clk),    // input wire clk
                       .rst    (reset),  // input wire rst
                       .din    ({input_flow_ID[31:0], frame_eligible_time[TIMESTAMP_WIDTH-1:0]}), // 32+59=91位
                       .wr_en  (frame_elig_time_ok_w),  // input wire wr_en
                       .rd_en  (parameter_fifo_rd),     // input wire rd_en
                       .dout   (parameter_fifo_out)     // output wire [90:0] dout 从[103:0]改为[90:0]
                   );

    sram_w16_d512 u_group_flow_ram (
                      .clka  (clk),
                      .wea   (ptr_ram_wr),
                      .addra (ptr_ram_addr[8:0]),
                      .dina  (ptr_ram_din),
                      .douta (ptr_ram_dout)
                  );

    comparator u_comparator_0 (
                   .clk                (clk),
                   .reset              (reset),
                   .in_data_0          (frame_elig_time_queue_r[0][0]),
                   .in_data_1          (frame_elig_time_queue_r[4][0]),
                   .in_data_2          (frame_elig_time_queue_r[8][0]),
                   .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
                   .min_index_out      (min_index_out_0),
                   .min_index_out_flag (min_index_out_flag_0)
               );

    comparator u_comparator_1 (
                   .clk                (clk),
                   .reset              (reset),
                   .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
                   .in_data_0          (frame_elig_time_queue_r[1][0]),
                   .in_data_1          (frame_elig_time_queue_r[5][0]),
                   .in_data_2          (frame_elig_time_queue_r[9][0]),
                   .min_index_out      (min_index_out_1),
                   .min_index_out_flag (min_index_out_flag_1)
               );

    comparator u_comparator_2 (
                   .clk                (clk),
                   .reset              (reset),
                   .in_data_0          (frame_elig_time_queue_r[2][0]),
                   .in_data_1          (frame_elig_time_queue_r[6][0]),
                   .in_data_2          (frame_elig_time_queue_r[10][0]),
                   .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
                   .min_index_out      (min_index_out_2),
                   .min_index_out_flag (min_index_out_flag_2)
               );

    comparator u_comparator_3 (
                   .clk                (clk),
                   .reset              (reset),
                   .in_data_0          (frame_elig_time_queue_r[3][0]),
                   .in_data_1          (frame_elig_time_queue_r[7][0]),
                   .in_data_2          (frame_elig_time_queue_r[11][0]),
                   .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
                   .min_index_out      (min_index_out_3),
                   .min_index_out_flag (min_index_out_flag_3)
               );

    dequeue_process #(
                        .DATA_WIDTH (20),
                        .ADDR_WIDTH (ADDR_WIDTH)
                    ) dequeue_process_inst (
                        .clk            (clk),
                        .reset          (reset),
                        .start_dequeue  (start_dequeue),
                        .head_ptr_in    (head[rd_group_id]),
                        .ptr_ram_dout   (ptr_ram_dout),
                        .pcp_queue_full (pcp_queue_full[rd_pri_id]),
                        .ptr_ram_addr   (ptr_ram_addr_rd),
                        .pcp_queue_din  (pcp_queue_din_muxed),
                        .pcp_queue_wr   (pcp_queue_wr_muxed),
                        .new_head       (new_head),
                        .dequeue_done   (dequeue_done),
                        .rd_depth_cell  (rd_depth_cell_reg)
                    );

    generate
        genvar y;
        for (y = 0; y < NUM_PRIORITY; y = y + 1) begin : PRIORITY_QUEUE
            fifo_ft_w16_d64 u_priority_queue (
                                .clk        (clk),
                                .rst        (reset),
                                .din        (pcp_queue_din[y]),
                                .wr_en      (pcp_queue_wr[y]),
                                .rd_en      (pcp_queue_ack[y]),
                                .dout       (pcp_queue_dout[y]),
                                .full       (pcp_queue_full[y]),
                                .empty      (pcp_queue_empty[y]),
                                .data_count (pcp_queue_cnt[y])
                            );
        end
    endgenerate

    priority_arbiter u_priority_arbiter (
                         .clk           (clk),
                         .reset         (reset),
                         .i_req_release (q0_flag | q1_flag | q2_flag | q3_flag),
                         .i_req_in      ({q0_flag, q1_flag, q2_flag, q3_flag}),
                         .o_grant_out   ({pcp_queue_ack[0], pcp_queue_ack[1], pcp_queue_ack[2], pcp_queue_ack[3]})
                     );

    fifo_output_w20 u_fifo_output_w20 (
                        .clk        (clk),              // input wire clk
                        .rst        (reset),            // input wire rst
                        .din        (out_mb_md[METADATA_WIDTH-1:0]),  // input wire [METADATA_WIDTH-1 : 0] din
                        .wr_en      (out_mb_md_wr),     // input wire wr_en
                        .rd_en      (ptr_ack),          // input wire rd_en
                        .dout       (ptr_dout),         // output wire [METADATA_WIDTH-1 : 0] dout
                        .full       (),                 // output wire full
                        .empty      (output_queue_empty), // output wire empty
                        .data_count ()                  // output wire [4 : 0] data_count
                    );

    /***************assign****************/
    assign priority_request = {min_index_out_flag_3, min_index_out_flag_2, min_index_out_flag_1, min_index_out_flag_0};
    assign ptr_rdy = !output_queue_empty;
    assign q0_flag = (pcp_queue_cnt[0] != 0)&&(pcp_queue_din[0][15]==1) ? 1 : 0;
    assign q1_flag = (pcp_queue_cnt[1] != 0)&&(pcp_queue_din[1][15]==1) ? 1 : 0;
    assign q2_flag = (pcp_queue_cnt[2] != 0)&&(pcp_queue_din[2][15]==1) ? 1 : 0;
    assign q3_flag = (pcp_queue_cnt[3] != 0)&&(pcp_queue_din[3][15]==1) ? 1 : 0;

    /***************always****************/
    integer i, q, d, e;

    // Input Write State Machine
    always @(posedge clk) begin
        if (reset) begin
            ptr_din           <= 0;
            ptr_wr            <= 0;
            input_data_rd     <= 0;
            qm_wr_state       <= 0;
            wr_pcp            <= 0;
            flow_id_search_r  <= 0;
            wr_group_id       <= 0;
            parameter_fifo_rd <= 0;
            wr_finish_flag    <= 0;
            frame_elig_time_r <= 0;
        end
        else begin
            case (qm_wr_state)
                0: begin
                    if (!input_data_empty) begin
                        input_data_rd <= 1;
                        qm_wr_state   <= 1;
                    end
                end
                1: begin
                    input_data_rd <= 0;
                    qm_wr_state   <= 2;
                    if (input_data_dout[14])
                        parameter_fifo_rd <= 1;
                end
                2: begin
                    ptr_din        <= input_data_dout;
                    ptr_wr         <= 1;
                    wr_finish_flag <= 1;
                    qm_wr_state    <= 3;
                    wr_pcp         <= input_data_dout[22:20];
                    if (input_data_dout[14]) begin // [14]是first_cell标志位
                        frame_elig_time_r <= parameter_fifo_out[TIMESTAMP_WIDTH-1:0];   // frame_eligible_time的数据
                        flow_id_search_r  <= parameter_fifo_out[90:59]; // input_flow_ID[31:0]的数据 从[103:72]改为[90:59]
                        wr_group_id[3:0]  <= input_data_dout[26:23];
                    end
                end
                3: begin
                    parameter_fifo_rd <= 0;
                    if (ptr_wr_ack) begin
                        ptr_wr      <= 0;
                        qm_wr_state <= 0;
                        if (input_data_dout[15]) begin // [15]是last_cell标志位
                            wr_finish_flag <= 0;
                        end
                    end
                end
            endcase
        end
    end

    // Queue Management Main State Machine
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < NUM_FLOW_QUEUES; i = i + 1) begin
                depth_cell[i]  <= 0;
                tail[i]        <= 0;
                head[i]        <= 0;
                depth_frame[i] <= 0;
                depth_flag[i]  <= 0;
            end
            qm_mstate          <= 0;
            head_update_finish_flag <= 0;
            ptr_wr_ack         <= 0;
            wr_flag            <= 0;
            ptr_ram_addr       <= 0;
            ptr_ram_din        <= 0;
            ptr_ram_wr         <= 0;
        end
        else begin
            ptr_wr_ack <= 0;
            ptr_ram_wr <= 0;
            case (qm_mstate)
                0: begin
                    if (ptr_wr) begin
                        qm_mstate <= 1;
                        wr_flag   <= 1;
                    end
                    else if (wr_finish_flag == 0 & ptr_rd) begin // This seems to be disabled logic
                        qm_mstate <= 3;
                    end
                end
                1: begin
                    if (depth_cell[wr_group_id]) begin
                        ptr_ram_wr                       <= 1;
                        ptr_ram_addr[9:0]                <= tail[wr_group_id][9:0];
                        ptr_ram_din[METADATA_WIDTH-1:0] <= ptr_din[METADATA_WIDTH-1:0];
                        tail[wr_group_id]                <= ptr_din;
                    end
                    else begin
                        ptr_ram_wr                       <= 1;
                        ptr_ram_addr[9:0]                <= ptr_din[9:0];
                        ptr_ram_din[METADATA_WIDTH-1:0] <= ptr_din[METADATA_WIDTH-1:0];
                        tail[wr_group_id]                <= ptr_din;
                        head[wr_group_id]                <= ptr_din;
                    end
                    depth_cell[wr_group_id] <= depth_cell[wr_group_id] + 1;
                    if (ptr_din[15]) begin // last cell
                        depth_flag[wr_group_id]  <= 1;
                        depth_frame[wr_group_id] <= depth_frame[wr_group_id] + 1;
                    end
                    else if (ptr_din[14]) begin // first cell
                    end
                    ptr_wr_ack <= 1;
                    qm_mstate  <= 2;
                end
                2: begin
                    ptr_ram_addr[9:0]                <= tail[wr_group_id][9:0];
                    ptr_ram_din[METADATA_WIDTH-1:0] <= tail[wr_group_id][METADATA_WIDTH-1:0];
                    ptr_ram_wr                       <= 1;
                    qm_mstate                        <= 0;
                    wr_flag                          <= 0;
                end
                3: begin
                    ptr_ram_addr[9:0] <= ptr_ram_addr_rd;
                    if (dequeue_done) begin
                        qm_mstate          <= 4;
                        head_update_finish_flag <= 1; // 清除更新完成标志
                    end
                end
                4: begin
                    qm_mstate                 <= 5;
                    head[rd_group_id]         <= new_head;
                    depth_frame[rd_group_id]  <= depth_frame[rd_group_id] - 1;
                    depth_cell[rd_group_id]   <= depth_cell[rd_group_id] - rd_depth_cell_reg;
                    head_update_finish_flag        <= 0; // 设置更新完成标志
                end
                5: begin
                    qm_mstate <= 6;
                    if (depth_frame[rd_group_id] == 0)
                        depth_flag[rd_group_id] <= 0; // 清除深度标志
                end
                6: begin
                    qm_mstate <= 7;
                end
                7: begin
                    qm_mstate <= 8;
                end
                8: begin
                    qm_mstate <= 0;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            for (q = 0; q < NUM_FLOW_QUEUES; q = q + 1) begin
                for (e = 0; e < DEPTH_FLOW_QUEUES; e = e + 1) begin
                    frame_elig_time_queue_r[q][e] <= 0;
                end
            end
            shift_en <= 0;
        end
        else begin
            // 1. 处理移位操作 (优先级最高)
            if (dequeue_done) begin
                // 对当前出队的队列进行移位
                for (d = 0; d < DEPTH_FLOW_QUEUES-1; d = d + 1) begin
                    frame_elig_time_queue_r[rd_group_id][d] <= frame_elig_time_queue_r[rd_group_id][d+1];
                end
                frame_elig_time_queue_r[rd_group_id][DEPTH_FLOW_QUEUES-1] <= 0; // 清除最后一个位置
            end
            // 2. 处理新帧写入操作
            else if (qm_mstate == 1 && ptr_din[15]) begin // last cell in write state
                frame_elig_time_queue_r[wr_group_id][depth_frame[wr_group_id]] <= frame_elig_time_r;
            end
        end
    end



    always @(posedge clk) begin
        if (reset) begin
            re_comparator_counter <= 0;
            dequeue_valid <= 1;
        end
        else if(stop_dequeue_flag) begin
            if (re_comparator_counter < 5) begin
                re_comparator_counter <= re_comparator_counter + 1;
                dequeue_valid <= 0;
            end
            else begin
                re_comparator_counter <= 0; // Reset after reaching the last priority
                dequeue_valid <= 1; // Reset dequeue_valid to allow new dequeue requests
            end
        end
    end


    always @(*) begin
        // Default values
        // rd_group_id   = 0;
        start_dequeue = 0;
        ptr_rd        = 0;
        // Strict Priority: 3 > 2 > 1 > 0
        if(dequeue_valid) begin
            stop_dequeue_flag = 0; // Set flag to indicate dequeue process has started
            if (priority_request[3]) begin
                rd_group_id   = (min_index_out_3 == 0) ? 3 : (min_index_out_3 == 1) ? 7 : (min_index_out_3 == 2) ? 11 : 0;
                start_dequeue = (wr_finish_flag == 0) ? 1 : 0; // Only start dequeue if not in write state
                ptr_rd        = 1;
                rd_pri_id     = 3; // Set read priority ID to 3
                if(dequeue_done) begin
                    stop_dequeue_flag=1; // Reset dequeue flag after processing
                    start_dequeue=0; // Reset start_dequeue after processing
                end
            end
            else if (priority_request[2]) begin
                rd_group_id   = (min_index_out_2 == 0) ? 2 : (min_index_out_2 == 1) ? 6 : (min_index_out_2 == 2) ? 10 : 0;
                start_dequeue = (wr_finish_flag == 0) ? 1 : 0; // Only start dequeue if not in write state
                ptr_rd        = 1;
                rd_pri_id     = 2; // Set read priority ID to 2
                if(dequeue_done) begin
                    start_dequeue=0; // Reset dequeue flag after processing
                end
            end
            else if (priority_request[1]) begin
                rd_group_id   = (min_index_out_1 == 0) ? 1 : (min_index_out_1 == 1) ? 5 : (min_index_out_1 == 2) ? 9 : 0;
                start_dequeue = (wr_finish_flag == 0) ? 1 : 0; // Only start dequeue if not in write state
                ptr_rd        = 1;
                rd_pri_id     = 1; // Set read priority ID to 1
                if(dequeue_done) begin
                    start_dequeue=0; // Reset dequeue flag after processing
                end
            end
            else if (priority_request[0]) begin
                rd_group_id   = (min_index_out_0 == 0) ? 0 : (min_index_out_0 == 1) ? 4 : (min_index_out_0 == 2) ? 8 : 0;
                start_dequeue = (wr_finish_flag == 0) ? 1 : 0; // Only start dequeue if not in write state
                ptr_rd        = 1;
                rd_pri_id     = 0; // Set read priority ID to 0
                if(dequeue_done) begin
                    start_dequeue=0; // Reset dequeue flag after processing
                end
            end
            else if (head_update_finish_flag) begin
                start_dequeue = 0;
            end
        end
    end

    // 使用多路选择器将 dequeue_process 的输出路由到正确的优先级队列
    always @(*) begin
        pcp_queue_din[0] = 0;
        pcp_queue_din[1] = 0;
        pcp_queue_din[2] = 0;
        pcp_queue_din[3] = 0;
        pcp_queue_wr[0]  = 0;
        pcp_queue_wr[1]  = 0;
        pcp_queue_wr[2]  = 0;
        pcp_queue_wr[3]  = 0;

        case (rd_pri_id)
            3'd0: begin
                pcp_queue_din[0] = pcp_queue_din_muxed;
                pcp_queue_wr[0]  = pcp_queue_wr_muxed;
            end
            3'd1: begin
                pcp_queue_din[1] = pcp_queue_din_muxed;
                pcp_queue_wr[1]  = pcp_queue_wr_muxed;
            end
            3'd2: begin
                pcp_queue_din[2] = pcp_queue_din_muxed;
                pcp_queue_wr[2]  = pcp_queue_wr_muxed;
            end
            3'd3: begin
                pcp_queue_din[3] = pcp_queue_din_muxed;
                pcp_queue_wr[3]  = pcp_queue_wr_muxed;
            end
            default: begin
                pcp_queue_din[0] = 0;
                pcp_queue_din[1] = 0;
                pcp_queue_din[2] = 0;
                pcp_queue_din[3] = 0;
                pcp_queue_wr[0]  = 0;
                pcp_queue_wr[1]  = 0;
                pcp_queue_wr[2]  = 0;
                pcp_queue_wr[3]  = 0;
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset == 1'b1) begin
            out_mb_md    <= 20'd0;
            out_mb_md_wr <= 'b0;
        end
        else begin
            if (pcp_queue_ack[0] == 1'b1 & !pcp_queue_empty[0]) begin
                out_mb_md    <= pcp_queue_dout[0][METADATA_WIDTH-1:0];
                out_mb_md_wr <= 1'b1;
            end
            else if (pcp_queue_ack[1] == 1'b1 & !pcp_queue_empty[1]) begin
                out_mb_md    <= pcp_queue_dout[1][METADATA_WIDTH-1:0];
                out_mb_md_wr <= 1'b1;
            end
            else if (pcp_queue_ack[2] == 1'b1 & !pcp_queue_empty[2]) begin
                out_mb_md    <= pcp_queue_dout[2][METADATA_WIDTH-1:0];
                out_mb_md_wr <= 1'b1;
            end
            else if (pcp_queue_ack[3] == 1'b1 & !pcp_queue_empty[3]) begin
                out_mb_md    <= pcp_queue_dout[3][METADATA_WIDTH-1:0];
                out_mb_md_wr <= 1'b1;
            end
            else begin
                out_mb_md    <= 'b0;
                out_mb_md_wr <= 1'b0;
            end
        end
    end

endmodule
