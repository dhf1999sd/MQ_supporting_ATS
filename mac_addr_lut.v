`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:TSN@NNS
// Engineer:Wenxue Wu
// Create Date:  2023/11/14
// Module Name: mac_addr_lut_improved
// Target Devices:ZYNQ
// Tool Versions:VIVADO 2023.2
// Description: MAC地址查找表 - 改进版本
// 修复了原版本中的语法错误和时序问题
//////////////////////////////////////////////////////////////////////////////////

module mac_addr_lut (
    input             clk,
    input             reset,
    //port search signals
    input             src_lut_flag,
    input      [47:0] dst_mac,
    input      [47:0] src_mac,
    input      [15:0] se_portmap,     //src_mac port mapping
    input      [ 8:0] se_hash,
    input             se_req,
    output reg        se_ack,
    output reg        se_nak,
    output reg [ 3:0] search_result,
    input             aging_req,
    output reg        aging_ack
);

  parameter LIVE_TH = 10'd300;
  // 端口映射常量定义
  parameter PORT_0 = 16'h0000;
  parameter PORT_1 = 16'h0001;
  parameter PORT_2 = 16'h0002;
  parameter PORT_3 = 16'h0003;

  //======================================
  //              main state
  //======================================
  reg  [ 3:0] state;
  reg         clear_op;
  reg         hit;
  wire        item_valid;
  wire [ 9:0] live_time;
  wire        not_outlive;
  reg         ram_wr;
  reg  [ 8:0] ram_addr;
  reg  [79:0] ram_din;
  wire [79:0] ram_dout;
  reg  [79:0] ram_dout_reg;

  reg  [ 8:0] aging_addr;
  reg  [47:0] hit_mac;

  reg  [47:0] dst_mac_reg;
  reg  [47:0] src_mac_reg;
  reg         se_req_reg;
  reg  [ 8:0] se_hash_reg;
  reg  [15:0] se_portmap_reg;

  // 状态定义
  localparam  IDLE        = 4'h0,
                DST_LOOKUP1 = 4'h1,
                DST_LOOKUP2 = 4'h2,
                DST_LOOKUP3 = 4'h3,
                DST_RESULT  = 4'h4,
                SRC_LOOKUP1 = 4'h5,
                SRC_LOOKUP2 = 4'h6,
                SRC_LOOKUP3 = 4'h7,
                SRC_CHECK   = 4'h8,
                SRC_ADD     = 4'h9,
                SRC_UPDATE  = 4'hA,
                AGING_READ  = 4'hB,
                AGING_PROC1 = 4'hC,
                AGING_PROC2 = 4'hD,
                FINISH      = 4'hE,
                CLEAR_RAM   = 4'hF;

  always @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
      clear_op <= 1;
      ram_wr <= 0;
      ram_addr <= 0;
      ram_din <= 0;
      se_ack <= 0;
      se_nak <= 0;
      aging_ack <= 0;
      aging_addr <= 0;
      hit_mac <= 0;
      src_mac_reg <= 0;
      dst_mac_reg <= 0;
      search_result <= 0;
      se_req_reg <= 0;
      se_hash_reg <= 0;
      se_portmap_reg <= 0;
      ram_dout_reg <= 0;
    end else begin
      // 默认信号状态
      ram_dout_reg <= ram_dout;
      ram_wr <= 0;
      se_ack <= 0;
      se_nak <= 0;
      aging_ack <= 0;

      // 输入寄存器
      dst_mac_reg <= dst_mac;
      src_mac_reg <= src_lut_flag ? src_mac : src_mac_reg;
      se_req_reg <= se_req;
      se_hash_reg <= se_hash;
      se_portmap_reg <= se_portmap;

      case (state)
        IDLE: begin
          if (clear_op) begin
            ram_addr <= 0;
            ram_wr <= 1;
            ram_din <= 0;
            state <= CLEAR_RAM;
          end else if (se_req_reg) begin
            ram_addr <= se_hash_reg;
            hit_mac <= dst_mac_reg;
            state <= DST_LOOKUP1;
          end else if (aging_req) begin
            if (aging_addr < 9'h1ff) aging_addr <= aging_addr + 1;
            else begin
              aging_addr <= 0;
              aging_ack  <= 1;
            end
            ram_addr <= aging_addr;
            state <= AGING_READ;
          end
        end

        // 目标MAC查找阶段（增加等待周期以适配BRAM延迟）
        DST_LOOKUP1: state <= DST_LOOKUP2;
        DST_LOOKUP2: state <= DST_LOOKUP3;
        DST_LOOKUP3: state <= DST_RESULT;

        DST_RESULT: begin
          state <= SRC_LOOKUP1;
          case (hit)
            1'b0: begin  // 目标MAC未找到
              se_ack <= 0;
              se_nak <= 1;
              // 改进的端口映射逻辑
              case (se_portmap_reg[15:0])
                PORT_0:  search_result <= 4'b1110;  // 除端口0外的所有端口
                PORT_1:  search_result <= 4'b1101;  // 除端口1外的所有端口
                PORT_2:  search_result <= 4'b1011;  // 除端口2外的所有端口
                PORT_3:  search_result <= 4'b0111;  // 除端口3外的所有端口
                default: search_result <= 4'b1111;  // 所有端口
              endcase
            end
            1'b1: begin  // 目标MAC找到
              se_nak <= 0;
              se_ack <= 1;
              // 精确端口映射
              case (ram_dout_reg[15:0])
                PORT_0:  search_result <= 4'b0001;  // 端口0
                PORT_1:  search_result <= 4'b0010;  // 端口1
                PORT_2:  search_result <= 4'b0100;  // 端口2
                PORT_3:  search_result <= 4'b1000;  // 端口3
                default: search_result <= 4'b0000;  // 无效端口
              endcase
            end
          endcase

          // 准备源MAC查找
          ram_addr <= se_hash_reg;
          hit_mac  <= src_mac_reg;
        end

        // 源MAC查找阶段
        SRC_LOOKUP1: state <= SRC_LOOKUP2;
        SRC_LOOKUP2: state <= SRC_LOOKUP3;
        SRC_LOOKUP3: state <= SRC_CHECK;

        SRC_CHECK: begin
          if (hit == 1'b0) state <= SRC_ADD;  // 源MAC不存在，添加新条目
          else state <= SRC_UPDATE;  // 源MAC存在，更新条目
        end

        SRC_ADD: begin
          state <= FINISH;
          if (!item_valid) begin  // 如果当前位置无效，可以添加
            ram_din <= {1'b1, 5'b0, LIVE_TH, src_mac_reg[47:0], se_portmap_reg[15:0]};
            ram_wr  <= 1;
          end
        end

        SRC_UPDATE: begin
          state <= FINISH;
          if (hit) begin  // 如果找到匹配项，更新生存时间
            ram_din <= {1'b1, 5'b0, LIVE_TH, src_mac_reg[47:0], se_portmap_reg[15:0]};
            ram_wr  <= 1;
          end
        end

        // 老化处理
        AGING_READ:  state <= AGING_PROC1;
        AGING_PROC1: state <= AGING_PROC2;

        AGING_PROC2: begin
          state <= FINISH;
          if (not_outlive && item_valid) begin
            // 减少生存时间
            ram_din[79] <= 1'b1;
            ram_din[78:74] <= 5'b0;
            ram_din[73:64] <= live_time - 10'd1;
            ram_din[63:0] <= ram_dout_reg[63:0];
            ram_wr <= 1;
          end else begin
            // 清除过期条目
            ram_din[79:0] <= 80'b0;
            ram_wr <= 1;
          end
        end

        FINISH: begin
          ram_wr <= 0;
          se_ack <= 0;
          se_nak <= 0;
          aging_ack <= 0;
          clear_op <= 0;
          state <= IDLE;
        end

        CLEAR_RAM: begin
          if (ram_addr < 9'h1ff) begin
            ram_addr <= ram_addr + 1;
            ram_wr   <= 1;
            ram_din  <= 0;
          end else begin
            ram_addr <= 0;
            ram_wr <= 0;
            clear_op <= 0;
            state <= IDLE;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

  // 改进的hit检测逻辑
  always @(*) begin
    hit = (hit_mac == ram_dout_reg[63:16]) & ram_dout_reg[79];
  end

  // 辅助信号
  assign item_valid  = ram_dout_reg[79];  // 有效标志
  assign live_time   = ram_dout_reg[73:64];  // 生存时间
  assign not_outlive = (live_time > 0);  // 未过期检查

  // BRAM实例
  bram_hash u_sram (
      .clka (clk),       // input clka
      .wea  (ram_wr),    // input [0 : 0] wea
      .addra(ram_addr),  // input [8 : 0] addra
      .dina (ram_din),   // input [79 : 0] dina
      .douta(ram_dout)   // output [79 : 0] douta
  );

endmodule
