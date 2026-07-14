`timescale 1ns / 1ps

// 2ms时钟生成模块
// 产生FIFO读使能信号，周期为2ms

module clk_2ms(
    input         clk,    // 时钟信号
    input         valid,  // 插补有效信号
    input         empty,  // FIFO空标志
    output reg    clkout  // 2ms脉冲输出
);

reg [17:0] counter;

always @(posedge clk) begin
    if (!empty && valid) begin
        if (counter == 18'h3d090) begin
            clkout <= 1'b1;
            counter <= 18'h0;
        end else begin
            counter <= counter + 18'h1;
            clkout <= 1'b0;
        end
    end else begin
        clkout <= 1'b0;
        counter <= 18'h0;
    end
end

endmodule