`timescale 1ns / 1ps

// 轴选择模块
// 根据轴选择信号(i_X/i_Y/i_Z/i_A)将手轮脉冲分配到对应的轴
// 支持4轴同时选择，但实际使用中通常只选择一个轴

module axis_sel(
    // 系统信号
    input         clk,          // 时钟信号
    input         rstn,         // 复位信号(低有效)
    
    // 轴选择输入
    input         i_X,          // X轴选择(低有效)
    input         i_Y,          // Y轴选择(低有效)
    input         i_Z,          // Z轴选择(低有效)
    input         i_A,          // A轴选择(低有效)
    
    // 手轮输入
    input         p,            // 手轮脉冲
    input         dir_in,       // 手轮方向
    
    // 轴输出
    output reg    dir_x,        // X轴方向
    output reg    dir_y,        // Y轴方向
    output reg    dir_z,        // Z轴方向
    output reg    dir_a,        // A轴方向
    output reg    puls_x,       // X轴脉冲
    output reg    puls_y,       // Y轴脉冲
    output reg    puls_z,       // Z轴脉冲
    output reg    puls_a        // A轴脉冲
);

    // 内部寄存器声明
    reg [6:0] count1, count2, count3, count4;  // 消抖计数器
    reg flag1, flag2, flag3, flag4;            // 轴选择标志(消抖后)

    //------------------------------------------------------------------------
    // X轴选择消抖
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rstn) begin
            flag1 <= 1'b0;
            count1 <= 7'h0;
        end else begin
            if (!i_X) begin
                if (count1 == 7'h7d) begin  // 消抖延时约1us(50MHz)
                    flag1 <= 1'b1;
                    count1 <= 7'h0;
                end else begin
                    flag1 <= flag1;
                    count1 <= count1 + 7'h1;
                end
            end else begin
                flag1 <= 1'b0;
                count1 <= 7'h0;
            end
        end
    end

    //------------------------------------------------------------------------
    // Y轴选择消抖
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rstn) begin
            flag2 <= 1'b0;
            count2 <= 7'h0;
        end else begin
            if (!i_Y) begin
                if (count2 == 7'h7d) begin
                    flag2 <= 1'b1;
                    count2 <= 7'h0;
                end else begin
                    flag2 <= flag2;
                    count2 <= count2 + 7'h1;
                end
            end else begin
                flag2 <= 1'b0;
                count2 <= 7'h0;
            end
        end
    end

    //------------------------------------------------------------------------
    // Z轴选择消抖
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rstn) begin
            flag3 <= 1'b0;
            count3 <= 7'h0;
        end else begin
            if (!i_Z) begin
                if (count3 == 7'h7d) begin
                    flag3 <= 1'b1;
                    count3 <= 7'h0;
                end else begin
                    flag3 <= flag3;
                    count3 <= count3 + 7'h1;
                end
            end else begin
                flag3 <= 1'b0;
                count3 <= 7'h0;
            end
        end
    end

    //------------------------------------------------------------------------
    // A轴选择消抖
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rstn) begin
            flag4 <= 1'b0;
            count4 <= 7'h0;
        end else begin
            if (!i_A) begin
                if (count4 == 7'h7d) begin
                    flag4 <= 1'b1;
                    count4 <= 7'h0;
                end else begin
                    flag4 <= flag4;
                    count4 <= count4 + 7'h1;
                end
            end else begin
                flag4 <= 1'b0;
                count4 <= 7'h0;
            end
        end
    end

    //------------------------------------------------------------------------
    // 轴脉冲和方向分配
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dir_x <= 1'b0; dir_y <= 1'b0; dir_z <= 1'b0; dir_a <= 1'b0;
            puls_x <= 1'b0; puls_y <= 1'b0; puls_z <= 1'b0; puls_a <= 1'b0;
        end else begin
            if (flag1) begin                     // X轴选中
                dir_x <= dir_in; dir_y <= 1'b0; dir_z <= 1'b0; dir_a <= 1'b0;
                puls_x <= p; puls_y <= 1'b0; puls_z <= 1'b0; puls_a <= 1'b0;
            end else if (flag2) begin            // Y轴选中
                dir_x <= 1'b0; dir_y <= dir_in; dir_z <= 1'b0; dir_a <= 1'b0;
                puls_x <= 1'b0; puls_y <= p; puls_z <= 1'b0; puls_a <= 1'b0;
            end else if (flag3) begin            // Z轴选中
                dir_x <= 1'b0; dir_y <= 1'b0; dir_z <= dir_in; dir_a <= 1'b0;
                puls_x <= 1'b0; puls_y <= 1'b0; puls_z <= p; puls_a <= 1'b0;
            end else if (flag4) begin            // A轴选中
                dir_x <= 1'b0; dir_y <= 1'b0; dir_z <= 1'b0; dir_a <= dir_in;
                puls_x <= 1'b0; puls_y <= 1'b0; puls_z <= 1'b0; puls_a <= p;
            end else begin                       // 无轴选中
                dir_x <= 1'b0; dir_y <= 1'b0; dir_z <= 1'b0; dir_a <= 1'b0;
                puls_x <= 1'b0; puls_y <= 1'b0; puls_z <= 1'b0; puls_a <= 1'b0;
            end
        end
    end

endmodule