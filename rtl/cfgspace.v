`timescale 1ns / 1ps

// 模块功能：PCIe 配置空间寄存器管理模块
// 负责管理 PCIe 设备的配置寄存器，包括设备状态寄存器、命令寄存器、总线/设备号寄存器
// 通过写信号的上升沿检测实现寄存器的写入，支持设备使能控制（内存空间、IO空间、DMA）

module cfgspace (
    input clk,  // 时钟信号
    input rst,  // 复位信号（低有效）

    // 写入接口（来自 rxproc 模块）
    input        wr,   // 写使能信号
    input [ 3:0] add,  // 4位寄存器地址
    input [31:0] data, // 32位写入数据

    // 状态信号输出
    output [3:0] err_rep_en,  // 错误报告使能（devcsr[19:16]）
    output [2:0] maxp_size,   // 最大负载大小（devcsr[23:21]）
    output [2:0] maxrq_size,  // 最大请求大小（devcsr[30:28]）

    // 使能信号输出
    output memen,  // 内存空间使能（prmcsr[9]）
    output ioen,   // IO 空间使能（prmcsr[8]）
    output dmaen,  // DMA 使能（prmcsr[10]）

    // 总线/设备号输出
    output [7:0] busnum,  // 总线号（busdev[12:5]）
    output [4:0] devnum   // 设备号（busdev[4:0]）
);

    // 内部寄存器声明
    reg [31:0] devcsr;  // 设备控制/状态寄存器（Device CSR）
    reg [31:0] prmcsr;  // 主控制/状态寄存器（Primary CSR）
    reg [31:0] busdev;  // 总线/设备号寄存器
    reg        wr1;  // 写信号延迟1拍
    reg        wr2;  // 写信号延迟2拍
    reg        wr3;  // 写信号延迟3拍

    // 写信号延迟线：用于检测写信号的上升沿
    // wr3 != wr2 表示 wr 信号在当前时钟周期有变化
    always @(posedge clk) begin
        wr1 <= wr;
        wr2 <= wr1;
        wr3 <= wr2;
    end

    // 设备控制/状态寄存器（devcsr）写入逻辑
    // 地址 0x0：设备状态和配置信息
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            devcsr <= 32'h00000000;
        end else begin
            if (wr3 != wr2) begin  // 检测到写信号变化
                if (add == 4'h0) begin  // 地址为 0x0
                    devcsr <= data;  // 更新设备控制/状态寄存器
                end
            end
        end
    end

    // 设备控制/状态寄存器字段提取
    assign err_rep_en = devcsr[19:16];  // 错误报告使能位
    assign maxp_size  = devcsr[23:21];  // 最大负载大小（以DW为单位）
    assign maxrq_size = devcsr[30:28];  // 最大请求大小（以DW为单位）

    // 主控制/状态寄存器（prmcsr）写入逻辑
    // 地址 0x3：命令寄存器（使能控制）
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            prmcsr <= 32'h00000000;
        end else begin
            if (wr3 != wr2) begin  // 检测到写信号变化
                if (add == 4'h3) begin  // 地址为 0x3
                    prmcsr <= data;  // 更新主控制/状态寄存器
                end
            end
        end
    end

    // 命令寄存器字段提取（使能信号）
    assign ioen  = prmcsr[8];  // IO 空间使能
    assign memen = prmcsr[9];  // 内存空间使能
    assign dmaen = prmcsr[10];  // DMA 功能使能

    // 总线/设备号寄存器（busdev）写入逻辑
    // 地址 0xF：总线号和设备号
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            busdev <= 32'h00000000;
        end else begin
            if (wr3 != wr2) begin  // 检测到写信号变化
                if (add == 4'hF) begin  // 地址为 0xF
                    busdev <= data;  // 更新总线/设备号寄存器
                end
            end
        end
    end

    // 总线/设备号字段提取
    assign busnum = busdev[12:5];  // 总线号（8位）
    assign devnum = busdev[4:0];  // 设备号（5位）

endmodule
