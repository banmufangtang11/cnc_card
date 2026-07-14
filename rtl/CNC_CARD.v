`timescale 1ns / 1ps

// 模块功能：CNC控制卡顶层模块
// 集成PCIe接口、运动控制、编码器处理、手轮输入、刀具控制等全部功能
// 负责协调各子模块之间的数据流向和控制信号

module CNC_CARD(
    // 系统时钟和复位
    input         free100m,
    input         pcie_rst,
    input         refclk,

    // PCIe物理层接口
    input         rx_in0,
    input         rx_in1,
    input         rx_in2,
    input         rx_in3,
    output        tx_out0,
    output        tx_out1,
    output        tx_out2,
    output        tx_out3,

    // 运动控制按钮输入
    input         start,
    input         stop,
    input         s1,
    input         s2,
    input         s3,
    input         s4,
    input         s5,
    input         s6,

    // 手动JOG按钮输入（X/Y/Z/A轴正负方向）
    input         pos_x,
    input         neg_x,
    input         pos_y,
    input         neg_y,
    input         pos_z,
    input         neg_z,
    input         pos_a,
    input         neg_a,

    // 编码器反馈输入（X/Y/Z/A轴A/B相信号）
    input         x_a,
    input         x_b,
    input         y_a,
    input         y_b,
    input         z_a,
    input         z_b,
    input         a_a,
    input         a_b,

    // 回零相关信号
    input         szero,
    input         zero_xdot,
    input         zero_ydot,
    input         zero_zdot,
    input         set_ref,
    input         renew_count,

    // FIFO复位信号
    input         rst_fifo,

    // 手轮输入信号
    input         hw_valid,
    input         hw_Ain,
    input         hw_Bin,
    input         hw_X1,
    input         hw_X10,
    input         hw_X100,
    input         hw_HX,
    input         hw_HY,
    input         hw_HZ,
    input         hw_HA,

    // 刀具测量和换刀信号
    input         mag_fwOK,
    input         mag_bwOK,
    input         mag_count,
    input         tool_looseOK,
    input         toolsetter_trigger,
    input         toolsetter_out,

    // 状态输出信号
    output        downloaded,
    output        fifo33_alempty,

    // 脉冲输出（8轴）
    output        p1, p2, p3, p4, p5, p6, p7, p8,

    // 方向输出（8轴）
    output        d1, d2, d3, d4, d5, d6, d7, d8,

    // 轴使能输出（8轴）
    output        co1, co2, co3, co4, co5, co6, co7, co8,

    // 主轴控制输出
    output        m_cool,
    output        m_cw,
    output        m_atcw,

    // 刀具控制输出
    output        toolsetter_on,
    output        mag_on,
    output        mag_fw,
    output        mag_bw,
    output        tool_loose,

    // LED指示
    output [3:0]  led
);

// 时钟信号
wire        clk_50m;
wire        clk_40m;

// 复位信号
wire        rst;

// PCIe核心时钟
wire        tlpclk;

// 时钟生成器输出
wire        pll_out100m;

// FIFO接口信号
wire        fifo33_wrreq;
wire        fifo33_rdreq;
wire        fifo33_full;
wire        fifo33_alfull;
wire        fifo33_empty;
wire        fifo33_alempty_int;
wire [31:0] fifo33_datain;
wire [31:0] fifo33_dataout;

wire        fifo31_wrreq;
wire        fifo31_empty;
wire [10:0] fifo31_usedw;
wire [63:0] fifo31_datain;

// PCIe FIFO接口
wire [8:0]  pcie_fifooutdw;
wire        pcie_fifooutrd;
wire        pcie_fifooutrdempty;

// 外部接口信号
wire [21:0] ext_add;
wire        ext_rd;
wire        ext_wr;
wire        ext_int_req;
wire [31:0] extdq;
wire        iosel;
wire        memsel1;
wire        memsel2;

// 辅助控制信号
wire [31:0] aux_ctl;
wire [31:0] aux_back;
wire [31:0] aux_fee;
wire        z_stop;

// 编码器计数信号
wire [31:0] count_x;
wire [31:0] count_y;
wire [31:0] count_z;
wire [31:0] count_a;
wire [31:0] delta_x;
wire [31:0] delta_y;
wire [31:0] delta_z;
wire [31:0] delta_a;

// 卡位置计数信号
wire [31:0] card_count_x;
wire [31:0] card_count_y;
wire [31:0] card_count_z;
wire [31:0] card_count_a;

// DDA插补信号
wire [31:0] dda_datain;
wire        valid;

// JOG运动信号
wire        dir_x_jog_jog1;
wire        dir_y_jog_jog1;
wire        dir_z_jog_jog1;
wire        dir_a_jog1;
wire        puls_x_jog_jog1;
wire        puls_y_jog_jog1;
wire        puls_z_jog_jog1;
wire        puls_a_jog1;

// JOG选择信号
wire        dir_x_jog_jog;
wire        dir_y_jog_jog;
wire        dir_z_jog_jog;
wire        dir_a_jog;
wire        puls_x_jog_jog;
wire        puls_y_jog_jog;
wire        puls_z_jog_jog;
wire        puls_a_jog;

// 回零运动信号
wire        dir_x_jog_zero;
wire        dir_y_jog_zero;
wire        dir_z_jog_zero;
wire        puls_x_jog_zero;
wire        puls_y_jog_zero;
wire        puls_z_jog_zero;

// 手轮运动信号
wire        dir_x_hw;
wire        dir_y_hw;
wire        dir_z_hw;
wire        dir_a_hw;
wire        puls_x_hw;
wire        puls_y_hw;
wire        puls_z_hw;
wire        puls_a_hw;

// DDA插补信号
wire        dir_x_dda;
wire        dir_y_dda;
wire        dir_z_dda;
wire        dir_a_dda;
wire        puls_x_dda;
wire        puls_y_dda;
wire        puls_z_dda;
wire        puls_a_dda;

// 最终运动控制信号
wire        dx, dy, dz, da;
wire        px, py, pz, pa;

// 软件控制信号
wire        posx_s, negx_s, posy_s, negy_s, posz_s, negz_s, posa_s, nega_s;
wire        szero_s;

// 换刀机构信号
wire        mag_axis;
wire        mag_dir;
wire        mag_pul;
wire        magcout;
wire        fwok;
wire        bwok;
wire        looseok;

// 按钮消抖信号
wire        key_set_ref;
wire        key_zero;
wire        renew_c;

// 回零完成信号
wire        o_set_x;
wire        o_set_y;
wire        o_set_z;

// 编码器滤波中间信号
wire        enc_x_A, enc_x_B;
wire        enc_y_A, enc_y_B;
wire        enc_z_A, enc_z_B;
wire        enc_a_A, enc_a_B;


// ================================================
// PCIe核心模块
// ================================================
PCIECORE u_pcie_core(
    .fifooutclk(tlpclk),
    .fifooutrd(pcie_fifooutrd),
    .free100m(pll_out100m),
    .pcie_rst(pcie_rst),
    .refclk(refclk),
    .rx_in0(rx_in0),
    .rx_in1(rx_in1),
    .rx_in2(rx_in2),
    .rx_in3(rx_in3),
    .fifoinclk(tlpclk),

    .ext_int_req(ext_int_req),
    .set_ref(key_set_ref | o_set_y | o_set_z | o_set_x),
    .s1(s1),
    .s2(s2),
    .s3(s3),
    .s4(s4),
    .s5(s5),
    .s6(s6),
    .aux_back(aux_back),
    .card_count_a(card_count_a),
    .card_count_x(card_count_x),
    .card_count_y(card_count_y),
    .card_count_z(card_count_z),
    .delta_a(delta_a),
    .delta_x(delta_x),
    .delta_y(delta_y),
    .delta_z(delta_z),
    .extdq(extdq),

    .posa(count_a),
    .posx(count_x),
    .posy(count_y),
    .posz(count_z),
    .fifooutrdempty(pcie_fifooutrdempty),
    .tlpclk(tlpclk),
    .rstout(rst),
    .ext_rd(ext_rd),
    .iosel(iosel),
    .ext_wr(ext_wr),
    .memsel1(memsel1),
    .memsel2(memsel2),
    .tx_out0(tx_out0),
    .tx_out1(tx_out1),
    .tx_out2(tx_out2),
    .tx_out3(tx_out3),
    .co1(co1),
    .co2(co2),
    .co3(co3),
    .co4(co4),
    .co5(co5),
    .co6(co6),
    .co7(co7),
    .co8(co8),

    .posx_soft(posx_s),
    .negx_soft(negx_s),
    .posy_soft(posy_s),
    .negy_soft(negy_s),
    .posz_soft(posz_s),
    .negz_soft(negz_s),
    .posa_soft(posa_s),
    .nega_soft(nega_s),
    .szero_soft(szero_s),
    .m_cool(m_cool),
    .m_cw(m_cw),
    .m_atcw(m_atcw),
    .aux_ctl(aux_ctl),
    .ext_add(ext_add),

    .fifooutdq(fifo31_datain),
    .fifooutdw(pcie_fifooutdw),
    .led(led)
);


// ================================================
// 时钟生成器（100MHz -> 100MHz, 40MHz, 50MHz）
// ================================================
altpll0 u_pll(
    .inclk0(free100m),
    .c0(pll_out100m),
    .c1(clk_40m),
    .c3(clk_50m)
);


// ================================================
// FIFO33 - 运动指令缓冲区
// ================================================
fifo33 u_fifo33(
    .wrreq(fifo33_wrreq),
    .rdreq(fifo33_rdreq),
    .clock(tlpclk),
    .aclr(!rst_fifo),
    .data(fifo33_datain),
    .full(fifo33_full),
    .almost_full(fifo33_alfull),
    .empty(fifo33_empty),
    .almost_empty(fifo33_alempty_int),
    .q(fifo33_dataout)
);


// ================================================
// FIFO31 - PCIe接收数据缓冲区
// ================================================
fifo31 u_fifo31(
    .wrreq(fifo31_wrreq),
    .clock(tlpclk),
    .data(fifo31_datain),
    .empty(fifo31_empty),
    .usedw(fifo31_usedw)
);


// ================================================
// 外部接口模块 - 处理PCIe与运动控制之间的数据交换
// ================================================
ext_inf u_ext_inf(
    .clk(tlpclk),
    .rst(rst),
    .valid(valid),
    .data_rd_out(ext_rd),
    .data_wr(ext_wr),
    .empty(fifo33_empty),
    .full(fifo33_full),
    .almost_empty(fifo33_alempty_int),
    .almost_full(fifo33_alfull),
    .iosel(iosel),
    .memsel1(memsel1),
    .memsel2(memsel2),
    .app_int_ack(1'b0),
    .dq(extdq),
    .ext_add(ext_add),
    .ext_int_req(ext_int_req),
    .wrreq(fifo33_wrreq),
    .fifo_in(fifo33_datain)
);


// ================================================
// FIFO数据传输控制 - PCIe FIFO到FIFO31的数据搬运
// ================================================
test_fifo u_test_fifo(
    .clk(tlpclk),
    .rst(rst),
    .rdempty(pcie_fifooutrdempty),
    .dw(fifo31_usedw),
    .rddw(pcie_fifooutdw),
    .fifo31_inwr(fifo31_wrreq),
    .fiford(pcie_fifooutrd)
);


// ================================================
// 编码器滤波模块 - 对编码器A/B相信号进行滤波去抖
// ================================================
filter_encode u_enc_x_A(.clk(tlpclk), .rst_n(rst), .puls(x_a), .filter(enc_x_A));
filter_encode u_enc_x_B(.clk(tlpclk), .rst_n(rst), .puls(x_b), .filter(enc_x_B));
filter_encode u_enc_y_A(.clk(tlpclk), .rst_n(rst), .puls(y_a), .filter(enc_y_A));
filter_encode u_enc_y_B(.clk(tlpclk), .rst_n(rst), .puls(y_b), .filter(enc_y_B));
filter_encode u_enc_z_A(.clk(tlpclk), .rst_n(rst), .puls(z_a), .filter(enc_z_A));
filter_encode u_enc_z_B(.clk(tlpclk), .rst_n(rst), .puls(z_b), .filter(enc_z_B));
filter_encode u_enc_a_A(.clk(tlpclk), .rst_n(rst), .puls(a_a), .filter(enc_a_A));
filter_encode u_enc_a_B(.clk(tlpclk), .rst_n(rst), .puls(a_b), .filter(enc_a_B));


// ================================================
// 编码器脉冲计数模块 - 4倍频计数，输出增量和总量
// ================================================
encode_pd u_encode_x(
    .clk(tlpclk),
    .rst_n(rst),
    .plus_A(enc_x_A),
    .plus_B(enc_x_B),
    .renew(renew_c),
    .delta_count(delta_x),
    .total_count(count_x)
);

encode_pd u_encode_y(
    .clk(tlpclk),
    .rst_n(rst),
    .plus_A(enc_y_A),
    .plus_B(enc_y_B),
    .renew(renew_c),
    .delta_count(delta_y),
    .total_count(count_y)
);

encode_pd u_encode_z(
    .clk(tlpclk),
    .rst_n(rst),
    .plus_A(enc_z_A),
    .plus_B(enc_z_B),
    .renew(renew_c),
    .delta_count(delta_z),
    .total_count(count_z)
);

encode_pd_a u_encode_a(
    .clk(tlpclk),
    .rst_n(rst),
    .plus_A(enc_a_A),
    .plus_B(enc_a_B),
    .renew(renew_c),
    .delta_count(delta_a),
    .total_count(count_a)
);


// ================================================
// 卡位置计数模块 - 记录DDA插补产生的脉冲数
// ================================================
pctocard_count u_card_x(
    .clk(tlpclk),
    .rst_n(rst),
    .plus(puls_x_dda),
    .dir(dir_x_dda),
    .renew(renew_c),
    .card_count(card_count_x)
);

pctocard_count u_card_y(
    .clk(tlpclk),
    .rst_n(rst),
    .plus(puls_y_dda),
    .dir(dir_y_dda),
    .renew(renew_c),
    .card_count(card_count_y)
);

pctocard_count u_card_z(
    .clk(tlpclk),
    .rst_n(rst),
    .plus(puls_z_dda),
    .dir(dir_z_dda),
    .renew(renew_c),
    .card_count(card_count_z)
);

pctocard_count u_card_a(
    .clk(tlpclk),
    .rst_n(rst),
    .plus(pa),
    .dir(!da),
    .renew(renew_c),
    .card_count(card_count_a)
);


// ================================================
// DDA插补模块 - 根据指令数据生成各轴脉冲和方向
// ================================================
dda u_dda(
    .clk(tlpclk),
    .valid(valid),
    .data(dda_datain),
    .dir_x(dir_x_dda),
    .dir_y(dir_y_dda),
    .puls_x(puls_x_dda),
    .puls_y(puls_y_dda),
    .dir_z(dir_z_dda),
    .puls_z(puls_z_dda),
    .dir_a(dir_a_dda),
    .puls_a(puls_a_dda)
);


// ================================================
// JOG手动控制模块 - 处理手动按钮产生的连续脉冲
// ================================================
jog u_jog(
    .clk(tlpclk),
    .pos_x(posx_s | pos_x),
    .neg_x(negx_s | neg_x),
    .pos_y(posy_s | pos_y),
    .neg_y(negy_s | neg_y),
    .pos_z(posz_s | pos_z),
    .neg_z(negz_s | neg_z),
    .pos_a(posa_s | pos_a),
    .neg_a(nega_s | neg_a),
    .s1(s1),
    .s2(s2),
    .s3(s3),
    .s4(s4),
    .s5(s5),
    .s6(s6),
    .dir_x(dir_x_jog_jog1),
    .dir_y(dir_y_jog_jog1),
    .dir_z(dir_z_jog_jog1),
    .dir_a(dir_a_jog1),
    .puls_x(puls_x_jog_jog1),
    .puls_y(puls_y_jog_jog1),
    .puls_z(puls_z_jog_jog1),
    .puls_a(puls_a_jog1)
);


// ================================================
// 手轮输入模块 - 处理手轮脉冲，支持多倍率选择
// ================================================
hand_wheel u_hand_wheel(
    .clk_50m(clk_50m),
    .rstn(rst),
    .b_in(hw_Ain),
    .a_in(hw_Bin),
    .i_x1(hw_X1),
    .i_x10(hw_X10),
    .i_x100(hw_X100),
    .i_X(hw_HX),
    .i_Y(hw_HY),
    .i_Z(hw_HZ),
    .i_A(hw_HA),
    .dir_x(dir_x_hw),
    .dir_y(dir_y_hw),
    .dir_z(dir_z_hw),
    .dir_a(dir_a_hw),
    .puls_x(puls_x_hw),
    .puls_y(puls_y_hw),
    .puls_z(puls_z_hw),
    .puls_a(puls_a_hw)
);


// ================================================
// 手轮/JOG选择模块 - 选择手轮或JOG控制源
// ================================================
jog_sel u_jog_sel(
    .clk(tlpclk),
    .hw_valid(hw_valid),
    .dir_x_hw(dir_x_hw),
    .dir_y_hw(dir_y_hw),
    .dir_z_hw(dir_z_hw),
    .dir_a_hw(dir_a_hw),
    .puls_x_hw(puls_x_hw),
    .puls_y_hw(puls_y_hw),
    .puls_z_hw(puls_z_hw),
    .puls_a_hw(puls_a_hw),
    .dir_x_jog(dir_x_jog_jog1),
    .dir_y_jog(dir_y_jog_jog1),
    .dir_z_jog(dir_z_jog_jog1),
    .dir_a_jog(dir_a_jog1),
    .puls_x_jog(puls_x_jog_jog1),
    .puls_y_jog(puls_y_jog_jog1),
    .puls_z_jog(puls_z_jog_jog1),
    .puls_a_jog(puls_a_jog1),
    .dir_x(dir_x_jog_jog),
    .dir_y(dir_y_jog_jog),
    .dir_z(dir_z_jog_jog),
    .dir_a(dir_a_jog),
    .puls_x(puls_x_jog_jog),
    .puls_y(puls_y_jog_jog),
    .puls_z(puls_z_jog_jog),
    .puls_a(puls_a_jog)
);


// ================================================
// 回零选择模块 - 选择回零或JOG运动模式
// ================================================
zero_sel u_zero_sel(
    .clk(tlpclk),
    .szero(key_zero),
    .dir_x_zero(dir_x_jog_zero),
    .dir_y_zero(dir_y_jog_zero),
    .dir_z_zero(dir_z_jog_zero),
    .puls_x_zero(puls_x_jog_zero),
    .puls_y_zero(puls_y_jog_zero),
    .puls_z_zero(puls_z_jog_zero),
    .dir_x_jog(dir_x_jog_jog),
    .dir_y_jog(dir_y_jog_jog),
    .dir_z_jog(dir_z_jog_jog),
    .puls_x_jog(puls_x_jog_jog),
    .puls_y_jog(puls_y_jog_jog),
    .puls_z_jog(puls_z_jog_jog),
    .dir_x(dir_x_jog),
    .dir_y(dir_y_jog),
    .dir_z(dir_z_jog),
    .puls_x(puls_x_jog),
    .puls_y(puls_y_jog),
    .puls_z(puls_z_jog)
);


// ================================================
// 运动选择模块 - 选择DDA插补或手动运动模式
// ================================================
sel_assign u_sel_assign(
    .valid(valid),
    .empty(fifo31_empty),
    .dir_x0(dir_x_jog),
    .dir_x1(dir_x_dda),
    .dir_y0(dir_y_jog),
    .dir_y1(dir_y_dda),
    .dir_z0(dir_z_jog),
    .dir_z1(dir_z_dda),
    .dir_a0(dir_a_jog),
    .dir_a1(dir_a_dda),
    .puls_x0(puls_x_jog),
    .puls_x1(puls_x_dda),
    .puls_y0(puls_y_jog),
    .puls_y1(puls_y_dda),
    .puls_z0(puls_z_jog),
    .puls_z1(puls_z_dda),
    .puls_a0(puls_a_jog),
    .puls_a1(puls_a_dda),
    .datain(fifo33_dataout),
    .dir_x(dx),
    .dir_y(dy),
    .dir_z(dz),
    .dir_a(da),
    .puls_x(px),
    .puls_y(py),
    .puls_z(pz),
    .puls_a(pa),
    .dataout(dda_datain)
);


// ================================================
// 运行状态检测模块 - 检测start/stop信号，控制valid输出
// ================================================
check u_check(
    .clk(tlpclk),
    .start(start),
    .stop(stop),
    .empty(fifo33_empty),
    .valid(valid),
    .s1(s1),
    .s2(s2),
    .s3(s3),
    .s4(s4),
    .s5(s5),
    .s6(s6),
    .s7(z_stop)
);


// ================================================
// 2ms时钟生成模块 - FIFO读使能信号
// ================================================
clk_2ms u_clk_2ms(
    .clk(tlpclk),
    .valid(valid),
    .empty(fifo33_empty),
    .clkout(fifo33_rdreq)
);


// ================================================
// 按钮消抖模块 - set_ref和renew_count按钮
// ================================================
key_hold u_key_set_ref(.clk(tlpclk), .key_in(set_ref), .key_out(key_set_ref));
key_hold u_key_renew(.clk(tlpclk), .key_in(renew_count), .key_out(renew_c));


// ================================================
// 回零控制模块 - X/Y/Z轴自动回零
// ================================================
motor_ctrl_xy u_zero_x(
    .i_clk(clk_40m),
    .i_key_a(key_zero),
    .i_key_b(zero_xdot),
    .i_key_c(s3),
    .z_finished(o_set_z),
    .o_dir(dir_x_jog_zero),
    .o_pluse(puls_x_jog_zero),
    .o_set(o_set_x)
);

motor_ctrl_xy u_zero_y(
    .i_clk(clk_40m),
    .i_key_a(key_zero),
    .i_key_b(zero_ydot),
    .i_key_c(s4),
    .z_finished(o_set_z),
    .o_dir(dir_y_jog_zero),
    .o_pluse(puls_y_jog_zero),
    .o_set(o_set_y)
);

motor_ctrl u_zero_z(
    .i_clk(clk_40m),
    .i_key_a(key_zero),
    .i_key_b(zero_zdot),
    .i_key_c(s5),
    .o_dir(dir_z_jog_zero),
    .o_pluse(puls_z_jog_zero),
    .o_set(o_set_z)
);


// ================================================
// 刀具测量控制模块 - 控制刀具测量器使能
// ================================================
tool_set_ctrl u_tool_set_ctrl(
    .clk(tlpclk),
    .rst_ts(rst),
    .aux_data(aux_ctl),
    .enable_tlset(toolsetter_on)
);


// ================================================
// 刀具换刀控制模块 - 控制换刀机构运动
// ================================================
tool_mag_ctrl u_tool_mag_ctrl(
    .clk(tlpclk),
    .rst_tm(rst),
    .ahe_fin(fwok),
    .back_fin(bwok),
    .rot_count(magcout),
    .loos_fin(looseok),
    .clr_counts(renew_c),
    .aux_data(aux_ctl),
    .enable_tlmag(mag_on),
    .go(mag_fw),
    .back(mag_bw),
    .rot_dir(mag_dir),
    .rot(mag_pul),
    .tool_loos(tool_loose),
    .use_axis8(mag_axis),
    .aux_feedback(aux_fee)
);


// ================================================
// 辅助功能反馈模块 - 收集刀具测量和换刀状态
// ================================================
aux_fbac u_aux_fbac(
    .clk(tlpclk),
    .rst(rst),
    .trigger(toolsetter_trigger),
    .out_range(toolsetter_out),
    .breakdown(1'b1),
    .ahe_fin(fwok),
    .back_fin(bwok),
    .rot_count(magcout),
    .loos_fin(looseok),
    .data(aux_fee),
    .aux_intrupt(z_stop),
    .data_para(aux_back)
);


// ================================================
// 轴信号分配模块 - 根据co1-co8选择输出轴
// ================================================
co_assign u_co_assign(
    .clk(tlpclk),
    .rst(rst),
    .co1(co1), .co2(co2), .co3(co3), .co4(co4),
    .co5(co5), .co6(co6), .co7(co7), .co8(co8),
    .px_in(px), .py_in(py), .pz_in(pz), .pa_in(pa),
    .dx_in(dx), .dy_in(dy), .dz_in(!dz), .da_in(!da),
    .mag_sel(mag_axis),
    .md(mag_dir), .mp(mag_pul),
    .p1(p1), .p2(p2), .p3(p3), .p4(p4),
    .p5(p5), .p6(p6), .p7(p7), .p8(p8),
    .d1(d1), .d2(d2), .d3(d3), .d4(d4),
    .d5(d5), .d6(d6), .d7(d7), .d8(d8)
);


// ================================================
// 信号赋值
// ================================================
assign key_zero = szero_s | szero;
assign downloaded = fifo33_empty;
assign fifo33_alempty = fifo33_alempty_int;

// 换刀反馈信号
assign fwok = mag_fwOK;
assign bwok = mag_bwOK;
assign magcout = mag_count;
assign looseok = tool_looseOK;

endmodule