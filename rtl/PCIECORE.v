`timescale 1ns / 1ps

// 模块功能：PCIe核心接口模块
// 集成PCIe物理层、事务层、配置空间和FIFO接口
// 负责PCIEbot、rsstinf、cfgspace等子模块的协调

module PCIECORE(
    // PCIe RX物理层输入
    input         rx_in0,
    input         rx_in1,
    input         rx_in2,
    input         rx_in3,
    
    // PCIe TX物理层输出
    output        tx_out0,
    output        tx_out1,
    output        tx_out2,
    output        tx_out3,
    
    // 时钟和复位信号
    input         refclk,
    input         free100m,
    input         pcie_rst,
    
    // FIFO接口
    input         fifoinclk,
    input         fifooutclk,
    input         fifooutrd,
    
    // 外部中断请求
    input         ext_int_req,
    input         set_ref,
    
    // 轴使能选择信号
    input         s1,
    input         s2,
    input         s3,
    input         s4,
    input         s5,
    input         s6,
    
    // 辅助反馈信号
    input  [31:0] aux_back,
    input  [31:0] card_count_a,
    input  [31:0] card_count_x,
    input  [31:0] card_count_y,
    input  [31:0] card_count_z,
    input  [31:0] delta_a,
    input  [31:0] delta_x,
    input  [31:0] delta_y,
    input  [31:0] delta_z,
    
    // 双向数据总线
    inout  [31:0] extdq,
    
    // 编码器位置反馈
    input  [31:0] posa,
    input  [31:0] posx,
    input  [31:0] posy,
    input  [31:0] posz,
    
    // FIFO输出状态
    input         fifooutrdempty,
    
    // 输出信号
    output        tlpclk,
    output        rstout,
    output        ext_rd,
    output        iosel,
    output        ext_wr,
    output        memsel1,
    output        memsel2,
    
    // 轴使能输出
    output        co1,
    output        co2,
    output        co3,
    output        co4,
    output        co5,
    output        co6,
    output        co7,
    output        co8,
    
    // 软件运动控制信号
    output        posx_soft,
    output        negx_soft,
    output        posy_soft,
    output        negy_soft,
    output        posz_soft,
    output        negz_soft,
    output        posa_soft,
    output        nega_soft,
    output        szero_soft,
    
    // 主轴控制信号
    output        m_cool,
    output        m_cw,
    output        m_atcw,
    
    // 辅助控制信号
    output [31:0] aux_ctl,
    output [21:0] ext_add,
    
    // FIFO数据输出
    output [63:0] fifooutdq,
    output [8:0]  fifooutdw,
    
    // LED指示
    output [3:0]  led
);

// ================================================
// PCIe核心控制信号
// ================================================
wire        app_int_sts;
wire        cpl_err;
wire        cpl_pending;
wire        lane_act;
wire [2:0]  ltssm;
wire        rx_st_bardec;
wire [7:0]  rx_st_be;
wire [63:0] rx_st_data;
wire        rx_st_eop;
wire        rx_st_err;
wire        rx_st_sop;
wire        rx_st_valid;
wire        srstn;
wire [7:0]  tl_cfg_add;
wire [31:0] tl_cfg_ctl;
wire        tl_cfg_ctl_wr;
wire [31:0] tl_cfg_sts;
wire        tl_cfg_sts_wr;
wire [23:0] tx_cred;
wire        tx_fifo_empty;
wire        rx_st_ready;
wire        tx_st_data;
wire        tx_st_eop;
wire        tx_st_err;
wire        tx_st_sop;
wire        tx_st_valid;
wire        rx_st_mask;
wire        app_int_ack;


// ================================================
// PCIe Bot模块 - PCIe物理层和数据链路层核心
// ================================================
PCIEbot inst_pcie_bot(
    .app_int_sts(app_int_sts),
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
    .tlpclk(tlpclk),
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


// ================================================
// RSSTINF模块 - Avalon-ST到FIFO数据宽度转换
// ================================================
rsstinf inst_rsstinf(
    .clk(tlpclk),
    .rst(!srstn),
    .rx_st_data(rx_st_data),
    .rx_st_be(rx_st_be),
    .rx_st_bardec(rx_st_bardec),
    .rx_st_valid(rx_st_valid),
    .rx_st_err(rx_st_err),
    .rx_st_sop(rx_st_sop),
    .rx_st_eop(rx_st_eop),
    .rx_st_ready(rx_st_ready),
    .fifooutclk(fifooutclk),
    .fifooutrd(fifooutrd),
    .fifooutdq(fifooutdq),
    .fifooutdw(fifooutdw),
    .fifooutrdempty(fifooutrdempty),
    .led(led)
);


// ================================================
// TXPROC模块 - PCIe发送事务处理
// 生成TX TLP包，管理中断，控制CNC运动寄存器
// ================================================
txproc inst_txproc(
    .clk(tlpclk),
    .rst(!srstn),
    .tx_fifo_empty(tx_fifo_empty),
    .tx_cred(tx_cred),
    .ext_int_req(ext_int_req),
    .set_ref(set_ref),
    .aux_back(aux_back),
    .card_count_a(card_count_a),
    .card_count_x(card_count_x),
    .card_count_y(card_count_y),
    .card_count_z(card_count_z),
    .delta_a(delta_a),
    .delta_x(delta_x),
    .delta_y(delta_y),
    .delta_z(delta_z),
    .posa(posa),
    .posx(posx),
    .posy(posy),
    .posz(posz),
    .extdq(extdq),
    .app_int_sts(app_int_sts),
    .app_int_ack(app_int_ack),
    .tx_st_data(tx_st_data),
    .tx_st_sop(tx_st_sop),
    .tx_st_eop(tx_st_eop),
    .tx_st_valid(tx_st_valid),
    .tx_st_err(tx_st_err),
    .tx_st_ready(tx_st_ready),
    .posx_soft(posx_soft),
    .negx_soft(negx_soft),
    .posy_soft(posy_soft),
    .negy_soft(negy_soft),
    .posz_soft(posz_soft),
    .negz_soft(negz_soft),
    .posa_soft(posa_soft),
    .nega_soft(nega_soft),
    .szero_soft(szero_soft),
    .m_cool(m_cool),
    .m_cw(m_cw),
    .m_atcw(m_atcw),
    .aux_ctl(aux_ctl),
    .ext_add(ext_add),
    .ext_wr(ext_wr),
    .ext_rd(ext_rd),
    .iosel(iosel),
    .memsel1(memsel1),
    .memsel2(memsel2),
    .co1(co1),
    .co2(co2),
    .co3(co3),
    .co4(co4),
    .co5(co5),
    .co6(co6),
    .co7(co7),
    .co8(co8),
    .rstout(rstout)
);


// ================================================
// CFGSPACE模块 - PCIe配置空间管理
// ================================================
cfgspace inst_cfgspace(
    .clk(tlpclk),
    .rst(!srstn),
    .tl_cfg_add(tl_cfg_add),
    .tl_cfg_ctl(tl_cfg_ctl),
    .tl_cfg_ctl_wr(tl_cfg_ctl_wr),
    .tl_cfg_sts(tl_cfg_sts),
    .tl_cfg_sts_wr(tl_cfg_sts_wr),
    .cpl_err(cpl_err),
    .cpl_pending(cpl_pending),
    .lane_act(lane_act),
    .ltssm(ltssm),
    .rx_st_mask(rx_st_mask)
);

endmodule