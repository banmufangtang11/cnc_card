`timescale 1ns / 1ps

// 模块功能：PCIe物理层和数据链路层核心模块
// 集成PCIe硬核(PCIe_hard_plus)和PLL时钟生成器
// 负责PCIe信号的物理收发和链路层协议处理

module PCIEbot(
    // 输入信号
    // 应用层中断状态
    input         app_int_sts,
    // 完成包错误标志
    input  [6:0]  cpl_err,
    // 完成包待处理标志
    input         cpl_pending,
    // 100MHz自由运行时钟
    input         free100m,
    // PCIe复位信号
    input         pcie_rst,
    // 参考时钟(100MHz)
    input         refclk,
    // PCIe RX差分输入(4条lane)
    input         rx_in0,
    input         rx_in1,
    input         rx_in2,
    input         rx_in3,
    // RX流控掩码
    input         rx_st_mask,
    // RX接收就绪
    input         rx_st_ready,
    // TX数据(64位)
    input  [63:0] tx_st_data,
    // TX包结束标志
    input         tx_st_eop,
    // TX错误标志
    input         tx_st_err,
    // TX包开始标志
    input         tx_st_sop,
    // TX有效标志
    input         tx_st_valid,
    
    // 输出信号
    // 应用层中断确认
    output        app_int_ack,
    // TLP事务层时钟
    output        tlpclk,
    // lane激活状态
    output [3:0]  lane_act,
    // LTSSM状态机状态
    output [4:0]  ltssm,
    // RX地址解码
    output [7:0]  rx_st_bardec,
    // RX字节使能
    output [7:0]  rx_st_be,
    // RX数据(64位)
    output [63:0] rx_st_data,
    // RX包结束标志
    output        rx_st_eop,
    // RX错误标志
    output        rx_st_err,
    // RX包开始标志
    output        rx_st_sop,
    // RX有效标志
    output        rx_st_valid,
    // 系统复位(低有效)
    output        srstn,
    // 配置空间地址
    output [3:0]  tl_cfg_add,
    // 配置空间控制寄存器
    output [31:0] tl_cfg_ctl,
    // 配置空间控制写使能
    output        tl_cfg_ctl_wr,
    // 配置空间状态寄存器
    output [52:0] tl_cfg_sts,
    // 配置空间状态写使能
    output        tl_cfg_sts_wr,
    // TX信用额度
    output [35:0] tx_cred,
    // TX FIFO空标志
    output        tx_fifo_empty,
    // PCIe TX差分输出(4条lane)
    output        tx_out0,
    output        tx_out1,
    output        tx_out2,
    output        tx_out3,
    // TX发送就绪
    output        tx_st_ready
);

// ================================================
// PLL内部信号
// ================================================
wire        reconfig_clk;
wire        reconfig_locked;


// ================================================
// PLL时钟生成器 - 产生reconfig_clk和tlpclk
// ================================================
altpcierd_reconfig_clk_pll u_pll(
    .inclk0(refclk),
    .c0(reconfig_clk),
    .c1(tlpclk),
    .locked(reconfig_locked)
);


// ================================================
// PCIe硬核顶层 - PCIe物理层和数据链路层实现
// ================================================
PCIe_hard_plus u_pcie_hard(
    .app_int_sts(app_int_sts),
    .app_msi_num(5'b00000),
    .app_msi_req(1'b0),
    .app_msi_tc(3'b000),
    .cpl_err(cpl_err),
    .cpl_pending(cpl_pending),
    .free100m(free100m),
    .pcie_rst(pcie_rst),
    .refclk(refclk),
    .rx_in0(rx_in0),
    .rx_in1(rx_in1),
    .rx_in2(rx_in2),
    .rx_in3(rx_in3),
    .rx_st_mask(rx_st_mask),
    .rx_st_ready(rx_st_ready),
    .tx_st_data(tx_st_data),
    .tx_st_eop(tx_st_eop),
    .tx_st_err(tx_st_err),
    .tx_st_sop(tx_st_sop),
    .tx_st_valid(tx_st_valid),
    .app_int_ack(app_int_ack),
    .lane_act(lane_act),
    .ltssm(ltssm),
    .rx_st_bardec(rx_st_bardec),
    .rx_st_be(rx_st_be),
    .rx_st_data(rx_st_data),
    .rx_st_eop(rx_st_eop),
    .rx_st_err(rx_st_err),
    .rx_st_sop(rx_st_sop),
    .rx_st_valid(rx_st_valid),
    .srstn(srstn),
    .tl_cfg_add(tl_cfg_add),
    .tl_cfg_ctl(tl_cfg_ctl),
    .tl_cfg_ctl_wr(tl_cfg_ctl_wr),
    .tl_cfg_sts(tl_cfg_sts),
    .tl_cfg_sts_wr(tl_cfg_sts_wr),
    .tx_cred(tx_cred),
    .tx_fifo_empty(tx_fifo_empty),
    .tx_out0(tx_out0),
    .tx_out1(tx_out1),
    .tx_out2(tx_out2),
    .tx_out3(tx_out3),
    .tx_st_ready(tx_st_ready)
);

endmodule