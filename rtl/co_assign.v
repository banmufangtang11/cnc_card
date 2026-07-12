`timescale 1ns / 1ps

module co_assign (
    input         clk,
    input         rst,
    input         co1, co2, co3, co4, co5, co6, co7, co8,
    input         px_in, py_in, pz_in, pa_in,
    input         dx_in, dy_in, dz_in, da_in,
    input         mag_sel,
    input         md, mp,
    output reg    p1, p2, p3, p4, p5, p6, p7, p8,
    output reg    d1, d2, d3, d4, d5, d6, d7, d8
);

reg [7:0] coreg;
reg       mag;

always @(posedge clk) begin
    coreg[0] <= co1;
    coreg[1] <= co2;
    coreg[2] <= co3;
    coreg[3] <= co4;
    coreg[4] <= co5;
    coreg[5] <= co6;
    coreg[6] <= co7;
    coreg[7] <= co8;
    mag <= mag_sel;

    if (mag == 1'b1) begin
        d1 <= 1'b0; p1 <= 1'b0;
        d2 <= 1'b0; p2 <= 1'b0;
        d3 <= 1'b0; p3 <= 1'b0;
        d4 <= 1'b0; p4 <= 1'b0;
        d5 <= 1'b0; p5 <= 1'b0;
        d6 <= 1'b0; p6 <= 1'b0;
        d7 <= 1'b0; p7 <= 1'b0;
        d8 <= md; p8 <= mp;
    end else begin
        case (coreg)
            8'b00001111: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=dz_in;p3<=pz_in; d4<=da_in;p4<=pa_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00010111: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=dz_in;p3<=pz_in; d4<=1'b0;p4<=1'b0; d5<=da_in;p5<=pa_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00100111: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=dz_in;p3<=pz_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=da_in;p6<=pa_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01000111: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=dz_in;p3<=pz_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10000111: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=dz_in;p3<=pz_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b00011011: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=1'b0;p3<=1'b0; d4<=dz_in;p4<=pz_in; d5<=da_in;p5<=pa_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00101011: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=1'b0;p3<=1'b0; d4<=dz_in;p4<=pz_in; d5<=1'b0;p5<=1'b0; d6<=da_in;p6<=pa_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01001011: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=1'b0;p3<=1'b0; d4<=dz_in;p4<=pz_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10001011: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=1'b0;p3<=1'b0; d4<=dz_in;p4<=pz_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b00110011: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dz_in;p5<=pz_in; d6<=da_in;p6<=pa_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01010011: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10010011: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b01100011: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10100011: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b11000011: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=da_in;p8<=pa_in; end
            8'b00011101: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=dy_in;p3<=py_in; d4<=dz_in;p4<=pz_in; d5<=da_in;p5<=pa_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00101101: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=dy_in;p3<=py_in; d4<=dz_in;p4<=pz_in; d5<=1'b0;p5<=1'b0; d6<=da_in;p6<=pa_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01001101: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=dy_in;p3<=py_in; d4<=dz_in;p4<=pz_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10001101: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=dy_in;p3<=py_in; d4<=dz_in;p4<=pz_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b00110101: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=dz_in;p5<=pz_in; d6<=da_in;p6<=pa_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01010101: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10010101: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b01100101: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10100101: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b11000101: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=da_in;p8<=pa_in; end
            8'b00111001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=dz_in;p5<=pz_in; d6<=da_in;p6<=pa_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01011001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10011001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b01101001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10101001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b11001001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=da_in;p8<=pa_in; end
            8'b01110001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=dz_in;p6<=pz_in; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10110001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b11010001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=da_in;p8<=pa_in; end
            8'b11100001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dy_in;p6<=py_in; d7<=dz_in;p7<=pz_in; d8<=da_in;p8<=pa_in; end
            8'b00011110: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=dy_in;p3<=py_in; d4<=dz_in;p4<=pz_in; d5<=da_in;p5<=pa_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00101110: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=dy_in;p3<=py_in; d4<=dz_in;p4<=pz_in; d5<=1'b0;p5<=1'b0; d6<=da_in;p6<=pa_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01001110: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=dy_in;p3<=py_in; d4<=dz_in;p4<=pz_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10001110: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=dy_in;p3<=py_in; d4<=dz_in;p4<=pz_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b00110110: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=dz_in;p5<=pz_in; d6<=da_in;p6<=pa_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01010110: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10010110: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b01100110: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10100110: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b11000110: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=da_in;p8<=pa_in; end
            8'b00111010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=dz_in;p5<=pz_in; d6<=da_in;p6<=pa_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01011010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10011010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b01101010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10101010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b11001010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=da_in;p8<=pa_in; end
            8'b01110010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=dz_in;p6<=pz_in; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10110010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b11010010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=da_in;p8<=pa_in; end
            8'b11100010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dy_in;p6<=py_in; d7<=dz_in;p7<=pz_in; d8<=da_in;p8<=pa_in; end
            8'b00111100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=dy_in;p4<=py_in; d5<=dz_in;p5<=pz_in; d6<=da_in;p6<=pa_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01011100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=dy_in;p4<=py_in; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10011100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=dy_in;p4<=py_in; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b01101100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10101100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b11001100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=da_in;p8<=pa_in; end
            8'b01110100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=dz_in;p6<=pz_in; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10110100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b11010100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=da_in;p8<=pa_in; end
            8'b11100100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dy_in;p6<=py_in; d7<=dz_in;p7<=pz_in; d8<=da_in;p8<=pa_in; end
            8'b01111000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dx_in;p4<=px_in; d5<=dy_in;p5<=py_in; d6<=dz_in;p6<=pz_in; d7<=da_in;p7<=pa_in; d8<=1'b0;p8<=1'b0; end
            8'b10111000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dx_in;p4<=px_in; d5<=dy_in;p5<=py_in; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=da_in;p8<=pa_in; end
            8'b11011000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dx_in;p4<=px_in; d5<=dy_in;p5<=py_in; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=da_in;p8<=pa_in; end
            8'b11101000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dx_in;p4<=px_in; d5<=1'b0;p5<=1'b0; d6<=dy_in;p6<=py_in; d7<=dz_in;p7<=pz_in; d8<=da_in;p8<=pa_in; end
            8'b11110000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dx_in;p5<=px_in; d6<=dy_in;p6<=py_in; d7<=dz_in;p7<=pz_in; d8<=da_in;p8<=pa_in; end

            8'b00000111: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=dz_in;p3<=pz_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00001011: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=1'b0;p3<=1'b0; d4<=dz_in;p4<=pz_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00010011: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00100011: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01000011: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=1'b0;p8<=1'b0; end
            8'b10000011: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dz_in;p8<=pz_in; end
            8'b00001101: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=dy_in;p3<=py_in; d4<=dz_in;p4<=pz_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00010101: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00100101: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01000101: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=1'b0;p8<=1'b0; end
            8'b10000101: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dz_in;p8<=pz_in; end
            8'b00011001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00101001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01001001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=1'b0;p8<=1'b0; end
            8'b10001001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dz_in;p8<=pz_in; end
            8'b00110001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01010001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=1'b0;p8<=1'b0; end
            8'b10010001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dz_in;p8<=pz_in; end
            8'b01100001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dy_in;p6<=py_in; d7<=dz_in;p7<=pz_in; d8<=1'b0;p8<=1'b0; end
            8'b10100001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dy_in;p6<=py_in; d7<=1'b0;p7<=1'b0; d8<=dz_in;p8<=pz_in; end
            8'b11000001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dy_in;p7<=py_in; d8<=dz_in;p8<=pz_in; end
            8'b00001110: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=dy_in;p3<=py_in; d4<=dz_in;p4<=pz_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00010110: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00100110: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01000110: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=1'b0;p8<=1'b0; end
            8'b10000110: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dz_in;p8<=pz_in; end
            8'b00011010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00101010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01001010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=1'b0;p8<=1'b0; end
            8'b10001010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dz_in;p8<=pz_in; end
            8'b00110010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01010010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=1'b0;p8<=1'b0; end
            8'b10010010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dz_in;p8<=pz_in; end
            8'b01100010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dy_in;p6<=py_in; d7<=dz_in;p7<=pz_in; d8<=1'b0;p8<=1'b0; end
            8'b10100010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dy_in;p6<=py_in; d7<=1'b0;p7<=1'b0; d8<=dz_in;p8<=pz_in; end
            8'b11000010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dy_in;p7<=py_in; d8<=dz_in;p8<=pz_in; end
            8'b00011100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=dy_in;p4<=py_in; d5<=dz_in;p5<=pz_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00101100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01001100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=1'b0;p8<=1'b0; end
            8'b10001100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dz_in;p8<=pz_in; end
            8'b00110100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01010100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b10010100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dz_in;p8<=pz_in; end
            8'b01100100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dy_in;p6<=py_in; d7<=dz_in;p7<=pz_in; d8<=1'b0;p8<=1'b0; end
            8'b10100100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dy_in;p6<=py_in; d7<=1'b0;p7<=1'b0; d8<=dz_in;p8<=pz_in; end
            8'b11000100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dy_in;p7<=py_in; d8<=dz_in;p8<=pz_in; end
            8'b00111000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dx_in;p4<=px_in; d5<=dy_in;p5<=py_in; d6<=dz_in;p6<=pz_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01011000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dx_in;p4<=px_in; d5<=dy_in;p5<=py_in; d6<=1'b0;p6<=1'b0; d7<=dz_in;p7<=pz_in; d8<=1'b0;p8<=1'b0; end
            8'b10011000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dx_in;p4<=px_in; d5<=dy_in;p5<=py_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dz_in;p8<=pz_in; end
            8'b01101000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dx_in;p4<=px_in; d5<=1'b0;p5<=1'b0; d6<=dy_in;p6<=py_in; d7<=dz_in;p7<=pz_in; d8<=1'b0;p8<=1'b0; end
            8'b10101000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dx_in;p4<=px_in; d5<=1'b0;p5<=1'b0; d6<=dy_in;p6<=py_in; d7<=1'b0;p7<=1'b0; d8<=dz_in;p8<=pz_in; end
            8'b11001000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dx_in;p4<=px_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dy_in;p7<=py_in; d8<=dz_in;p8<=pz_in; end
            8'b01110000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dx_in;p5<=px_in; d6<=dy_in;p6<=py_in; d7<=dz_in;p7<=pz_in; d8<=1'b0;p8<=1'b0; end
            8'b10110000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dx_in;p5<=px_in; d6<=1'b0;p6<=1'b0; d7<=dy_in;p7<=py_in; d8<=dz_in;p8<=pz_in; end
            8'b11010000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dx_in;p5<=px_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dy_in;p8<=py_in; end
            8'b11100000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dx_in;p6<=px_in; d7<=dy_in;p7<=py_in; d8<=dz_in;p8<=pz_in; end

            8'b00000011: begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00000101: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00001001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00010001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00100001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dy_in;p6<=py_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01000001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dy_in;p7<=py_in; d8<=1'b0;p8<=1'b0; end
            8'b10000001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dy_in;p8<=py_in; end
            8'b00000110: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=dy_in;p3<=py_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00001010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00010010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00100010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dy_in;p6<=py_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01000010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dy_in;p7<=py_in; d8<=1'b0;p8<=1'b0; end
            8'b10000010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dy_in;p8<=py_in; end
            8'b00001100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=dy_in;p4<=py_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00010100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=1'b0;p4<=1'b0; d5<=dy_in;p5<=py_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00100100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dy_in;p6<=py_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01000100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dy_in;p7<=py_in; d8<=1'b0;p8<=1'b0; end
            8'b10000100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dy_in;p8<=py_in; end
            8'b00011000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dx_in;p4<=px_in; d5<=dy_in;p5<=py_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00101000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dx_in;p4<=px_in; d5<=1'b0;p5<=1'b0; d6<=dy_in;p6<=py_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01001000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dx_in;p4<=px_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dy_in;p7<=py_in; d8<=1'b0;p8<=1'b0; end
            8'b10001000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dx_in;p4<=px_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dy_in;p8<=py_in; end
            8'b00110000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dx_in;p5<=px_in; d6<=dy_in;p6<=py_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01010000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dx_in;p5<=px_in; d6<=1'b0;p6<=1'b0; d7<=dy_in;p7<=py_in; d8<=1'b0;p8<=1'b0; end
            8'b10010000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dx_in;p5<=px_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dy_in;p8<=py_in; end
            8'b01100000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dx_in;p6<=px_in; d7<=dy_in;p7<=py_in; d8<=1'b0;p8<=1'b0; end
            8'b10100000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dx_in;p6<=px_in; d7<=1'b0;p7<=1'b0; d8<=dy_in;p8<=py_in; end
            8'b11000000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dx_in;p7<=px_in; d8<=dy_in;p8<=py_in; end

            8'b00000001: begin d1<=dx_in;p1<=px_in; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00000010: begin d1<=1'b0;p1<=1'b0; d2<=dx_in;p2<=px_in; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00000100: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=dx_in;p3<=px_in; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00001000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=dx_in;p4<=px_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00010000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=dx_in;p5<=px_in; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b00100000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=dx_in;p6<=px_in; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
            8'b01000000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=dx_in;p7<=px_in; d8<=1'b0;p8<=1'b0; end
            8'b10000000: begin d1<=1'b0;p1<=1'b0; d2<=1'b0;p2<=1'b0; d3<=1'b0;p3<=1'b0; d4<=1'b0;p4<=1'b0; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=dx_in;p8<=px_in; end

            default:      begin d1<=dx_in;p1<=px_in; d2<=dy_in;p2<=py_in; d3<=dz_in;p3<=pz_in; d4<=da_in;p4<=pa_in; d5<=1'b0;p5<=1'b0; d6<=1'b0;p6<=1'b0; d7<=1'b0;p7<=1'b0; d8<=1'b0;p8<=1'b0; end
        endcase
    end
end

endmodule