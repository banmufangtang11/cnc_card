`timescale 1ns / 1ps

// 编码器信号滤波模块
// 对编码器A/B相信号进行去抖滤波，消除噪声干扰

module filter_encode(
    input         clk,     // 时钟信号
    input         rst_n,   // 复位信号（低有效）
    input         puls,    // 原始脉冲输入
    output reg    filter   // 滤波后脉冲输出
);

localparam FILTER_CNT_END = 'd20;

reg [7:0] filter_cnt;
reg       puls_t, puls_tt;
reg       flag, flag_cnt;

wire puls_neg = (puls_tt & !puls_t);
wire puls_pos = (!puls_tt & puls_t);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        puls_t <= 1'b1;
        puls_tt <= 1'b1;
    end else begin
        puls_t <= puls;
        puls_tt <= puls_t;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        filter_cnt <= 'd0;
    end else if (filter_cnt == FILTER_CNT_END || puls_neg || puls_pos) begin
        filter_cnt <= 'd0;
    end else if (flag_cnt) begin
        filter_cnt <= filter_cnt + 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        flag_cnt <= 'd0;
    end else if (filter_cnt == FILTER_CNT_END) begin
        flag_cnt <= 'd0;
    end else if (puls_neg || puls_pos) begin
        flag_cnt <= 'd1;
    end
end

always @(*) begin
    flag = (!rst_n) ? 'd1 : (filter_cnt == FILTER_CNT_END) ? 'd1 : 'd0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        filter <= 'd0;
    end else if (flag) begin
        filter <= puls_tt;
    end
end

endmodule