`timescale 1ns / 1ps

module aux_fbac(
    input           clk         ,
    input           rst         ,
    input   [31:0] data        ,
    input           trigger     ,
    input           out_range   ,
    input           breakdown   ,
    input           ahe_fin     ,
    input           back_fin    ,
    input           rot_count   ,
    input           loos_fin    ,
    output  reg [31:0] data_para  ,
    output  reg    aux_intrupt
);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            data_para <= 32'b0;
            aux_intrupt <= 1'b0;
        end else begin
            if (trigger == 1'b1) begin
                aux_intrupt <= 1'b1;
                data_para[0] <= 1'b1;
            end else begin
                aux_intrupt <= 1'b0;
                data_para[0] <= 1'b0;
            end

            data_para[1] <= out_range;
            data_para[2] <= ~breakdown;

            if (data == 32'b00000000000000000000000000001000) begin
                data_para[3] <= 1'b1;
            end else if (data == 32'b00000000000000000000000000000000) begin
                data_para[3] <= 1'b0;
            end

            data_para[4] <= ~ahe_fin;
            data_para[5] <= ~back_fin;

            if (data == 32'b00000000000000000000000001000000) begin
                data_para[6] <= 1'b1;
            end else if (data == 32'b00000000000000000000000000000000) begin
                data_para[6] <= 1'b0;
            end

            data_para[7] <= ~loos_fin;
        end
    end

endmodule