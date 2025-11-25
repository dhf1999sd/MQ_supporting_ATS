module comparator #(
    parameter DATA_WIDTH = 59
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire [DATA_WIDTH-1:0]  in_data_0,
    input  wire [DATA_WIDTH-1:0]  in_data_1,
    input  wire [DATA_WIDTH-1:0]  in_data_2,
    input  wire [DATA_WIDTH-1:0]  local_clock,
    output reg  [1:0]             min_index_out,
    output reg                    min_index_out_flag
);

    // --------- 1st stage: Zero mask & latch inputs ---------
    reg [DATA_WIDTH-1:0] v0_reg, v1_reg, v2_reg;
    always @(posedge clk) begin
        if (reset) begin
            v0_reg <= {DATA_WIDTH{1'b1}};
            v1_reg <= {DATA_WIDTH{1'b1}};
            v2_reg <= {DATA_WIDTH{1'b1}};
        end else begin
            v0_reg <= (in_data_0 != 0) ? in_data_0 : {DATA_WIDTH{1'b1}};
            v1_reg <= (in_data_1 != 0) ? in_data_1 : {DATA_WIDTH{1'b1}};
            v2_reg <= (in_data_2 != 0) ? in_data_2 : {DATA_WIDTH{1'b1}};
        end
    end

    // --------- 2nd stage: Compare v0_reg and v1_reg ---------
    reg [DATA_WIDTH-1:0] min_v01_reg;
    reg [1:0]            idx_v01_reg;
    always @(posedge clk) begin
        if (reset) begin
            min_v01_reg <= {DATA_WIDTH{1'b1}};
            idx_v01_reg <= 2'd0;
        end else begin
            if (v0_reg <= v1_reg) begin
                min_v01_reg <= v0_reg;
                idx_v01_reg <= 2'd0;
            end else begin
                min_v01_reg <= v1_reg;
                idx_v01_reg <= 2'd1;
            end
        end
    end

    // --------- 3rd stage: Compare above with v2_reg & valid output ---------
    reg [DATA_WIDTH-1:0] min_val_reg;
    reg [1:0]            min_idx_reg;
    reg [DATA_WIDTH-1:0] local_clock_pipe;
    always @(posedge clk) begin
        if (reset) begin
            min_val_reg      <= {DATA_WIDTH{1'b1}};
            min_idx_reg      <= 2'd0;
            local_clock_pipe <= {DATA_WIDTH{1'b1}};
        end else begin
            if (min_v01_reg <= v2_reg) begin
                min_val_reg <= min_v01_reg;
                min_idx_reg <= idx_v01_reg;
            end else begin
                min_val_reg <= v2_reg;
                min_idx_reg <= 2'd2;
            end
            local_clock_pipe <= local_clock;
        end
    end

    wire valid = (min_val_reg != {DATA_WIDTH{1'b1}}) && (min_val_reg <= local_clock_pipe);

    always @(posedge clk) begin
        if (reset) begin
            min_index_out      <= 2'b0;
            min_index_out_flag <= 1'b0;
        end else begin
            min_index_out      <= min_idx_reg;
            min_index_out_flag <= valid;
        end
    end

endmodule
