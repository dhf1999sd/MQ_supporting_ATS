module group_id_simple_map(
    input  wire [3:0] dst_port,  // 目标端口 one-hot
    input  wire [3:0] src_port,  // 入端口 one-hot
    input  wire [1:0] pri,       // 优先级
    output reg  [3:0] group_id
);

    always @(*) begin
        group_id = 4'd0; // 默认值

        // 入端口和目标端口不会相同（互斥）

        if(dst_port == 4'b1000) begin
            case(src_port)
                4'b0001: group_id = 0 + pri;
                4'b0010: group_id = 4 + pri;
                4'b0100: group_id = 8 + pri;
                default: group_id = 0;
            endcase
        end
        else if(dst_port == 4'b0100) begin
            case(src_port)
                4'b0001: group_id = 0 + pri;
                4'b0010: group_id = 4 + pri;
                4'b1000: group_id = 8 + pri;
                default: group_id = 0;
            endcase
        end
        else if(dst_port == 4'b0010) begin
            case(src_port)
                4'b0001: group_id = 0 + pri;
                4'b0100: group_id = 4 + pri;
                4'b1000: group_id = 8 + pri;
                default: group_id = 0;
            endcase
        end
        else if(dst_port == 4'b0001) begin
            case(src_port)
                4'b0010: group_id = 0 + pri;
                4'b0100: group_id = 4 + pri;
                4'b1000: group_id = 8 + pri;
                default: group_id = 0;
            endcase
        end
        else begin
            group_id = 0;
        end
    end

endmodule
