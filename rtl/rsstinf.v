`timescale 1ns / 1ps

// 模块功能：Avalon-ST 接口到 FIFO 接口的数据宽度转换
// 将 64 位 Avalon-ST 格式的数据扩展为 96 位 FIFO 写入格式
// 包含 PCIe RX 数据的有效信号、字节使能、解码信息等控制信号的打包

module rsstinf (
    input clk,  // 时钟信号
    input rst,  // 复位信号（低有效）

    // Avalon-ST 接口输入信号（来自 PCIe Hard IP）
    input  [ 7:0] rx_st_bardec,  // 地址解码信号，标识接收到的 TLP 类型
    input  [ 7:0] rx_st_be,      // 字节使能信号，标识 64 位数据中哪些字节有效
    input  [63:0] rx_st_data,    // 64 位 RX 数据
    input         rx_st_eop,     // 包结束信号（End of Packet）
    input         rx_st_err,     // 错误信号
    input         rx_st_sop,     // 包开始信号（Start of Packet）
    input         rx_st_valid,   // 数据有效信号
    output        rx_st_mask,    // 流量控制掩码（未使用，固定为0）
    output        rx_st_ready,   // 接收就绪信号（FIFO 未满时有效）

    // FIFO 接口输出信号
    output [95:0] fifodq,     // 96 位 FIFO 写入数据
    output        fifowr,     // FIFO 写使能信号
    output        led,        // LED 指示信号（有数据接收时点亮）
    input         fifoalfull  // FIFO 半满信号（用于流量控制）
);

    // 内部寄存器声明
    reg [95:0] fifodqreg;  // 96 位 FIFO 数据寄存器
    reg        led_reg;  // LED 状态寄存器

    // 流量控制信号赋值
    assign rx_st_mask  = 1'b0;  // 不屏蔽任何通道
    assign rx_st_ready = ~fifoalfull;  // FIFO 未满时接收就绪

    // 主时序逻辑：数据打包和 LED 控制
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            fifodqreg <= 96'h000000000000000000000000;
            led_reg <= 1'b0;
        end else begin
            fifodqreg[63:0] <= rx_st_data[63:0];
            fifodqreg[71:64] <= rx_st_be;
            fifodqreg[79:72] <= rx_st_bardec;
            fifodqreg[80] <= rx_st_valid;
            fifodqreg[81] <= rx_st_err;
            fifodqreg[82] <= rx_st_sop;
            fifodqreg[83] <= rx_st_eop;
            fifodqreg[95:84] <= 12'h000;

            if (rx_st_valid == 1'b1) begin
                led_reg <= 1'b1;
            end
        end
    end

    // 输出赋值
    assign fifodq = fifodqreg;  // 96 位数据输出到 FIFO
    assign fifowr = rx_st_valid;  // 数据有效时写 FIFO
    assign led    = led_reg;  // LED 状态输出

endmodule
