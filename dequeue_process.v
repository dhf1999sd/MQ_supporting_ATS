//////////////////////////////////////////////////////////////////////////////////
// Company:         TSN@NNS
// Engineer:        Wenxue Wu
// 
// Create Date:     2024/05/15
// Design Name:     DFQ CAM Dequeue Process
// Module Name:     dequeue_process
// Project Name:    DFQ_CAM_v5
// Target Devices:  ZYNQ
// Tool Versions:   VIVADO 2023.2
// Description:     Dequeue process module for DFQ CAM system with FSM control
//                  Handles reading from pointer RAM and managing queue operations
// 
// Dependencies:    None
// 
// Revision:     v1.0
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module dequeue_process#(
    parameter       DATA_WIDTH = 20,
    parameter       ADDR_WIDTH = 10
)(
    input  wire                         clk,
    input  wire                         reset,
    input  wire                         start_dequeue,      // 启动出队信号
    input  wire [DATA_WIDTH-1:0]        head_ptr_in,        // 当前帧的头指针
    input  wire [DATA_WIDTH-1:0]        ptr_ram_dout,       // 从RAM读出的数据
    input  wire                         pcp_queue_full,     // 目标优先级队列是否已满
    output reg  [ADDR_WIDTH-1:0]        ptr_ram_addr,       // 输出到RAM的读取地址
    output reg  [DATA_WIDTH-1:0]        pcp_queue_din,      // 输出到优先级队列的数据
    output reg                          pcp_queue_wr,       // 优先级队列的写使能
    output reg  [DATA_WIDTH-1:0]        new_head,           // 帧出队后新的头指针
    output reg                          dequeue_done,       // 帧出队完成标志
    output reg  [15:0]                  rd_depth_cell
);

/***************function**************/

/***************parameter*************/
    localparam [3:0] ST_IDLE         = 4'd0;   // 空闲状态
    localparam [3:0] ST_START        = 4'd1;   // 开始处理
    localparam [3:0] ST_CHECK        = 4'd2;   // 检查是否为尾部条目
    localparam [3:0] ST_READ         = 4'd3;   // 读取操作（非尾部路径）
    localparam [3:0] ST_PUSH         = 4'd4;   // 推送数据到队列
    localparam [3:0] ST_PUSH_LOOP    = 4'd5;   // 推送循环等待
    localparam [3:0] ST_PUSH_DONE    = 4'd6;   // 推送完成
    localparam [3:0] ST_REFRESH      = 4'd7;   // 刷新操作
    localparam [3:0] ST_REFRESH_DONE = 4'd8;   // 刷新完成，检查是否为指针尾部
    localparam [3:0] ST_EXIT         = 4'd9;   // 从非尾部路径退出
    localparam [3:0] ST_CAM_REFRESH  = 4'd10;  // CAM刷新操作
    localparam [3:0] ST_CAM_WAIT     = 4'd11;  // CAM等待状态
    localparam [3:0] ST_FINAL        = 4'd12;  // 返回空闲前的最终状态
    localparam [3:0] ST_EXIT2        = 4'd13;  // 从尾部路径退出
    localparam [3:0] ST_NEXT         = 4'd14;  // 下一步操作（尾部路径）
    localparam [3:0] ST_WAIT         = 4'd15;  // 等待状态（尾部路径）

/***************port******************/             

/***************mechine***************/

/***************reg*******************/
    reg [3:0] current_state;
    reg [DATA_WIDTH-1:0] rd_head_reg;

/***************wire******************/
    // Flag to check if current entry is 64B (both bit 15 and 14 are set)
    wire is_cell_1 = head_ptr_in[15] && head_ptr_in[14];
    // Flag to check if current pointer entry is tail (bit 15 is set)
    wire is_last_cell = ptr_ram_dout[15];

/***************component*************/

/***************assign****************/

/***************always****************/
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state    <= ST_IDLE;
            pcp_queue_wr     <= 1'b0;
            ptr_ram_addr     <= {ADDR_WIDTH{1'b0}};
            pcp_queue_din    <= {DATA_WIDTH{1'b0}};
            dequeue_done     <= 1'b0;
            new_head         <= {DATA_WIDTH{1'b0}};
            rd_head_reg      <= {DATA_WIDTH{1'b0}};
            rd_depth_cell    <= {16{1'b0}};
        end else begin
            // Default values - these signals are pulsed for one clock cycle
            pcp_queue_wr     <= 1'b0;
            dequeue_done     <= 1'b0;
            case (current_state)
                //-------------------------------------------------------------
                // State 0: IDLE - 等待开始信号
                //-------------------------------------------------------------
                ST_IDLE: begin
                    if (start_dequeue) begin
                        current_state <= ST_START;
                        rd_depth_cell <= 16'b0; // Reset depth cell counter
                    end
                end

                //-------------------------------------------------------------
                // State 1: START - 开始处理，发送头指针
                //-------------------------------------------------------------
                ST_START: begin
                    pcp_queue_din <= head_ptr_in;
                    pcp_queue_wr  <= 1'b1;
                    ptr_ram_addr  <= head_ptr_in[ADDR_WIDTH-1:0];
                    current_state <= ST_CHECK;
                    rd_depth_cell <= rd_depth_cell+1;
                end

                //-------------------------------------------------------------
                // State 2: CHECK - 检查是否为尾部条目
                //-------------------------------------------------------------
                ST_CHECK: begin
                    if (is_cell_1) begin
                        current_state <= ST_EXIT;  // 跳转到尾部路径
                    end else begin
                        current_state <= ST_READ;   // 继续非尾部路径
                    end
                end

                //-------------------------------------------------------------
                // State 3: READ - 读取操作（非尾部路径）
                //-------------------------------------------------------------
                ST_READ: begin
                    current_state <= ST_PUSH;
                end

                //-------------------------------------------------------------
                // State 4: PUSH - 推送数据到队列
                //-------------------------------------------------------------
                ST_PUSH: begin
                    pcp_queue_din <= ptr_ram_dout;
                    pcp_queue_wr  <= 1'b1;
                    ptr_ram_addr  <= ptr_ram_dout[ADDR_WIDTH-1:0];
                    current_state <= ST_PUSH_LOOP;
                    rd_depth_cell <= rd_depth_cell+1;
                end

                //-------------------------------------------------------------
                // State 5: PUSH_LOOP - 推送循环等待
                //-------------------------------------------------------------
                ST_PUSH_LOOP: begin
                    current_state <= ST_PUSH_DONE;
                end

                //-------------------------------------------------------------
                // State 6: PUSH_DONE - 推送完成
                //-------------------------------------------------------------
                ST_PUSH_DONE: begin
                    current_state <= ST_REFRESH;
                    if (is_last_cell) begin
                        ptr_ram_addr  <= ptr_ram_dout[ADDR_WIDTH-1:0];
                        current_state <= ST_EXIT;
                    end
                end

                //-------------------------------------------------------------
                // State 7: REFRESH - 刷新操作
                //-------------------------------------------------------------
                ST_REFRESH: begin
                    current_state <= ST_REFRESH_DONE;
                    pcp_queue_din <= ptr_ram_dout;
                    ptr_ram_addr  <= ptr_ram_dout[ADDR_WIDTH-1:0];
                    pcp_queue_wr  <= 1'b1;
                    rd_depth_cell <= rd_depth_cell+1;
                end

                //-------------------------------------------------------------
                // State 8: REFRESH_DONE - 刷新完成，检查是否为指针尾部
                //-------------------------------------------------------------
                ST_REFRESH_DONE: begin
                    if (is_last_cell) begin
                        // pcp_queue_din <= ptr_ram_dout;
                        // ptr_ram_addr  <= ptr_ram_dout[ADDR_WIDTH-1:0];
                        // pcp_queue_wr  <= 1'b1;
                        current_state <= ST_EXIT;
                    end else begin
                        current_state <= 4'd15;
                    end
                end

                4'd15: begin
                    current_state <= ST_PUSH;
                end

                //-------------------------------------------------------------
                // State 9: EXIT - 从非尾部路径退出
                //-------------------------------------------------------------
                ST_EXIT: begin
                    dequeue_done  <= 1'b1;
                    current_state <= ST_CAM_REFRESH;
                end

                //-------------------------------------------------------------
                //-------------------------------------------------------------
                ST_CAM_REFRESH: begin
                    current_state <= ST_CAM_WAIT;
                    new_head      <= ptr_ram_dout;
                end

                //-------------------------------------------------------------
                // State 11: CAM_WAIT - CAM等待状态
                //-------------------------------------------------------------
                ST_CAM_WAIT: begin
                    current_state <= ST_FINAL;
                end

                //-------------------------------------------------------------
                // State 12: FINAL - 返回空闲前的最终状态
                //-------------------------------------------------------------
                ST_FINAL: begin
                    current_state <= ST_EXIT2;
                end

                ST_EXIT2: begin
                    current_state <= ST_IDLE;
                end

                //-------------------------------------------------------------
                // Default: 默认状态 - 重置到空闲状态
                //-------------------------------------------------------------
                default: begin
                    pcp_queue_wr  <= 1'b0;
                    dequeue_done  <= 1'b0;
                    current_state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule