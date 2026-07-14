`timescale 1ns / 1ps

module key_gen(
    input       clk      ,
    input       key1     ,
    input       key2     ,
    input       key3     ,
    output reg  key1_rdy ,
    output reg  key2_rdy ,
    output reg  key3_rdy
);

    reg [21:0] count1;
    reg [21:0] count2;
    reg [21:0] count3;
    reg [21:0] c_max = 4194303;
    reg [21:0] c_button = 4000000;

    always @(posedge clk) begin
        if (key1 == 1) begin
            if (count1 < c_max) begin
                count1 <= count1 + 1;
            end else begin
                count1 <= count1;
            end
        end else begin
            count1 <= 0;
        end

        key1_rdy <= (count1 == c_button) ? 1'b1 : 1'b0;
    end

    always @(posedge clk) begin
        if (key2 == 1) begin
            if (count2 < c_max) begin
                count2 <= count2 + 1;
            end else begin
                count2 <= count2;
            end
        end else begin
            count2 <= 0;
        end

        key2_rdy <= (count2 == c_button) ? 1'b1 : 1'b0;
    end

    always @(posedge clk) begin
        if (key3 == 1) begin
            if (count3 < c_max) begin
                count3 <= count3 + 1;
            end else begin
                count3 <= count3;
            end
        end else begin
            count3 <= 0;
        end

        key3_rdy <= (count3 == c_button) ? 1'b1 : 1'b0;
    end

endmodule