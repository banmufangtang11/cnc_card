`timescale 1ns / 1ps

// JOG手动运动控制模块
// 处理4轴(X/Y/Z/A)的手动正反向运动，包含按键消抖和脉冲生成逻辑
// 支持限位信号(s1-s6)的保护功能

module jog(
    input         clk,        // 时钟信号
    input         pos_x,      // X轴正向按键
    input         neg_x,      // X轴负向按键
    input         pos_y,      // Y轴正向按键
    input         neg_y,      // Y轴负向按键
    input         pos_z,      // Z轴正向按键
    input         neg_z,      // Z轴负向按键
    input         pos_a,      // A轴正向按键
    input         neg_a,      // A轴负向按键
    input         s1,         // X轴正限位
    input         s2,         // X轴负限位
    input         s3,         // Y轴正限位
    input         s4,         // Y轴负限位
    input         s5,         // Z轴正限位
    input         s6,         // Z轴负限位

    output reg    dir_x,      // X轴方向输出(1=正向, 0=负向)
    output reg    dir_y,      // Y轴方向输出
    output reg    dir_z,      // Z轴方向输出
    output reg    dir_a,      // A轴方向输出
    output reg    puls_x,     // X轴脉冲输出
    output reg    puls_y,     // Y轴脉冲输出
    output reg    puls_z,     // Z轴脉冲输出
    output reg    puls_a      // A轴脉冲输出
);

    reg        flag_x_pos, flag_x_neg;  // X轴按键消抖标志
    reg        flag_y_pos, flag_y_neg;  // Y轴按键消抖标志
    reg        flag_z_pos, flag_z_neg;  // Z轴按键消抖标志
    reg        flag_a_pos, flag_a_neg;  // A轴按键消抖标志
    reg        f1, f2, f3, f4, f5, f6;  // 限位信号消抖标志

    reg [ 6:0] cnt_x_pos, cnt_x_neg;    // X轴按键消抖计数器
    reg [ 6:0] cnt_y_pos, cnt_y_neg;    // Y轴按键消抖计数器
    reg [ 6:0] cnt_z_pos, cnt_z_neg;    // Z轴按键消抖计数器
    reg [ 6:0] cnt_a_pos, cnt_a_neg;    // A轴按键消抖计数器
    reg [ 6:0] c1, c2, c3, c4, c5, c6;  // 限位信号消抖计数器

    reg [15:0] cnt_puls_x_pos, cnt_puls_x_neg;  // X轴脉冲周期计数器
    reg [15:0] cnt_puls_y_pos, cnt_puls_y_neg;  // Y轴脉冲周期计数器
    reg [15:0] cnt_puls_z_pos, cnt_puls_z_neg;  // Z轴脉冲周期计数器
    reg [15:0] cnt_puls_a_pos, cnt_puls_a_neg;  // A轴脉冲周期计数器

    //------------------------------------------------------------------------
    // X轴负向按键消抖
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (neg_x) begin
            if (cnt_x_neg == 7'h7d) begin  // 消抖延时约1us(125MHz)
                flag_x_neg <= 1'b1;
                cnt_x_neg <= 7'h0;
            end else begin
                flag_x_neg <= flag_x_neg;
                cnt_x_neg <= cnt_x_neg + 7'h1;
            end
        end else begin
            flag_x_neg <= 1'b0;
            cnt_x_neg <= 7'h0;
        end
    end

    //------------------------------------------------------------------------
    // X轴正向按键消抖
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (pos_x) begin
            if (cnt_x_pos == 7'h7d) begin
                flag_x_pos <= 1'b1;
                cnt_x_pos <= 7'h0;
            end else begin
                flag_x_pos <= flag_x_pos;
                cnt_x_pos <= cnt_x_pos + 7'h1;
            end
        end else begin
            flag_x_pos <= 1'b0;
            cnt_x_pos <= 7'h0;
        end
    end

    //------------------------------------------------------------------------
    // Y轴负向按键消抖
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (neg_y) begin
            if (cnt_y_neg == 7'h7d) begin
                flag_y_neg <= 1'b1;
                cnt_y_neg <= 7'h0;
            end else begin
                flag_y_neg <= flag_y_neg;
                cnt_y_neg <= cnt_y_neg + 7'h1;
            end
        end else begin
            flag_y_neg <= 1'b0;
            cnt_y_neg <= 7'h0;
        end
    end

    //------------------------------------------------------------------------
    // Y轴正向按键消抖
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (pos_y) begin
            if (cnt_y_pos == 7'h7d) begin
                flag_y_pos <= 1'b1;
                cnt_y_pos <= 7'h0;
            end else begin
                flag_y_pos <= flag_y_pos;
                cnt_y_pos <= cnt_y_pos + 7'h1;
            end
        end else begin
            flag_y_pos <= 1'b0;
            cnt_y_pos <= 7'h0;
        end
    end

    //------------------------------------------------------------------------
    // Z轴负向按键消抖
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (neg_z) begin
            if (cnt_z_neg == 7'h7d) begin
                flag_z_neg <= 1'b1;
                cnt_z_neg <= 7'h0;
            end else begin
                flag_z_neg <= flag_z_neg;
                cnt_z_neg <= cnt_z_neg + 7'h1;
            end
        end else begin
            flag_z_neg <= 1'b0;
            cnt_z_neg <= 7'h0;
        end
    end

    //------------------------------------------------------------------------
    // Z轴正向按键消抖
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (pos_z) begin
            if (cnt_z_pos == 7'h7d) begin
                flag_z_pos <= 1'b1;
                cnt_z_pos <= 7'h0;
            end else begin
                flag_z_pos <= flag_z_pos;
                cnt_z_pos <= cnt_z_pos + 7'h1;
            end
        end else begin
            flag_z_pos <= 1'b0;
            cnt_z_pos <= 7'h0;
        end
    end

    //------------------------------------------------------------------------
    // A轴负向按键消抖
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (neg_a) begin
            if (cnt_a_neg == 7'h7d) begin
                flag_a_neg <= 1'b1;
                cnt_a_neg <= 7'h0;
            end else begin
                flag_a_neg <= flag_a_neg;
                cnt_a_neg <= cnt_a_neg + 7'h1;
            end
        end else begin
            flag_a_neg <= 1'b0;
            cnt_a_neg <= 7'h0;
        end
    end

    //------------------------------------------------------------------------
    // A轴正向按键消抖
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (pos_a) begin
            if (cnt_a_pos == 7'h7d) begin
                flag_a_pos <= 1'b1;
                cnt_a_pos <= 7'h0;
            end else begin
                flag_a_pos <= flag_a_pos;
                cnt_a_pos <= cnt_a_pos + 7'h1;
            end
        end else begin
            flag_a_pos <= 1'b0;
            cnt_a_pos <= 7'h0;
        end
    end

    //------------------------------------------------------------------------
    // 限位信号消抖
    //------------------------------------------------------------------------
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

    //------------------------------------------------------------------------
    // X轴脉冲生成逻辑
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (flag_x_neg) begin
            if (f3) begin                // X轴正限位触发，禁止运动
                dir_x <= 1'b0;
                puls_x <= 1'b0;
            end else begin
                if (cnt_puls_x_neg == 16'h3d09) begin  // 脉冲周期约0.1ms
                    dir_x <= 1'b0;
                    puls_x <= ~puls_x;
                    cnt_puls_x_neg <= 16'h0;
                end else begin
                    dir_x <= 1'b0;
                    puls_x <= puls_x;
                    cnt_puls_x_neg <= cnt_puls_x_neg + 16'h1;
                end
            end
        end else if (flag_x_pos) begin
            if (f2) begin                // X轴负限位触发，禁止运动
                dir_x <= 1'b0;
                puls_x <= 1'b0;
            end else begin
                if (cnt_puls_x_pos == 16'h3d09) begin
                    dir_x <= 1'b1;
                    puls_x <= ~puls_x;
                    cnt_puls_x_pos <= 16'h0;
                end else begin
                    dir_x <= 1'b1;
                    puls_x <= puls_x;
                    cnt_puls_x_pos <= cnt_puls_x_pos + 16'h1;
                end
            end
        end else begin
            dir_x <= 1'b0;
            puls_x <= 1'b0;
            cnt_puls_x_neg <= 16'h0;
            cnt_puls_x_pos <= 16'h0;
        end
    end

    //------------------------------------------------------------------------
    // Y轴脉冲生成逻辑
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (flag_y_neg) begin
            if (f4) begin                // Y轴正限位触发，禁止运动
                dir_y <= 1'b0;
                puls_y <= 1'b0;
            end else begin
                if (cnt_puls_y_neg == 16'h3d09) begin
                    dir_y <= 1'b0;
                    puls_y <= ~puls_y;
                    cnt_puls_y_neg <= 16'h0;
                end else begin
                    dir_y <= 1'b0;
                    puls_y <= puls_y;
                    cnt_puls_y_neg <= cnt_puls_y_neg + 16'h1;
                end
            end
        end else if (flag_y_pos) begin
            if (f1) begin                // Y轴负限位触发，禁止运动
                dir_y <= 1'b0;
                puls_y <= 1'b0;
            end else begin
                if (cnt_puls_y_pos == 16'h3d09) begin
                    dir_y <= 1'b1;
                    puls_y <= ~puls_y;
                    cnt_puls_y_pos <= 16'h0;
                end else begin
                    dir_y <= 1'b1;
                    puls_y <= puls_y;
                    cnt_puls_y_pos <= cnt_puls_y_pos + 16'h1;
                end
            end
        end else begin
            dir_y <= 1'b0;
            puls_y <= 1'b0;
            cnt_puls_y_neg <= 16'h0;
            cnt_puls_y_pos <= 16'h0;
        end
    end

    //------------------------------------------------------------------------
    // Z轴脉冲生成逻辑
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (flag_z_neg) begin
            if (f5) begin                // Z轴正限位触发，禁止运动
                dir_z <= 1'b0;
                puls_z <= 1'b0;
            end else begin
                if (cnt_puls_z_neg == 16'h3d09) begin
                    dir_z <= 1'b0;
                    puls_z <= ~puls_z;
                    cnt_puls_z_neg <= 16'h0;
                end else begin
                    dir_z <= 1'b0;
                    puls_z <= puls_z;
                    cnt_puls_z_neg <= cnt_puls_z_neg + 16'h1;
                end
            end
        end else if (flag_z_pos) begin
            if (f6) begin                // Z轴负限位触发，禁止运动
                dir_z <= 1'b0;
                puls_z <= 1'b0;
            end else begin
                if (cnt_puls_z_pos == 16'h3d09) begin
                    dir_z <= 1'b1;
                    puls_z <= ~puls_z;
                    cnt_puls_z_pos <= 16'h0;
                end else begin
                    dir_z <= 1'b1;
                    puls_z <= puls_z;
                    cnt_puls_z_pos <= cnt_puls_z_pos + 16'h1;
                end
            end
        end else begin
            dir_z <= 1'b0;
            puls_z <= 1'b0;
            cnt_puls_z_neg <= 16'h0;
            cnt_puls_z_pos <= 16'h0;
        end
    end

    //------------------------------------------------------------------------
    // A轴脉冲生成逻辑
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (flag_a_neg) begin
            if (f5) begin                // A轴正限位触发，禁止运动
                dir_a <= 1'b0;
                puls_a <= 1'b0;
            end else begin
                if (cnt_puls_a_neg == 16'h3d09) begin
                    dir_a <= 1'b0;
                    puls_a <= ~puls_a;
                    cnt_puls_a_neg <= 16'h0;
                end else begin
                    dir_a <= 1'b0;
                    puls_a <= puls_a;
                    cnt_puls_a_neg <= cnt_puls_a_neg + 16'h1;
                end
            end
        end else if (flag_a_pos) begin
            if (f6) begin                // A轴负限位触发，禁止运动
                dir_a <= 1'b0;
                puls_a <= 1'b0;
            end else begin
                if (cnt_puls_a_pos == 16'h3d09) begin
                    dir_a <= 1'b1;
                    puls_a <= ~puls_a;
                    cnt_puls_a_pos <= 16'h0;
                end else begin
                    dir_a <= 1'b1;
                    puls_a <= puls_a;
                    cnt_puls_a_pos <= cnt_puls_a_pos + 16'h1;
                end
            end
        end else begin
            dir_a <= 1'b0;
            puls_a <= 1'b0;
            cnt_puls_a_neg <= 16'h0;
            cnt_puls_a_pos <= 16'h0;
        end
    end

endmodule