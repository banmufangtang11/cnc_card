`timescale 1ns / 1ps

// 模块功能：PCIe TX 数据包处理模块
// 负责生成 PCIe TX TLP 数据包，包括：内存读完成（CPLD）、DMA写、DMA读
// 管理中断请求和响应，控制 CNC 运动控制相关的寄存器（位置、速度、IO等）
// 支持 PCIe 流量控制信用检查和 4KB 边界交叉处理

module txproc (
    input clk,  // 时钟信号
    input rst,  // 复位信号（低有效）

    // TX FIFO 接口（连接到 PCIe Hard IP）
    output reg [71:0] txfifodq,  // 72位 TX FIFO 数据（包含 TLP 头部和数据）

    // 内存读请求接口（来自 rxproc 模块）
    input      memrdreq,    // 内存读请求
    input      memrddxfer,  // 内存读传输完成
    output reg memrdack,    // 内存读确认

    // TLP 头部字段（来自 rxproc/cfgspace 模块）
    input [ 7:0] tag,     // TLP 标签
    input [ 7:0] busnum,  // 总线号
    input [15:0] reqid,   // 请求者 ID
    input [ 2:0] tc,      // 流量类别
    input [ 1:0] attrib,  // 属性字段
    input [ 4:0] devnum,  // 设备号

    // PCIe 流量控制接口（来自 PCIe Hard IP）
    input [35:0] tx_cred,     // TX 信用（36位，包含各类 TLP 的信用值）
    input        tx_st_ready, // TX 就绪信号

    // 外部接口（连接到运动控制模块）
    input        memsel1,  // 内存片选1
    input        data_rd,  // 数据读信号
    input        data_wr,  // 数据写信号
    input [21:0] ext_add,  // 外部地址
    inout [31:0] extdq,    // 32位外部数据总线

    // DMA 读 FIFO 接口（来自 rxproc 模块）
    input             fifordempty,  // DMA 读 FIFO 空标志
    input             app_int_ack,  // 中断确认
    input             rxfifowr,     // RX FIFO 写使能
    input      [ 8:0] fiforddw,     // DMA 读 FIFO 深度
    input      [63:0] fifodqin,     // DMA 读 FIFO 数据
    output reg        fiford,       // DMA 读 FIFO 读使能
    output reg        clrfifo,      // FIFO 清空信号

    // 使能和状态信号
    output reg dmaen,        // DMA 使能
    output reg app_int_sts,  // 中断状态（发送到 PCIe Hard IP）
    output reg tx_st_err,    // TX 错误标志
    output reg tx_st_valid,  // TX 数据有效

    // LED 指示信号
    output reg led1,  // LED1
    output reg led2,  // LED2
    output reg led3,  // LED3
    output reg led4,  // LED4

    // 外部中断请求
    input ext_int_req,  // 外部中断请求（来自运动控制模块）
    input iosel,        // IO 空间选择

    // 写请求信号
    output reg wrreq,  // 写请求

    // 参考位置设置
    input set_ref,  // 设置参考位置信号

    // 轴位置输入（来自运动控制模块）
    input [31:0] posx,  // X轴位置
    input [31:0] posy,  // Y轴位置
    input [31:0] posz,  // Z轴位置
    input [31:0] posa,  // A轴位置

    // 卡位置输入（来自运动控制模块）
    input [31:0] card_posx,  // X轴卡位置
    input [31:0] card_posy,  // Y轴卡位置
    input [31:0] card_posz,  // Z轴卡位置
    input [31:0] card_posa,  // A轴卡位置

    // 增量位置输入
    input [31:0] delta_x,  // X轴增量
    input [31:0] delta_y,  // Y轴增量
    input [31:0] delta_z,  // Z轴增量
    input [31:0] delta_a,  // A轴增量

    // 数字输入信号
    input s1,  // 数字输入1
    input s2,  // 数字输入2
    input s3,  // 数字输入3
    input s4,  // 数字输入4
    input s5,  // 数字输入5
    input s6,  // 数字输入6

    // 参考位置输出
    output [31:0] posx_ref,  // X轴参考位置
    output [31:0] posy_ref,  // Y轴参考位置
    output [31:0] posz_ref,  // Z轴参考位置
    output [31:0] posa_ref,  // A轴参考位置

    // 卡参考位置输出
    output [31:0] card_posx_ref,  // X轴卡参考位置
    output [31:0] card_posy_ref,  // Y轴卡参考位置
    output [31:0] card_posz_ref,  // Z轴卡参考位置
    output [31:0] card_posa_ref,  // A轴卡参考位置

    // 数字输出信号
    output reg co1,  // 数字输出1
    output reg co2,  // 数字输出2
    output reg co3,  // 数字输出3
    output reg co4,  // 数字输出4
    output reg co5,  // 数字输出5
    output reg co6,  // 数字输出6
    output reg co7,  // 数字输出7
    output reg co8,  // 数字输出8

    // 轴使能信号
    output reg xen,  // X轴使能
    output reg yen,  // Y轴使能
    output reg zen,  // Z轴使能
    output reg aen,  // A轴使能

    // JOG 控制信号
    output reg jog_posx,   // X轴正向 JOG
    output reg jog_posy,   // Y轴正向 JOG
    output reg jog_posz,   // Z轴正向 JOG
    output reg jog_posa,   // A轴正向 JOG
    output reg jog_negx,   // X轴负向 JOG
    output reg jog_negy,   // Y轴负向 JOG
    output reg jog_negz,   // Z轴负向 JOG
    output reg jog_nega,   // A轴负向 JOG
    output reg szero_soft, // 软件归零

    // 主轴控制信号
    output reg m_cool,  // 冷却液控制
    output reg m_cw,    // 主轴顺时针旋转
    output reg m_atcw,  // 主轴逆时针旋转

    // 辅助控制信号
    output reg [31:0] aux_ctl,  // 辅助控制输出
    input      [31:0] aux_back  // 辅助反馈输入
);

    // 主状态机状态定义（TX 数据包处理状态）
    localparam IDLE = 0;  // 空闲状态
    localparam MEMRDCPLDHEAD1 = 1;  // 内存读CPLD头部生成1
    localparam MEMRDCPLDHEAD2 = 2;  // 内存读CPLD头部生成2
    localparam MEMRDCPLDWAITST1 = 3;  // 内存读CPLD等待状态1
    localparam MEMRDCPLDWAITST2 = 4;  // 内存读CPLD等待状态2
    localparam MEMRDCPLDDATAST1 = 5;  // 内存读CPLD数据状态1
    localparam MEMRDCPLDDONE = 6;  // 内存读CPLD完成
    localparam MEMRDCPLDWAITST3 = 7;  // 内存读CPLD等待状态3
    localparam MEMRDCPLDWAITST4 = 8;  // 内存读CPLD等待状态4
    localparam MEMRDCPLDWAITST5 = 9;  // 内存读CPLD等待状态5
    localparam MEMRDCPLDWAITST6 = 10;  // 内存读CPLD等待状态6
    localparam MEMRDCPLDWAITST7 = 11;  // 内存读CPLD等待状态7
    localparam DMAWRWAITST1 = 12;  // DMA写等待状态1
    localparam DMAWRHEAD1 = 13;  // DMA写头部生成1
    localparam DMAWRHEAD2 = 14;  // DMA写头部生成2
    localparam DMAWRDATAST1 = 15;  // DMA写数据状态1
    localparam DMAWRDATAST2 = 16;  // DMA写数据状态2
    localparam DMAWRWAITST3 = 17;  // DMA写等待状态3
    localparam DMAWRWAITST4 = 18;  // DMA写等待状态4
    localparam DMAWRWAITST5 = 19;  // DMA写等待状态5
    localparam DMAWRWAITST6 = 20;  // DMA写等待状态6
    localparam DMAWRWAITST7 = 21;  // DMA写等待状态7
    localparam DMAWRWAITST8 = 22;  // DMA写等待状态8
    localparam DMARDWAITST1 = 23;  // DMA读等待状态1
    localparam DMARDWAITST2 = 24;  // DMA读等待状态2
    localparam DMARDHEAD1 = 25;  // DMA读头部生成1
    localparam DMARDHEAD2 = 26;  // DMA读头部生成2
    localparam DMARDWAITST3 = 27;  // DMA读等待状态3
    localparam DMARDWAITST4 = 28;  // DMA读等待状态4
    localparam DMARDWAITST5 = 29;  // DMA读等待状态5
    localparam DMARDWAITST6 = 30;  // DMA读等待状态6

    // 主状态机寄存器
    reg [5:0] pre_state;  // 当前状态
    reg [5:0] nxt_state;  // 下一状态

    // 中断状态机状态定义
    localparam INT_IDLE = 0;  // 中断空闲状态
    localparam INT_EN = 1;  // 中断使能状态
    localparam INT_ACK1 = 2;  // 中断确认状态1
    localparam INT_DISABLE = 3;  // 中断禁用状态
    localparam INT_ACK2 = 4;  // 中断确认状态2

    // 中断状态机寄存器
    reg [ 2:0] pre_state1;  // 中断当前状态
    reg [ 2:0] nxt_state1;  // 中断下一状态

    // TX 控制信号
    reg        txen;  // TX 使能

    // TLP 头部和数据寄存器
    reg [63:0] memrdcpheadrega;  // 内存读CPLD头部寄存器A
    reg [63:0] memrdcpheadregb;  // 内存读CPLD头部寄存器B
    reg [63:0] memrdcpdatareg;  // 内存读CPLD数据寄存器
    reg [63:0] dmawrheadrega;  // DMA写头部寄存器A
    reg [63:0] dmawrheadregb;  // DMA写头部寄存器B
    reg [63:0] dmardheadrega;  // DMA读头部寄存器A
    reg [63:0] dmardheadregb;  // DMA读头部寄存器B

    // TLP 类型使能信号
    reg        postheaden;  // Posted TLP 头部使能
    reg        postdataen;  // Posted TLP 数据使能
    reg        npheaden;  // Non-Posted TLP 头部使能
    reg        npdataen;  // Non-Posted TLP 数据使能
    reg        cpheaden;  // Completion TLP 头部使能
    reg        cpdataen;  // Completion TLP 数据使能

    // 寄存器选择信号
    reg        intregsel;  // 中断寄存器选择
    reg        headregsel;  // 头部寄存器选择
    reg        countregsel;  // 计数寄存器选择
    reg        cmdregsel;  // 命令寄存器选择
    reg        clrcmd;  // 清除命令
    reg        startdmawr;  // 启动DMA写
    reg        countale;  // 计数使能
    reg        clrct;  // 清除计数
    reg        dmarden;  // DMA读使能
    reg        clrcmd1;  // 清除命令1

    // PC到卡寄存器
    reg        pctocardregsel;  // PC到卡寄存器选择
    reg [31:0] pctocardreg;  // PC到卡数据寄存器

    // DCS寄存器（运动控制相关）
    reg        dcsregsel;  // DCS寄存器选择
    reg [31:0] dcsreg;  // DCS寄存器

    // MCM寄存器（运动控制模式）
    reg        mcmregsel;  // MCM寄存器选择
    reg [31:0] mcmreg;  // MCM寄存器

    // 数字输出寄存器
    reg co1regsel, co2regsel, co3regsel, co4regsel;
    reg co5regsel, co6regsel, co7regsel, co8regsel;
    reg [31:0] co1reg, co2reg, co3reg, co4reg;
    reg [31:0] co5reg, co6reg, co7reg, co8reg;

    // 轴位置寄存器
    reg posx_regsel, posy_regsel, posz_regsel, posa_regsel;
    reg [31:0] posx_reg, posy_reg, posz_reg, posa_reg;

    // 轴参考位置寄存器
    reg posx_ref_regsel, posy_ref_regsel, posz_ref_regsel, posa_ref_regsel;
    reg [31:0] posx_ref_reg, posy_ref_reg, posz_ref_reg, posa_ref_reg;

    // 轴实际位置寄存器
    reg posx_real_regsel, posy_real_regsel, posz_real_regsel, posa_real_regsel;
    reg [31:0] posx_real_reg, posy_real_reg, posz_real_reg, posa_real_reg;

    // 轴断点位置寄存器
    reg posx_break_regsel, posy_break_regsel, posz_break_regsel, posa_break_regsel;
    reg [31:0] posx_break_reg, posy_break_reg, posz_break_reg, posa_break_reg;

    // 卡位置寄存器
    reg card_posx_regsel, card_posy_regsel, card_posz_regsel, card_posa_regsel;
    reg [31:0] card_posx_reg, card_posy_reg, card_posz_reg, card_posa_reg;

    // 卡参考位置寄存器
    reg card_posx_ref_regsel, card_posy_ref_regsel, card_posz_ref_regsel, card_posa_ref_regsel;
    reg [31:0] card_posx_ref_reg, card_posy_ref_reg, card_posz_ref_reg, card_posa_ref_reg;

    // 卡实际位置寄存器
    reg card_posx_real_regsel, card_posy_real_regsel, card_posz_real_regsel, card_posa_real_regsel;
    reg [31:0] card_posx_real_reg, card_posy_real_reg, card_posz_real_reg, card_posa_real_reg;

    // 轴速度寄存器
    reg spdx_regsel, spdy_regsel, spdz_regsel, spda_regsel;
    reg [31:0] spdx_reg, spdy_reg, spdz_reg, spda_reg;

    // 软件归零寄存器
    reg        szero_softregsel;  // 软件归零寄存器选择
    reg [31:0] szero_softreg;  // 软件归零寄存器

    // JOG正向控制寄存器
    reg jog_posx_regsel, jog_posy_regsel, jog_posz_regsel, jog_posa_regsel;
    reg [31:0] jog_posx_reg, jog_posy_reg, jog_posz_reg, jog_posa_reg;

    // JOG负向控制寄存器
    reg jog_negx_regsel, jog_negy_regsel, jog_negz_regsel, jog_nega_regsel;
    reg [31:0] jog_negx_reg, jog_negy_reg, jog_negz_reg, jog_nega_reg;

    // 主轴控制寄存器
    reg m_cool_regsel, m_cw_regsel, m_atcw_regsel;
    reg [31:0] m_cool_reg, m_cw_reg, m_atcw_reg;

    // 辅助控制寄存器
    reg aux_ctl_regsel, aux_back_regsel;
    reg [31:0] aux_ctl_reg, aux_back_reg;

    // 通用寄存器
    reg [31:0] intreg;  // 中断寄存器
    reg [31:0] headreg;  // 头部寄存器
    reg [31:0] countreg;  // 计数寄存器
    reg [31:0] cmdreg;  // 命令寄存器
    reg [31:0] rdcountreg;  // 读计数寄存器

    // 4KB边界相关寄存器
    reg [12:0] boundry4k;  // 4KB边界地址
    reg [12:0] headreglow4k;  // 头部低13位（4KB内偏移）
    reg [12:0] canntcross4k;  // 不可跨越4KB边界的长度
    reg [12:0] extpayload;  // 扩展负载长度

    // 长度相关寄存器
    reg [ 8:0] cross4klength;  // 跨越4KB边界的长度
    reg [ 8:0] fifodwlength;  // FIFO双字长度
    reg [ 8:0] ctlength;  // 计数长度
    reg [ 8:0] bytelength;  // 字节长度
    reg [ 8:0] pctreg;  // PCT寄存器
    reg [ 8:0] maxpayload;  // 最大负载长度

    // 标签寄存器
    reg [ 7:0] dmawrtag;  // DMA写标签
    reg [ 7:0] dmardtag;  // DMA读标签
    reg [ 7:0] rxfifowrct;  // RX FIFO写计数

    // 扩展标签寄存器
    reg [11:0] dmardcpldtag;  // DMA读CPLD标签

    // 控制标志
    reg        wr_flag;  // 写标志
    reg [ 1:0] cnt;  // 计数器



    always @(*) begin
        case (pre_state1)
            INT_IDLE: begin
                if (intreg[0] == 1'b1 && intreg[1] == 1'b1) begin
                    nxt_state1 = INT_EN;
                end else begin
                    nxt_state1 = INT_IDLE;
                end
            end
            INT_EN: begin
                if (app_int_ack == 1'b1) begin
                    nxt_state1 = INT_ACK1;
                end else begin
                    nxt_state1 = INT_EN;
                end
            end
            INT_ACK1: begin
                if (intreg[0] == 1'b0) begin
                    nxt_state1 = INT_DISABLE;
                end else begin
                    nxt_state1 = INT_ACK1;
                end
            end
            INT_DISABLE: begin
                if (app_int_ack == 1'b1) begin
                    nxt_state1 = INT_ACK2;
                end else begin
                    nxt_state1 = INT_DISABLE;
                end
            end
            INT_ACK2: begin
                nxt_state1 = INT_IDLE;
            end
            default: begin
                nxt_state1 = INT_IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if (pre_state1 == INT_EN || pre_state1 == INT_ACK1) begin
            app_int_sts <= 1'b1;
        end else begin
            app_int_sts <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            pre_state1 <= INT_IDLE;
        end else begin
            pre_state1 <= nxt_state1;
        end
    end

    always @(posedge clk) begin
        if (memsel1 == 1'b1 && ext_add == 22'h000004) begin
            intregsel <= 1'b1;
        end else begin
            intregsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000008) begin
            headregsel <= 1'b1;
        end else begin
            headregsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h00000C) begin
            countregsel <= 1'b1;
        end else begin
            countregsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000010) begin
            cmdregsel <= 1'b1;
        end else begin
            cmdregsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000014) begin
            pctocardregsel <= 1'b1;
        end else begin
            pctocardregsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000020) begin
            posx_regsel <= 1'b1;
        end else begin
            posx_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000024) begin
            posy_regsel <= 1'b1;
        end else begin
            posy_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000028) begin
            posz_regsel <= 1'b1;
        end else begin
            posz_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h00002C) begin
            posa_regsel <= 1'b1;
        end else begin
            posa_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h0000A8) begin
            aux_back_regsel <= 1'b1;
        end else begin
            aux_back_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h0000AC) begin
            aux_ctl_regsel <= 1'b1;
        end else begin
            aux_ctl_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h0000C0) begin
            card_posx_regsel <= 1'b1;
        end else begin
            card_posx_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h0000C4) begin
            card_posy_regsel <= 1'b1;
        end else begin
            card_posy_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h0000C8) begin
            card_posz_regsel <= 1'b1;
        end else begin
            card_posz_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h0000CC) begin
            card_posa_regsel <= 1'b1;
        end else begin
            card_posa_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000030) begin
            posx_ref_regsel <= 1'b1;
        end else begin
            posx_ref_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000034) begin
            posy_ref_regsel <= 1'b1;
        end else begin
            posy_ref_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000038) begin
            posz_ref_regsel <= 1'b1;
        end else begin
            posz_ref_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h00003C) begin
            posa_ref_regsel <= 1'b1;
        end else begin
            posa_ref_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h0000E0) begin
            card_posx_ref_regsel <= 1'b1;
        end else begin
            card_posx_ref_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h0000E4) begin
            card_posy_ref_regsel <= 1'b1;
        end else begin
            card_posy_ref_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h0000E8) begin
            card_posz_ref_regsel <= 1'b1;
        end else begin
            card_posz_ref_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h0000EC) begin
            card_posa_ref_regsel <= 1'b1;
        end else begin
            card_posa_ref_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000040) begin
            posx_real_regsel <= 1'b1;
        end else begin
            posx_real_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000044) begin
            posy_real_regsel <= 1'b1;
        end else begin
            posy_real_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000048) begin
            posz_real_regsel <= 1'b1;
        end else begin
            posz_real_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h00004C) begin
            posa_real_regsel <= 1'b1;
        end else begin
            posa_real_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000100) begin
            card_posx_real_regsel <= 1'b1;
        end else begin
            card_posx_real_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000104) begin
            card_posy_real_regsel <= 1'b1;
        end else begin
            card_posy_real_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000108) begin
            card_posz_real_regsel <= 1'b1;
        end else begin
            card_posz_real_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h00010C) begin
            card_posa_real_regsel <= 1'b1;
        end else begin
            card_posa_real_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000050) begin
            posx_break_regsel <= 1'b1;
        end else begin
            posx_break_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000054) begin
            posy_break_regsel <= 1'b1;
        end else begin
            posy_break_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000058) begin
            posz_break_regsel <= 1'b1;
        end else begin
            posz_break_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h00005C) begin
            posa_break_regsel <= 1'b1;
        end else begin
            posa_break_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h0000D0) begin
            spdx_regsel <= 1'b1;
        end else begin
            spdx_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h0000D4) begin
            spdy_regsel <= 1'b1;
        end else begin
            spdy_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h0000D8) begin
            spdz_regsel <= 1'b1;
        end else begin
            spdz_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h0000DC) begin
            spda_regsel <= 1'b1;
        end else begin
            spda_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000018) begin
            dcsregsel <= 1'b1;
        end else begin
            dcsregsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h00001C) begin
            mcmregsel <= 1'b1;
        end else begin
            mcmregsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000060) begin
            co1regsel <= 1'b1;
        end else begin
            co1regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000064) begin
            co2regsel <= 1'b1;
        end else begin
            co2regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000068) begin
            co3regsel <= 1'b1;
        end else begin
            co3regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h00006C) begin
            co4regsel <= 1'b1;
        end else begin
            co4regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000070) begin
            co5regsel <= 1'b1;
        end else begin
            co5regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000074) begin
            co6regsel <= 1'b1;
        end else begin
            co6regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000078) begin
            co7regsel <= 1'b1;
        end else begin
            co7regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h00007C) begin
            co8regsel <= 1'b1;
        end else begin
            co8regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000080) begin
            jog_posx_regsel <= 1'b1;
        end else begin
            jog_posx_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000084) begin
            jog_posy_regsel <= 1'b1;
        end else begin
            jog_posy_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000088) begin
            jog_posz_regsel <= 1'b1;
        end else begin
            jog_posz_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h00008C) begin
            jog_posa_regsel <= 1'b1;
        end else begin
            jog_posa_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000090) begin
            jog_negx_regsel <= 1'b1;
        end else begin
            jog_negx_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000094) begin
            jog_negy_regsel <= 1'b1;
        end else begin
            jog_negy_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000098) begin
            jog_negz_regsel <= 1'b1;
        end else begin
            jog_negz_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h00009C) begin
            jog_nega_regsel <= 1'b1;
        end else begin
            jog_nega_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h0000A0) begin
            szero_softregsel <= 1'b1;
        end else begin
            szero_softregsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000110) begin
            m_cool_regsel <= 1'b1;
        end else begin
            m_cool_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000114) begin
            m_cw_regsel <= 1'b1;
        end else begin
            m_cw_regsel <= 1'b0;
        end

        if (memsel1 == 1'b1 && ext_add == 22'h000118) begin
            m_atcw_regsel <= 1'b1;
        end else begin
            m_atcw_regsel <= 1'b0;
        end
    end

    always @(posedge clk) begin
        posx_real_reg <= posx_reg - posx_ref_reg;
        posy_real_reg <= posy_reg - posy_ref_reg;
        posz_real_reg <= posz_reg - posz_ref_reg;
        posa_real_reg <= posa_reg - posa_ref_reg;

        aux_ctl <= aux_ctl_reg;
        aux_back_reg <= aux_back;
    end

    always @(posedge clk) begin
        card_posx_real_reg <= card_posx_reg - card_posx_ref_reg;
        card_posy_real_reg <= card_posy_reg - card_posy_ref_reg;
        card_posz_real_reg <= card_posz_reg - card_posz_ref_reg;
        card_posa_real_reg <= card_posa_reg - card_posa_ref_reg;
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            intreg <= 32'h00000002;
        end else if (data_wr == 1'b1 && intregsel == 1'b1) begin
            intreg <= extdq;
        end else begin
            intreg[0] <= ext_int_req;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            pctocardreg <= 32'h00000000;
            wr_flag <= 1'b0;
        end else begin
            if (data_wr == 1'b1 && pctocardregsel == 1'b1) begin
                pctocardreg <= extdq;
                wr_flag <= 1'b1;
            end else begin
                wr_flag <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            wrreq <= 1'b0;
            cnt   <= 2'b00;
        end else begin
            if (wr_flag == 1'b1 && cnt == 2'b00) begin
                wrreq <= 1'b1;
                cnt   <= cnt + 1;
            end else if (cnt == 2'b01) begin
                wrreq <= 1'b0;
                cnt   <= 2'b00;
            end else begin
                wrreq <= 1'b0;
                cnt   <= 2'b00;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            aux_ctl_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && aux_ctl_regsel == 1'b1) begin
                aux_ctl_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            aux_back_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && aux_back_regsel == 1'b1) begin
                aux_back_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            posx_reg <= 32'h00000000;
        end else if (data_wr == 1'b1 && posx_regsel == 1'b1) begin
            posx_reg <= extdq;
        end else begin
            posx_reg <= posx;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            posy_reg <= 32'h00000000;
        end else if (data_wr == 1'b1 && posy_regsel == 1'b1) begin
            posy_reg <= extdq;
        end else begin
            posy_reg <= posy;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            posz_reg <= 32'h00000000;
        end else if (data_wr == 1'b1 && posz_regsel == 1'b1) begin
            posz_reg <= extdq;
        end else begin
            posz_reg <= posz;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            posa_reg <= 32'h00000000;
        end else if (data_wr == 1'b1 && posa_regsel == 1'b1) begin
            posa_reg <= extdq;
        end else begin
            posa_reg <= posa;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            card_posx_reg <= 32'h00000000;
        end else if (data_wr == 1'b1 && card_posx_regsel == 1'b1) begin
            card_posx_reg <= extdq;
        end else begin
            card_posx_reg <= card_posx;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            card_posy_reg <= 32'h00000000;
        end else if (data_wr == 1'b1 && card_posy_regsel == 1'b1) begin
            card_posy_reg <= extdq;
        end else begin
            card_posy_reg <= card_posy;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            card_posz_reg <= 32'h00000000;
        end else if (data_wr == 1'b1 && card_posz_regsel == 1'b1) begin
            card_posz_reg <= extdq;
        end else begin
            card_posz_reg <= card_posz;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            card_posa_reg <= 32'h00000000;
        end else if (data_wr == 1'b1 && card_posa_regsel == 1'b1) begin
            card_posa_reg <= extdq;
        end else begin
            card_posa_reg <= card_posa;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            posx_ref_reg <= 32'h00000000;
        end else if (set_ref == 1'b1) begin
            posx_ref_reg <= posx_reg;
        end else if (data_wr == 1'b1 && posx_ref_regsel == 1'b1) begin
            posx_ref_reg <= extdq;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            posy_ref_reg <= 32'h00000000;
        end else if (set_ref == 1'b1) begin
            posy_ref_reg <= posy_reg;
        end else if (data_wr == 1'b1 && posy_ref_regsel == 1'b1) begin
            posy_ref_reg <= extdq;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            posz_ref_reg <= 32'h00000000;
        end else if (set_ref == 1'b1) begin
            posz_ref_reg <= posz_reg;
        end else if (data_wr == 1'b1 && posz_ref_regsel == 1'b1) begin
            posz_ref_reg <= extdq;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            posa_ref_reg <= 32'h00000000;
        end else if (set_ref == 1'b1) begin
            posa_ref_reg <= posa_reg;
        end else if (data_wr == 1'b1 && posa_ref_regsel == 1'b1) begin
            posa_ref_reg <= extdq;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            card_posx_ref_reg <= 32'h00000000;
        end else if (set_ref == 1'b1) begin
            card_posx_ref_reg <= card_posx_reg;
        end else if (data_wr == 1'b1 && card_posx_ref_regsel == 1'b1) begin
            card_posx_ref_reg <= extdq;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            card_posy_ref_reg <= 32'h00000000;
        end else if (set_ref == 1'b1) begin
            card_posy_ref_reg <= card_posy_reg;
        end else if (data_wr == 1'b1 && card_posy_ref_regsel == 1'b1) begin
            card_posy_ref_reg <= extdq;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            card_posz_ref_reg <= 32'h00000000;
        end else if (set_ref == 1'b1) begin
            card_posz_ref_reg <= card_posz_reg;
        end else if (data_wr == 1'b1 && card_posz_ref_regsel == 1'b1) begin
            card_posz_ref_reg <= extdq;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            card_posa_ref_reg <= 32'h00000000;
        end else if (set_ref == 1'b1) begin
            card_posa_ref_reg <= card_posa_reg;
        end else if (data_wr == 1'b1 && card_posa_ref_regsel == 1'b1) begin
            card_posa_ref_reg <= extdq;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            posx_real_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && posx_real_regsel == 1'b1) begin
                posx_real_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            posy_real_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && posy_real_regsel == 1'b1) begin
                posy_real_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            posz_real_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && posz_real_regsel == 1'b1) begin
                posz_real_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            posa_real_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && posa_real_regsel == 1'b1) begin
                posa_real_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            card_posx_real_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && card_posx_real_regsel == 1'b1) begin
                card_posx_real_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            card_posy_real_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && card_posy_real_regsel == 1'b1) begin
                card_posy_real_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            card_posz_real_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && card_posz_real_regsel == 1'b1) begin
                card_posz_real_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            card_posa_real_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && card_posa_real_regsel == 1'b1) begin
                card_posa_real_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            posx_break_reg <= 32'h00000000;
        end else if (s1 == 1'b1 || s2 == 1'b1 || s3 == 1'b1 || s4 == 1'b1 || s5 == 1'b1 || s6 == 1'b1) begin
            posx_break_reg <= posx_real_reg;
        end else if (data_wr == 1'b1 && posx_break_regsel == 1'b1) begin
            posx_break_reg <= extdq;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            posy_break_reg <= 32'h00000000;
        end else if (s1 == 1'b1 || s2 == 1'b1 || s3 == 1'b1 || s4 == 1'b1 || s5 == 1'b1 || s6 == 1'b1) begin
            posy_break_reg <= posy_real_reg;
        end else if (data_wr == 1'b1 && posy_break_regsel == 1'b1) begin
            posy_break_reg <= extdq;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            posz_break_reg <= 32'h00000000;
        end else if (s1 == 1'b1 || s2 == 1'b1 || s3 == 1'b1 || s4 == 1'b1 || s5 == 1'b1 || s6 == 1'b1) begin
            posz_break_reg <= posz_real_reg;
        end else if (data_wr == 1'b1 && posz_break_regsel == 1'b1) begin
            posz_break_reg <= extdq;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            posa_break_reg <= 32'h00000000;
        end else if (s1 == 1'b1 || s2 == 1'b1 || s3 == 1'b1 || s4 == 1'b1 || s5 == 1'b1 || s6 == 1'b1) begin
            posa_break_reg <= posa_real_reg;
        end else if (data_wr == 1'b1 && posa_break_regsel == 1'b1) begin
            posa_break_reg <= extdq;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            spdx_reg <= 32'h00000000;
        end else if (data_wr == 1'b1 && spdx_regsel == 1'b1) begin
            spdx_reg <= extdq;
        end else begin
            spdx_reg <= delta_x;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            spdy_reg <= 32'h00000000;
        end else if (data_wr == 1'b1 && spdy_regsel == 1'b1) begin
            spdy_reg <= extdq;
        end else begin
            spdy_reg <= delta_y;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            spdz_reg <= 32'h00000000;
        end else if (data_wr == 1'b1 && spdz_regsel == 1'b1) begin
            spdz_reg <= extdq;
        end else begin
            spdz_reg <= delta_z;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            spda_reg <= 32'h00000000;
        end else if (data_wr == 1'b1 && spda_regsel == 1'b1) begin
            spda_reg <= extdq;
        end else begin
            spda_reg <= delta_a;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            dcsreg <= 32'h00000000;
        end else if (data_wr == 1'b1 && dcsregsel == 1'b1) begin
            dcsreg <= extdq;
        end else begin
            dcsreg[0] <= s1;
            dcsreg[1] <= s2;
            dcsreg[2] <= s3;
            dcsreg[3] <= s4;
            dcsreg[4] <= s5;
            dcsreg[5] <= s6;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            mcmreg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && mcmregsel == 1'b1) begin
                mcmreg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            co1reg <= 32'h00000001;
        end else begin
            if (data_wr == 1'b1 && co1regsel == 1'b1) begin
                co1reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            co2reg <= 32'h00000001;
        end else begin
            if (data_wr == 1'b1 && co2regsel == 1'b1) begin
                co2reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            co3reg <= 32'h00000001;
        end else begin
            if (data_wr == 1'b1 && co3regsel == 1'b1) begin
                co3reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            co4reg <= 32'h00000001;
        end else begin
            if (data_wr == 1'b1 && co4regsel == 1'b1) begin
                co4reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            co5reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && co5regsel == 1'b1) begin
                co5reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            co6reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && co6regsel == 1'b1) begin
                co6reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            co7reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && co7regsel == 1'b1) begin
                co7reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            co8reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && co8regsel == 1'b1) begin
                co8reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            jog_posx_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && jog_posx_regsel == 1'b1) begin
                jog_posx_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            jog_posy_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && jog_posy_regsel == 1'b1) begin
                jog_posy_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            jog_posz_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && jog_posz_regsel == 1'b1) begin
                jog_posz_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            jog_posa_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && jog_posa_regsel == 1'b1) begin
                jog_posa_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            jog_negx_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && jog_negx_regsel == 1'b1) begin
                jog_negx_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            jog_negy_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && jog_negy_regsel == 1'b1) begin
                jog_negy_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            jog_negz_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && jog_negz_regsel == 1'b1) begin
                jog_negz_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            jog_nega_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && jog_nega_regsel == 1'b1) begin
                jog_nega_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            szero_softreg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && szero_softregsel == 1'b1) begin
                szero_softreg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            m_cool_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && m_cool_regsel == 1'b1) begin
                m_cool_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            m_cw_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && m_cw_regsel == 1'b1) begin
                m_cw_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            m_atcw_reg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && m_atcw_regsel == 1'b1) begin
                m_atcw_reg <= extdq;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            headreg <= 32'h00000000;
        end else begin
            if (data_wr == 1'b1 && headregsel == 1'b1) begin
                headreg <= extdq;
            end else if ((pre_state == DMAWRDATAST1 || pre_state == DMAWRDATAST2) && tx_st_ready == 1'b1) begin
                headreg[31:3] <= headreg[31:3] + 1;
            end else if (pre_state == DMARDHEAD2) begin
                headreg[31:9] <= headreg[31:9] + 1;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            countreg <= 32'h00000040;
        end else if (clrcmd == 1'b1) begin
            countreg <= 32'h00000040;
        end else if (data_wr == 1'b1 && countregsel == 1'b1) begin
            countreg <= extdq;
        end else if (((pre_state == DMAWRDATAST1 || pre_state == DMAWRDATAST2) && tx_st_ready == 1'b1) || rxfifowr == 1'b1) begin
            countreg[22:3] <= countreg[22:3] - 1;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            rdcountreg <= 32'h00000040;
        end else if (clrcmd == 1'b1) begin
            rdcountreg <= 32'h00000040;
        end else if (data_wr == 1'b1 && countregsel == 1'b1) begin
            rdcountreg <= extdq;
        end else if (pre_state == DMARDHEAD2) begin
            rdcountreg[22:9] <= rdcountreg[22:9] - 1;
        end
    end

    always @(posedge clk) begin
        if (rdcountreg[22:3] == 19'h00000) begin
            clrcmd1 <= 1'b1;
        end else begin
            clrcmd1 <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (countreg[22:3] == 19'h00000) begin
            clrcmd <= 1'b1;
        end else begin
            clrcmd <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            cmdreg[15:0] <= 16'h0000;
        end else if (clrcmd == 1'b1 || clrcmd1 == 1'b1) begin
            cmdreg[15:0] <= 16'h0000;
        end else if (data_wr == 1'b1 && cmdregsel == 1'b1) begin
            cmdreg <= extdq;
        end
    end

    always @(*) begin
        if (cmdreg[8] == 1'b1 && fifordempty == 1'b0) begin
            startdmawr = 1'b1;
        end else begin
            startdmawr = 1'b0;
        end
    end

    always @(posedge clk) begin
        clrfifo <= cmdreg[31] || !rst;
        dmaen   <= cmdreg[30];
    end

    always @(*) begin
        boundry4k = 13'h1000;
        headreglow4k[12] = 1'b0;
        headreglow4k[11:0] = headreg[11:0];
    end

    always @(posedge clk) begin
        canntcross4k <= boundry4k - headreglow4k;

        if (canntcross4k >= 13'h0200) begin
            cross4klength <= 9'h100;
        end else begin
            cross4klength <= canntcross4k[8:0];
        end

        if (fiforddw >= 9'h020) begin
            fifodwlength <= 9'h100;
        end else begin
            fifodwlength[2:0] <= 3'h0;
            fifodwlength[8:3] <= fiforddw[5:0];
        end

        if (countreg[22:0] >= 23'h00100) begin
            ctlength <= 9'h100;
        end else begin
            ctlength <= countreg[8:0];
        end

        if (pre_state == DMAWRWAITST1) begin
            if (cross4klength >= ctlength) begin
                if (ctlength >= fifodwlength) begin
                    bytelength <= fifodwlength;
                end else begin
                    bytelength <= ctlength;
                end
            end else begin
                if (cross4klength >= fifodwlength) begin
                    bytelength <= fifodwlength;
                end else begin
                    bytelength <= cross4klength;
                end
            end
        end
    end

    always @(*) begin
        dmawrtag = 8'h00;

        dmawrheadrega[0] = 1'b0;
        dmawrheadrega[6:1] = bytelength[8:3];
        dmawrheadrega[9:7] = 3'h0;
        dmawrheadrega[11:10] = 2'h0;
        dmawrheadrega[13:12] = 2'h2;
        dmawrheadrega[15:14] = 2'h0;
        dmawrheadrega[23:16] = 8'h00;
        dmawrheadrega[31:24] = 8'h40;

        dmawrheadrega[39:32] = 8'hFF;
        dmawrheadrega[47:40] = dmawrtag;
        dmawrheadrega[50:48] = 3'h0;
        dmawrheadrega[55:51] = devnum;
        dmawrheadrega[63:56] = busnum;

        dmawrheadregb[1:0] = 2'h0;
        dmawrheadregb[31:2] = headreg[31:2];
        dmawrheadregb[63:32] = 32'h00000000;
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            dmardtag <= 8'h00;
        end else begin
            if (pre_state == DMARDHEAD2) begin
                dmardtag <= dmardtag + 1;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            dmardcpldtag <= 12'h000;
        end else begin
            if (rxfifowr == 1'b1) begin
                dmardcpldtag <= dmardcpldtag + 1;
            end
        end
    end

    always @(posedge clk) begin
        if ((dmardtag[3] != dmardcpldtag[9]) && (dmardtag[2:0] == dmardcpldtag[8:6])) begin
            dmarden <= 1'b0;
        end else begin
            dmarden <= 1'b1;
        end
    end

    always @(*) begin
        dmardheadrega[9:0]   = 10'h0080;
        dmardheadrega[11:10] = 2'h0;
        dmardheadrega[13:12] = 2'h2;
        dmardheadrega[15:14] = 2'h0;
        dmardheadrega[23:16] = 8'h00;
        dmardheadrega[31:24] = 8'h00;

        dmardheadrega[39:32] = 8'hFF;
        dmardheadrega[44:40] = dmardtag[4:0];
        dmardheadrega[47:45] = 3'h0;
        dmardheadrega[50:48] = 3'h0;
        dmardheadrega[55:51] = devnum;
        dmardheadrega[63:56] = busnum;

        dmardheadregb[1:0]   = 2'h0;
        dmardheadregb[31:2]  = headreg[31:2];
        dmardheadregb[63:32] = 32'h00000000;
    end

    always @(posedge clk) begin
        if (tx_cred[2:0] >= 3'h3) begin
            postheaden <= 1'b1;
        end else begin
            postheaden <= 1'b0;
        end

        if (tx_cred[14:3] >= 12'h00C) begin
            postdataen <= 1'b1;
        end else begin
            postdataen <= 1'b0;
        end

        if (tx_cred[17:15] >= 3'h2) begin
            npheaden <= 1'b1;
        end else begin
            npheaden <= 1'b0;
        end

        if (tx_cred[20:18] >= 3'h2) begin
            npdataen <= 1'b1;
        end else begin
            npdataen <= 1'b0;
        end

        if (tx_cred[23:21] >= 3'h2) begin
            cpheaden <= 1'b1;
        end else begin
            cpheaden <= 1'b0;
        end

        if (tx_cred[35:24] >= 12'h004) begin
            cpdataen <= 1'b1;
        end else begin
            cpdataen <= 1'b0;
        end
    end

    always @(posedge clk) begin
        memrdcpheadrega[9:0] = 10'h0001;
        memrdcpheadrega[11:10] = 2'h0;
        memrdcpheadrega[13:12] = attrib;
        memrdcpheadrega[19:14] = 6'h00;
        memrdcpheadrega[22:20] = tc;
        memrdcpheadrega[31:23] = 9'h04A;

        memrdcpheadrega[47:32] = 16'h0004;
        memrdcpheadrega[50:48] = 3'h0;
        memrdcpheadrega[55:51] = devnum;
        memrdcpheadrega[63:56] = busnum;

        memrdcpheadregb[6:0] = ext_add[6:0];
        memrdcpheadregb[7] = 1'b0;
        memrdcpheadregb[15:8] = tag;
        memrdcpheadregb[31:16] = reqid;

        if (ext_add[2] == 1'b1) begin
            memrdcpheadregb[63:32] = extdq;
        end else begin
            memrdcpheadregb[63:32] = 32'h00000000;
        end

        if (pre_state == MEMRDCPLDWAITST2) begin
            memrdcpdatareg[31:0]  = extdq;
            memrdcpdatareg[63:32] = 32'h00000000;
        end
    end

    always @(*) begin
        case (pre_state)
            IDLE: begin
                if (memrdreq == 1'b1) begin
                    nxt_state = MEMRDCPLDHEAD1;
                end else if (startdmawr == 1'b1) begin
                    nxt_state = DMAWRWAITST1;
                end else if (cmdreg[9] == 1'b1 && dmarden == 1'b1) begin
                    nxt_state = DMARDWAITST1;
                end else begin
                    nxt_state = IDLE;
                end
            end
            MEMRDCPLDHEAD1: begin
                if (cpheaden == 1'b1 && tx_st_ready == 1'b1) begin
                    nxt_state = MEMRDCPLDHEAD2;
                end else begin
                    nxt_state = MEMRDCPLDHEAD1;
                end
            end
            MEMRDCPLDHEAD2: begin
                if (cpdataen == 1'b1 && tx_st_ready == 1'b1) begin
                    nxt_state = MEMRDCPLDWAITST1;
                end else begin
                    nxt_state = MEMRDCPLDHEAD2;
                end
            end
            MEMRDCPLDWAITST1: begin
                nxt_state = MEMRDCPLDWAITST2;
            end
            MEMRDCPLDWAITST2: begin
                nxt_state = MEMRDCPLDDATAST1;
            end
            MEMRDCPLDDATAST1: begin
                if (cpdataen == 1'b1 && tx_st_ready == 1'b1) begin
                    nxt_state = MEMRDCPLDDONE;
                end else begin
                    nxt_state = MEMRDCPLDDATAST1;
                end
            end
            MEMRDCPLDDONE: begin
                nxt_state = IDLE;
            end
            DMAWRWAITST1: begin
                if (postheaden == 1'b1) begin
                    nxt_state = DMAWRHEAD1;
                end else begin
                    nxt_state = DMAWRWAITST1;
                end
            end
            DMAWRHEAD1: begin
                if (tx_st_ready == 1'b1) begin
                    nxt_state = DMAWRHEAD2;
                end else begin
                    nxt_state = DMAWRHEAD1;
                end
            end
            DMAWRHEAD2: begin
                if (tx_st_ready == 1'b1) begin
                    nxt_state = DMAWRDATAST1;
                end else begin
                    nxt_state = DMAWRHEAD2;
                end
            end
            DMAWRDATAST1: begin
                if (tx_st_ready == 1'b1) begin
                    nxt_state = DMAWRDATAST2;
                end else begin
                    nxt_state = DMAWRDATAST1;
                end
            end
            DMAWRDATAST2: begin
                if (tx_st_ready == 1'b1 && countreg[22:3] == 19'h00000) begin
                    nxt_state = DMAWRWAITST3;
                end else if (tx_st_ready == 1'b1) begin
                    nxt_state = DMAWRDATAST1;
                end else begin
                    nxt_state = DMAWRDATAST2;
                end
            end
            DMAWRWAITST3: begin
                nxt_state = DMAWRWAITST4;
            end
            DMAWRWAITST4: begin
                nxt_state = DMAWRWAITST5;
            end
            DMAWRWAITST5: begin
                nxt_state = DMAWRWAITST6;
            end
            DMAWRWAITST6: begin
                nxt_state = DMAWRWAITST7;
            end
            DMAWRWAITST7: begin
                nxt_state = DMAWRWAITST8;
            end
            DMAWRWAITST8: begin
                nxt_state = IDLE;
            end
            DMARDWAITST1: begin
                nxt_state = DMARDWAITST2;
            end
            DMARDWAITST2: begin
                if (npheaden == 1'b1) begin
                    nxt_state = DMARDHEAD1;
                end else begin
                    nxt_state = DMARDWAITST2;
                end
            end
            DMARDHEAD1: begin
                if (tx_st_ready == 1'b1) begin
                    nxt_state = DMARDHEAD2;
                end else begin
                    nxt_state = DMARDHEAD1;
                end
            end
            DMARDHEAD2: begin
                if (tx_st_ready == 1'b1 && rdcountreg[22:9] == 14'h0000) begin
                    nxt_state = DMARDWAITST3;
                end else if (tx_st_ready == 1'b1) begin
                    nxt_state = DMARDWAITST2;
                end else begin
                    nxt_state = DMARDHEAD2;
                end
            end
            DMARDWAITST3: begin
                nxt_state = DMARDWAITST4;
            end
            DMARDWAITST4: begin
                nxt_state = DMARDWAITST5;
            end
            DMARDWAITST5: begin
                nxt_state = DMARDWAITST6;
            end
            DMARDWAITST6: begin
                nxt_state = IDLE;
            end
            default: begin
                nxt_state = IDLE;
            end
        endcase
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            pre_state <= IDLE;
        end else begin
            pre_state <= nxt_state;
        end
    end

    always @(posedge clk) begin
        if (pre_state == MEMRDCPLDHEAD1) begin
            txfifodq[71:64] <= 8'h00;
            txfifodq[63:0] <= memrdcpheadrega;
            tx_st_valid <= 1'b1;
            tx_st_err <= 1'b0;
        end else if (pre_state == MEMRDCPLDHEAD2) begin
            txfifodq[71:64] <= 8'h00;
            txfifodq[63:0] <= memrdcpheadregb;
            tx_st_valid <= 1'b1;
            tx_st_err <= 1'b0;
        end else if (pre_state == MEMRDCPLDDATAST1) begin
            txfifodq[71:64] <= 8'h00;
            txfifodq[63:0] <= memrdcpdatareg;
            tx_st_valid <= 1'b1;
            tx_st_err <= 1'b0;
        end else if (pre_state == DMAWRHEAD1) begin
            txfifodq[71:64] <= 8'h00;
            txfifodq[63:0] <= dmawrheadrega;
            tx_st_valid <= 1'b1;
            tx_st_err <= 1'b0;
        end else if (pre_state == DMAWRHEAD2) begin
            txfifodq[71:64] <= 8'h00;
            txfifodq[63:0] <= dmawrheadregb;
            tx_st_valid <= 1'b1;
            tx_st_err <= 1'b0;
        end else if (pre_state == DMAWRDATAST1) begin
            txfifodq[71:64] <= 8'hFF;
            txfifodq[63:0] <= fifodqin;
            tx_st_valid <= 1'b1;
            tx_st_err <= 1'b0;
        end else if (pre_state == DMAWRDATAST2) begin
            txfifodq[71:64] <= 8'hFF;
            txfifodq[63:0] <= fifodqin;
            tx_st_valid <= 1'b1;
            tx_st_err <= 1'b0;
        end else if (pre_state == DMARDHEAD1) begin
            txfifodq[71:64] <= 8'h00;
            txfifodq[63:0] <= dmardheadrega;
            tx_st_valid <= 1'b1;
            tx_st_err <= 1'b0;
        end else if (pre_state == DMARDHEAD2) begin
            txfifodq[71:64] <= 8'h00;
            txfifodq[63:0] <= dmardheadregb;
            tx_st_valid <= 1'b1;
            tx_st_err <= 1'b0;
        end else begin
            txfifodq[71:64] <= 8'h00;
            txfifodq[63:0] <= 64'h0000000000000000;
            tx_st_valid <= 1'b0;
            tx_st_err <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (pre_state == MEMRDCPLDHEAD1 || pre_state == MEMRDCPLDHEAD2 || pre_state == MEMRDCPLDDATAST1) begin
            memrdack <= 1'b1;
        end else begin
            memrdack <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (pre_state == DMAWRDATAST1 || pre_state == DMAWRDATAST2) begin
            fiford <= 1'b1;
        end else begin
            fiford <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (pre_state == IDLE) begin
            led1 <= 1'b0;
            led2 <= 1'b0;
            led3 <= 1'b0;
            led4 <= 1'b0;
        end else if (pre_state == MEMRDCPLDHEAD1) begin
            led1 <= 1'b1;
        end else if (pre_state == DMAWRHEAD1) begin
            led2 <= 1'b1;
        end else if (pre_state == DMARDHEAD1) begin
            led3 <= 1'b1;
        end
    end

    assign posx_ref = posx_ref_reg;
    assign posy_ref = posy_ref_reg;
    assign posz_ref = posz_ref_reg;
    assign posa_ref = posa_ref_reg;

    assign card_posx_ref = card_posx_ref_reg;
    assign card_posy_ref = card_posy_ref_reg;
    assign card_posz_ref = card_posz_ref_reg;
    assign card_posa_ref = card_posa_ref_reg;

endmodule
