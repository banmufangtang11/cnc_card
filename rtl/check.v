`timescale 1ns / 1ps

// 运行状态检测模块
// 检测start/stop信号和各轴限位信号，控制valid输出

module check(
    input         clk,   // 时钟信号
    input         start, // 启动信号
    input         stop,  // 停止信号
    input         empty, // FIFO空标志
    input         s1,    // X轴正限位
    input         s2,    // X轴负限位
    input         s3,    // Y轴正限位
    input         s4,    // Y轴负限位
    input         s5,    // Z轴正限位
    input         s6,    // Z轴负限位
    input         s7,    // 辅助中断信号
    output reg    valid  // 插补有效信号
);

reg         flag_start, flag_stop;
reg         f1, f2, f3, f4, f5, f6, f7;
reg [6:0]   cnt_start, cnt_stop;
reg [6:0]   c1, c2, c3, c4, c5, c6, c7;

always @(posedge clk) begin
    if (start) begin
        if (cnt_start == 7'h7d) begin
            flag_start <= 1'b1;
            cnt_start <= 7'h0;
        end else begin
            cnt_start <= cnt_start + 7'h1;
        end
    end else begin
        flag_start <= 1'b0;
        cnt_start <= 7'h0;
    end
end

always @(posedge clk) begin
    if (stop) begin
        if (cnt_stop == 7'h7d) begin
            flag_stop <= 1'b1;
            cnt_stop <= 7'h0;
        end else begin
            cnt_stop <= cnt_stop + 7'h1;
        end
    end else begin
        flag_stop <= 1'b0;
        cnt_stop <= 7'h0;
    end
end

always @(posedge clk) begin
    f1 <= (s1 && (c1 == 7'h7d)) ? 1'b1 : (s1 ? f1 : 1'b0);
    c1 <= s1 ? ((c1 == 7'h7d) ? 7'h0 : c1 + 7'h1) : 7'h0;
end

always @(posedge clk) begin
    f2 <= (s2 && (c2 == 7'h7d)) ? 1'b1 : (s2 ? f2 : 1'b0);
    c2 <= s2 ? ((c2 == 7'h7d) ? 7'h0 : c2 + 7'h1) : 7'h0;
end

always @(posedge clk) begin
    f3 <= (s3 && (c3 == 7'h7d)) ? 1'b1 : (s3 ? f3 : 1'b0);
    c3 <= s3 ? ((c3 == 7'h7d) ? 7'h0 : c3 + 7'h1) : 7'h0;
end

always @(posedge clk) begin
    f4 <= (s4 && (c4 == 7'h7d)) ? 1'b1 : (s4 ? f4 : 1'b0);
    c4 <= s4 ? ((c4 == 7'h7d) ? 7'h0 : c4 + 7'h1) : 7'h0;
end

always @(posedge clk) begin
    f5 <= (s5 && (c5 == 7'h7d)) ? 1'b1 : (s5 ? f5 : 1'b0);
    c5 <= s5 ? ((c5 == 7'h7d) ? 7'h0 : c5 + 7'h1) : 7'h0;
end

always @(posedge clk) begin
    f6 <= (s6 && (c6 == 7'h7d)) ? 1'b1 : (s6 ? f6 : 1'b0);
    c6 <= s6 ? ((c6 == 7'h7d) ? 7'h0 : c6 + 7'h1) : 7'h0;
end

always @(posedge clk) begin
    f7 <= (s7 && (c7 == 7'h7d)) ? 1'b1 : (s7 ? f7 : 1'b0);
    c7 <= s7 ? ((c7 == 7'h7d) ? 7'h0 : c7 + 7'h1) : 7'h0;
end

always @(posedge clk) begin
    if (flag_stop || f1 || f2 || f3 || f4 || f5 || f6 || f7) begin
        valid <= 1'b0;
    end else if (flag_start) begin
        valid <= 1'b1;
    end else if (empty) begin
        valid <= 1'b0;
    end else begin
        valid <= 1'b0;
    end
end

endmodule