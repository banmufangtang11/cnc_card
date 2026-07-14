`timescale 1ns / 1ps

module tool_set_ctrl(
    input           clk           ,
    input           rst_ts        ,
    input   [31:0] aux_data      ,
    output  reg    enable_tlset
);

    always @(posedge clk or negedge rst_ts) begin
        if (!rst_ts) begin
            enable_tlset <= 1'b0;
        end else begin
            case (aux_data[3:0])
                4'b0010: enable_tlset <= 1'b1;
                4'b0011: enable_tlset <= 1'b0;
                default: enable_tlset <= enable_tlset;
            endcase
        end
    end

endmodule