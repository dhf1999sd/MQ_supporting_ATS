`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:          TSN@NNS
// Engineer:         Wenxue Wu
// Create Date:      2024/07/04 17:16:55
// Module Name:      frame_eligbility_calculator
// Target Devices:   ZYNQ
// Tool Versions:    VIVADO 2023.2
// Description:      Frame Eligibility Calculator for ATS (Asynchronous Traffic Shaping)
//////////////////////////////////////////////////////////////////////////////////

module frame_eligbility_calculator #(
    parameter NUM_FLOW         = 2,
    parameter TIMESTAMP_WIDTH  = 59
  ) (
    input  wire                           clk,
    input  wire                           reset,
    input  wire [31:0]                    flow_id,
    input  wire [TIMESTAMP_WIDTH-1:0]     arrival_time,
    input  wire                           read_end_flag,
    input  wire [3:0]                     group_id,
    input  wire                           start_flag,
    input  wire [15:0]                    frame_length,
    output wire                           frame_discard_flag,
    output wire [TIMESTAMP_WIDTH-1:0]     frame_eligible_time,
    output wire                           frame_eligible_time_OK
  );

  //========================================================================
  // Internal Signals
  //========================================================================
  wire                                  start_match_flag;
  wire                                  match_finish_flag;
  wire [TIMESTAMP_WIDTH-1:0]            group_eligibility_time;                   // [ps]
  wire [TIMESTAMP_WIDTH-1:0]            update_bucket_empty_time;                    // [ps]
  wire [TIMESTAMP_WIDTH-1:0]            update_group_eligibility_time;               // [ps]
  wire [TIMESTAMP_WIDTH-1:0]            bucket_empty_time;                        // [ps]
  wire [TIMESTAMP_WIDTH-1:0]            max_residence_time;                       // [ps]
  wire [31:0]                           bucket_size;
  wire [31:0]                           token_rate;
  reg  [TIMESTAMP_WIDTH-1:0]            bucket_empty_to_full_time[NUM_FLOW-1:0];  // [ps]

  // Delayed update flag to break combinational loop
  reg                                   update_flag;

  //========================================================================
  // Break Combinational Loop Logic
  //========================================================================
  always @(posedge clk)
  begin
    if (reset)
    begin
      update_flag <= 1'b0;
    end
    else
    begin
      update_flag <= frame_eligible_time_OK & !frame_discard_flag;
    end
  end


  //========================================================================
  // ATS Shaper Parameter Match (flow_entry_manager)
  //========================================================================
  flow_entry_manager u_flow_entry_manager (
                       .clk                        (clk   ),
                       .reset                      (reset ),
                       .flow_id                    (flow_id),
                       .group_id                   (group_id),
                       .update_flag                (update_flag),
                       .match_finish_flag             (match_finish_flag),
                       .start_match_flag                 (start_match_flag),
                       .bucket_size                (bucket_size),
                       .token_rate                 (token_rate),
                       .max_residence_time         (max_residence_time),
                       .bucket_empty_time          (bucket_empty_time),
                       .update_bucket_empty_time      (update_bucket_empty_time),
                       .group_eligibility_time     (group_eligibility_time),
                       .update_group_eligibility_time (update_group_eligibility_time)
                     );

  //========================================================================
  // ATS Shaper (Token Bucket Algorithm)
  //========================================================================
  token_bucket u_token_bucket (
                 .clk                            (clk),
                 .reset                          (reset),
                 .start_flag                     (start_flag),
                 .start_match_flag               (start_match_flag),
                 .match_finish_flag             (match_finish_flag),
                 .arrival_time                   (arrival_time),
                 .frame_length                   (frame_length),
                 .committed_burst_size           (bucket_size),
                 .committed_information_rate     (token_rate),
                 .bucket_empty_time              (bucket_empty_time),
                 .group_eligibility_time         (group_eligibility_time),
                 .update_group_eligibility_time     (update_group_eligibility_time),
                 .frame_eligible_time            (frame_eligible_time),
                 .update_bucket_empty_time          (update_bucket_empty_time),
                 .max_residence_time             (max_residence_time),
                 .frame_eligible_time_OK         (frame_eligible_time_OK),
                 .frame_discard_flag                   (frame_discard_flag),
                 .read_end_flag                  (read_end_flag)
               );

endmodule
