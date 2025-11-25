`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:TSN@NNS
// Engineer:Wenxue Wu
// Create Date:  2023/11/14
// Module Name: local_clock
// Target Devices:ZYNQ
// Tool Versions:VIVADO 2023.2
// Description:
//
//////////////////////////////////////////////////////////////////////////////////
module local_clock #(
        parameter CLOCK_PERIOD_PS = 8000,    //对应8ns  1时钟周期=8ns
        parameter TIMESTAMP_WIDTH = 59
    ) (
        input clk,  //
        input reset,  //
        output reg [TIMESTAMP_WIDTH-1:0] local_clock
    );
    always @(posedge clk) begin
        if (reset) begin
            local_clock <= 72'd1000000000000;//{TIMESTAMP_WIDTH{1'b0}}; 1s
        end
        else begin
            if (local_clock >= {TIMESTAMP_WIDTH{1'b1}}) begin
                local_clock <= {TIMESTAMP_WIDTH{1'b0}};
            end
            else begin
                local_clock <= local_clock + CLOCK_PERIOD_PS;
            end
        end
    end

endmodule
