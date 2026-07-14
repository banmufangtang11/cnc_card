`timescale 1ns / 1ps

// JOG/手轮运动选择模块
// 根据hw_valid信号选择手轮运动(有效)或JOG手动运动(无效)
// 包含消抖延时，避免切换时的抖动干扰

module jog_sel(
    input         clk,              // 时钟信号
    input         hw_valid,         // 手轮有效信号(1=手轮模式, 0=JOG模式)
    
    // 手轮运动输入
    input         dir_x_hw,         // 手轮X方向
    input         dir_y_hw,         // 手轮Y方向
    input         dir_z_hw,         // 手轮Z方向
    input         dir_a_hw,         // 手轮A方向
    input         puls_x_hw,        // 手轮X脉冲
    input         puls_y_hw,        // 手轮Y脉冲
    input         puls_z_hw,        // 手轮Z脉冲
    input         puls_a_hw,        // 手轮A脉冲
    
    // JOG运动输入
    input         dir_x_jog,        // JOG X方向
    input         dir_y_jog,        // JOG Y方向
    input         dir_z_jog,        // JOG Z方向
    input         dir_a_jog,        // JOG A方向
    input         puls_x_jog,       // JOG X脉冲
    input         puls_y_jog,       // JOG Y脉冲
    input         puls_z_jog,       // JOG Z脉冲
    input         puls_a_jog,       // JOG A脉冲
    
    // 最终运动输出
    output        dir_x,            // X方向输出
    output        dir_y,            // Y方向输出
    output        dir_z,            // Z方向输出
    output        dir_a,            // A方向输出
    output        puls_x,           // X脉冲输出
    output        puls_y,           // Y脉冲输出
    output        puls_z,           // Z脉冲输出
    output        puls_a            // A脉冲输出
);

    reg [6:0] cnt;                   // 消抖计数器
    reg       flag;                  // 手轮有效标志(消抖后)

    // 消抖逻辑：当hw_valid无效时，延时1us后切换到JOG模式
    always @(posedge clk) begin
        if (!hw_valid) begin
            if (cnt == 7'h7d) begin  // 延时约1us(125MHz)
                flag <= 1'b1;
                cnt <= 7'h0;
            end else begin
                flag <= flag;
                cnt <= cnt + 7'h1;
            end
        end else begin
            flag <= 1'b0;
            cnt <= 7'h0;
        end
    end

    // 根据flag选择运动源：flag=1选JOG，flag=0选手轮
    assign dir_x  = (flag) ? dir_x_jog  : dir_x_hw;
    assign dir_y  = (flag) ? dir_y_jog  : dir_y_hw;
    assign dir_z  = (flag) ? dir_z_jog  : dir_z_hw;
    assign dir_a  = (flag) ? dir_a_jog  : dir_a_hw;
    assign puls_x = (flag) ? puls_x_jog : puls_x_hw;
    assign puls_y = (flag) ? puls_y_jog : puls_y_hw;
    assign puls_z = (flag) ? puls_z_jog : puls_z_hw;
    assign puls_a = (flag) ? puls_a_jog : puls_a_hw;

endmodule