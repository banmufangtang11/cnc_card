`timescale 1ns / 1ps

// 回零选择模块
// 根据szero信号选择回零运动或JOG运动

module zero_sel(
    input         clk,              // 时钟信号
    input         szero,            // 回零触发信号
    
    input         dir_x_zero,       // 回零X方向
    input         dir_y_zero,       // 回零Y方向
    input         dir_z_zero,       // 回零Z方向
    input         puls_x_zero,      // 回零X脉冲
    input         puls_y_zero,      // 回零Y脉冲
    input         puls_z_zero,      // 回零Z脉冲
    
    input         dir_x_jog,        // JOG X方向
    input         dir_y_jog,        // JOG Y方向
    input         dir_z_jog,        // JOG Z方向
    input         puls_x_jog,       // JOG X脉冲
    input         puls_y_jog,       // JOG Y脉冲
    input         puls_z_jog,       // JOG Z脉冲
    
    output        dir_x,            // 最终X方向
    output        dir_y,            // 最终Y方向
    output        dir_z,            // 最终Z方向
    output        puls_x,           // 最终X脉冲
    output        puls_y,           // 最终Y脉冲
    output        puls_z            // 最终Z脉冲
);

reg [6:0] count;
reg       flag;

always @(posedge clk) begin
    if (szero) begin
        if (count == 7'h7d) begin
            flag <= 1'b1;
            count <= 7'h0;
        end else begin
            count <= count + 7'h1;
        end
    end else begin
        flag <= 1'b0;
        count <= 7'h0;
    end
end

assign dir_x = flag ? dir_x_zero : dir_x_jog;
assign dir_y = flag ? dir_y_zero : dir_y_jog;
assign dir_z = flag ? dir_z_zero : dir_z_jog;
assign puls_x = flag ? puls_x_zero : puls_x_jog;
assign puls_y = flag ? puls_y_zero : puls_y_jog;
assign puls_z = flag ? puls_z_zero : puls_z_jog;

endmodule