`timescale 1ns / 1ps

// PC到卡脉冲计数模块
// 对脉冲信号进行上升沿检测并计数
// 支持清零操作(renew信号)

module pctocard_count(
    // 系统信号
    input         clk,           // 时钟信号
    input         rst_n,         // 复位信号(低有效)
    
    // 输入信号
    input         plus,          // 脉冲输入信号
    input         dir,           // 方向信号(未使用)
    input         renew,         // 清零信号
    
    // 计数输出
    output reg [31:0] card_count  // 卡端计数
);

    // 内部寄存器声明
    reg plus_tt;                 // 脉冲延时两拍
    reg plus_t;                  // 脉冲延时一拍
    wire plus_flag;              // 脉冲上升沿标志
    
    // 脉冲上升沿检测
    assign plus_flag = (!plus_tt & plus_t);

    //------------------------------------------------------------------------
    // 脉冲信号延时寄存器(用于上升沿检测)
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            plus_tt <= 1'b0;
            plus_t  <= 1'b0;
        end else begin
            plus_t  <= plus;
            plus_tt <= plus_t;
        end
    end

    //------------------------------------------------------------------------
    // 卡端脉冲计数
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            card_count <= 'd0;
        end else if (renew == 1'b1) begin
            card_count <= 'd0;
        end else if (plus_flag == 1'b1) begin
            card_count <= card_count + 1'b1;
        end else begin
            card_count <= card_count;
        end
    end

endmodule