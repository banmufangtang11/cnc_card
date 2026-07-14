`timescale 1ns / 1ps

// 运动选择模块
// 根据valid信号选择DDA插补运动(1)或手动运动(0)

module sel_assign(
    input         valid,    // DDA有效信号
    input         empty,    // FIFO空标志
    input  [31:0] datain,   // FIFO输入数据
    output [31:0] dataout,  // DDA输入数据
    
    input         dir_x0,   // 手动模式X方向
    input         dir_x1,   // DDA模式X方向
    input         dir_y0,   // 手动模式Y方向
    input         dir_y1,   // DDA模式Y方向
    input         dir_z0,   // 手动模式Z方向
    input         dir_z1,   // DDA模式Z方向
    input         dir_a0,   // 手动模式A方向
    input         dir_a1,   // DDA模式A方向
    
    input         puls_x0,  // 手动模式X脉冲
    input         puls_x1,  // DDA模式X脉冲
    input         puls_y0,  // 手动模式Y脉冲
    input         puls_y1,  // DDA模式Y脉冲
    input         puls_z0,  // 手动模式Z脉冲
    input         puls_z1,  // DDA模式Z脉冲
    input         puls_a0,  // 手动模式A脉冲
    input         puls_a1,  // DDA模式A脉冲
    
    output        dir_x,    // 最终X方向
    output        dir_y,    // 最终Y方向
    output        dir_z,    // 最终Z方向
    output        dir_a,    // 最终A方向
    output        puls_x,   // 最终X脉冲
    output        puls_y,   // 最终Y脉冲
    output        puls_z,   // 最终Z脉冲
    output        puls_a    // 最终A脉冲
);

assign dataout = empty ? 32'h0 : datain;

assign dir_x = valid ? dir_x1 : dir_x0;
assign dir_y = valid ? dir_y1 : dir_y0;
assign dir_z = valid ? dir_z1 : dir_z0;
assign dir_a = valid ? dir_a1 : dir_a0;
assign puls_x = valid ? puls_x1 : puls_x0;
assign puls_y = valid ? puls_y1 : puls_y0;
assign puls_z = valid ? puls_z1 : puls_z0;
assign puls_a = valid ? puls_a1 : puls_a0;

endmodule