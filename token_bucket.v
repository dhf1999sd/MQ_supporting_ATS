`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         TSN@NNS
// Engineer:        Wenxue Wu
// 
// Create Date:     2024/07/13
// Design Name:     Token Bucket Algorithm
// Module Name:     token_bucket
// Project Name:    ATS_with_mult_queue_v11
// Target Devices:  ZYNQ
// Tool Versions:   VIVADO 2023.2
// Description:     This module implements the Token Bucket algorithm for Asynchronous Traffic
//                  Shaping (ATS). It calculates the frame eligibility time based on flow
//                  parameters and traffic conditions. The implementation uses a state machine
//                  to ensure proper sequential calculation and avoid timing hazards.
// 
// Dependencies:    None
// 
// Revision:     v1.0
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module token_bucket#(
    parameter       TIME_WIDTH = 59 // Width of time-related signals in bits
)(
    // System Signals
    input  wire                           clk,
    input  wire                           reset,
    // Control Signals
    input  wire                           start_flag,
    input  wire                           read_end_flag,
    input  wire                           match_finish_flag,
    // Frame and Flow Parameters
    input  wire [15:0]                    frame_length,
    input  wire [31:0]                    committed_information_rate,    // [ps/Byte]
    input  wire [31:0]                    committed_burst_size,          // [Byte]
    // Time Inputs
    input  wire [TIME_WIDTH-1:0]          arrival_time,                  // [ps]
    input  wire [TIME_WIDTH-1:0]          group_eligibility_time,        // [ps]
    input  wire [TIME_WIDTH-1:0]          bucket_empty_time,             // [ps]
    input  wire [TIME_WIDTH-1:0]          max_residence_time,            // [ps]
    // Outputs
    output reg                            start_match_flag,
    output reg                            frame_discard_flag,
    output reg                            frame_eligible_time_OK,
    output reg  [TIME_WIDTH-1:0]          frame_eligible_time,           // [ps]
    output reg  [TIME_WIDTH-1:0]          update_bucket_empty_time,         // [ps]
    output reg  [TIME_WIDTH-1:0]          update_group_eligibility_time     // [ps]
);

/***************function**************/

/***************parameter*************/
    localparam S_IDLE              = 4'd0;
    localparam S_CALC_DURATIONS    = 4'd1;
    localparam S_WAIT_1            = 4'd2;
    localparam S_CALC_TIMES        = 4'd3;
    localparam S_CALC_FET_TEMP     = 4'd4; // Calculate Frame Eligible Time (Temporary)
    localparam S_LATCH_FET         = 4'd5; // Latch FET to avoid timing hazard
    localparam S_CHECK_RESIDENCE   = 4'd6;
    localparam S_SET_OK            = 4'd7;
    localparam S_WAIT_END          = 4'd8;
    localparam S_DISCARD_FRAME     = 4'd9;

/***************port******************/             

/***************mechine***************/

/***************reg*******************/
    reg [3:0]                             token_state;
    reg [TIME_WIDTH-1:0]                  length_recovery_duration;      // [ps]
    reg [TIME_WIDTH-1:0]                  empty_to_full_duration;        // [ps]
    reg [TIME_WIDTH-1:0]                  scheduler_eligibility_time;    // [ps]
    reg [TIME_WIDTH-1:0]                  bucket_full_time;              // [ps]
    reg [TIME_WIDTH-1:0]                  frame_eligible_time_temp;      // Temporary register for FET calculation
    reg [TIME_WIDTH-1:0]                  max_allowable_time;            // Pre-calculated max residence time check

/***************wire******************/

/***************component*************/

/***************assign****************/

/***************always****************/
    always @(posedge clk) begin
        if (reset) begin
            // Reset all outputs
            frame_discard_flag               <= 1'b0;
            frame_eligible_time_OK           <= 1'b0;
            frame_eligible_time              <= {TIME_WIDTH{1'b0}};
            update_bucket_empty_time         <= {TIME_WIDTH{1'b0}};
            update_group_eligibility_time    <= {TIME_WIDTH{1'b0}};
            // Reset internal state
            token_state                      <= S_IDLE;
            length_recovery_duration         <= {TIME_WIDTH{1'b0}};
            empty_to_full_duration           <= {TIME_WIDTH{1'b0}};
            scheduler_eligibility_time       <= {TIME_WIDTH{1'b0}};
            bucket_full_time                 <= {TIME_WIDTH{1'b0}};
            frame_eligible_time_temp         <= {TIME_WIDTH{1'b0}};
            max_allowable_time               <= {TIME_WIDTH{1'b0}};
            start_match_flag                 <= 1'b0;
        end else begin
            case (token_state)
                S_IDLE: begin
                    if (start_flag) begin
                        frame_discard_flag           <= 1'b0;
                        frame_eligible_time_OK       <= 1'b0;
                        start_match_flag             <= 1'b1; // Indicate start of processing
                    end
                    if(match_finish_flag) begin
                        start_match_flag <= 1'b0; // Reset match flag after processing
                        token_state      <= S_CALC_DURATIONS;
                    end
                end

                S_CALC_DURATIONS: begin
                    length_recovery_duration <= frame_length * committed_information_rate;
                    empty_to_full_duration   <= committed_burst_size * committed_information_rate;
                    token_state              <= S_WAIT_1;
                end

                S_WAIT_1: begin
                    token_state <= S_CALC_TIMES;
                end

                S_CALC_TIMES: begin
                    scheduler_eligibility_time <= bucket_empty_time + length_recovery_duration;
                    bucket_full_time           <= bucket_empty_time + empty_to_full_duration;
                    token_state                <= S_CALC_FET_TEMP;
                end

                S_CALC_FET_TEMP: begin
                    // Calculate Frame Eligible Time into a temporary register
                    frame_eligible_time_temp <= (arrival_time > group_eligibility_time && arrival_time > scheduler_eligibility_time) ? arrival_time :
                        (group_eligibility_time > scheduler_eligibility_time) ? group_eligibility_time : scheduler_eligibility_time;
                    // Pre-calculate the max allowable time for the check in the next state
                    max_allowable_time       <= arrival_time + max_residence_time;
                    token_state              <= S_LATCH_FET;
                end

                S_LATCH_FET: begin
                    // Latch the calculated value into the final register to ensure timing stability
                    frame_eligible_time <= frame_eligible_time_temp;
                    token_state         <= S_CHECK_RESIDENCE;
                end

                S_CHECK_RESIDENCE: begin
                    if (frame_eligible_time <= max_allowable_time) begin
                        // Frame is within residence time limit
                        update_group_eligibility_time <= frame_eligible_time;
                        update_bucket_empty_time      <= (frame_eligible_time < bucket_full_time) ?
                            scheduler_eligibility_time :
                            scheduler_eligibility_time + frame_eligible_time - bucket_full_time;
                        frame_discard_flag            <= 1'b0;
                        token_state                   <= S_SET_OK;
                    end else begin
                        // Frame must be discarded
                        token_state  <= S_DISCARD_FRAME;
                    end
                end

                S_SET_OK: begin
                    frame_eligible_time_OK <= 1'b1;
                    token_state            <= S_WAIT_END;
                end

                S_DISCARD_FRAME: begin
                    // Also set OK flag to signal completion of processing (with discard decision)
                    frame_eligible_time_OK <= 1'b1;
                    frame_discard_flag     <= 1'b1;
                    token_state            <= S_WAIT_END;
                end

                S_WAIT_END: begin
                    if (read_end_flag) begin
                        frame_eligible_time_OK <= 1'b0;
                        token_state            <= S_IDLE;
                        frame_discard_flag     <= 1'b0; // Reset discard flag for next operation
                    end
                end

                default:
                    token_state <= S_IDLE; // Default to IDLE state
            endcase
        end
    end

endmodule
