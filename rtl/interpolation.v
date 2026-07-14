`timescale 1ns / 1ps

// DDA插补核心模块
// 基于累加器原理生成脉冲，实现匀速运动控制

module interpolation(
    input         clk,    // 时钟信号
    input         valid,  // 数据有效信号
    input  [16:0] data,   // 插补参数（脉冲频率控制）
    output reg    q       // 输出脉冲
);

localparam CLK_DELAY = 249999;
localparam CLOCKS = 250000;

reg        q_t, q_tt;
reg [31:0] clk_num;
reg        clk_flag;
reg        delta_flag;
reg [31:0] plus_num;
reg [31:0] plus_num_t;
reg [31:0] delta;
reg [31:0] data_reg;
reg [31:0] plus_total;
reg [31:0] sum;

wire plus_pos = (!q_tt && q_t);

always @(posedge clk) begin
    data_reg <= valid ? data : 'd0;
end

always @(posedge clk) begin
    delta <= valid ? (data_reg - plus_num_t) : 'd0;
end

always @(posedge clk) begin
    if (!valid) begin
        delta_flag <= 'd0;
    end else if (delta_flag && clk_flag) begin
        delta_flag <= 'd0;
    end else if (delta != 0 && clk_flag) begin
        delta_flag <= 'd1;
    end
end

always @(posedge clk) begin
    clk_flag <= (valid && (clk_num == CLK_DELAY - 1'b1)) ? 'd1 : 'd0;
end

always @(posedge clk) begin
    if (!valid) begin
        sum <= 'd0;
    end else if (clk_flag) begin
        sum <= 'd0;
    end else if (sum >= CLOCKS) begin
        sum <= sum - CLOCKS;
    end else begin
        sum <= sum + data_reg;
    end
end

always @(posedge clk) begin
    if (!valid) begin
        q <= 'd0;
    end else if (clk_flag) begin
        q <= 'd0;
    end else if (sum >= CLOCKS / 2 && sum < CLOCKS) begin
        q <= 'd1;
    end else if (sum >= CLOCKS) begin
        q <= 'd0;
    end
end

always @(posedge clk) begin
    if (!valid) begin
        clk_num <= 'd0;
    end else if (clk_num == CLK_DELAY - 1'b1) begin
        clk_num <= 'd0;
    end else begin
        clk_num <= clk_num + 1'b1;
    end
end

always @(posedge clk) begin
    if (!valid) begin
        plus_num <= 'd0;
    end else if (clk_flag) begin
        plus_num <= 'd0;
    end else if (plus_pos) begin
        plus_num <= plus_num + 1'b1;
    end
end

always @(posedge clk) begin
    plus_num_t <= valid ? plus_num : 'd0;
end

always @(posedge clk) begin
    if (!valid) begin
        plus_total <= 'd0;
    end else if (plus_pos) begin
        plus_total <= plus_total + 1'b1;
    end
end

always @(posedge clk) begin
    if (!valid) begin
        q_t <= 'd0;
        q_tt <= 'd0;
    end else begin
        q_t <= q;
        q_tt <= q_t;
    end
end

endmodule