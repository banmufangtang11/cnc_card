`timescale 1ns / 1ps

// 手轮控制模块
// 对手轮A/B相信号进行滤波、鉴相和倍频处理
// 根据倍率选择(X1/X10/X100)和轴选择(X/Y/Z/A)输出对应的脉冲和方向信号

module hand_wheel(
    // 系统信号
    input         clk_50m,      // 50MHz时钟信号
    input         rstn,         // 复位信号(低有效)
    
    // 手轮输入
    input         b_in,         // 手轮B相信号
    input         a_in,         // 手轮A相信号
    input         i_x1,         // X1倍率选择
    input         i_x10,        // X10倍率选择
    input         i_x100,       // X100倍率选择
    input         i_X,          // X轴选择
    input         i_Y,          // Y轴选择
    input         i_Z,          // Z轴选择
    input         i_A,          // A轴选择
    
    // 输出信号
    output        dir_x,        // X轴方向
    output        dir_y,        // Y轴方向
    output        dir_z,        // Z轴方向
    output        dir_a,        // A轴方向
    output        puls_x,       // X轴脉冲
    output        puls_y,       // Y轴脉冲
    output        puls_z,       // Z轴脉冲
    output        puls_a        // A轴脉冲
);

    // 内部信号声明
    wire A_in1;                 // 滤波后A相
    wire B_in1;                 // 滤波后B相
    wire clk;                   // 时钟(50MHz)
    wire dir_out;               // 手轮方向输出
    wire empty;                 // FIFO空标志
    wire full;                  // FIFO满标志
    wire puls_out;              // 手轮脉冲输出
    wire rdreq;                 // FIFO读请求
    wire rst;                   // 复位(高有效)
    wire SYNTHESIZED_WIRE_0;    // FIFO写请求
    wire [21:0] SYNTHESIZED_WIRE_1;  // FIFO写入数据
    wire [21:0] SYNTHESIZED_WIRE_2;  // FIFO读出数据

    // 复位转换：低有效→高有效
    assign rst = ~rstn;
    // 时钟赋值
    assign clk = clk_50m;

    //------------------------------------------------------------------------
    // FIFO模块：缓存手轮周期测量数据
    //------------------------------------------------------------------------
    queue b2v_inst(
        .wrreq(SYNTHESIZED_WIRE_0),
        .rdreq(rdreq),
        .clock(clk),
        .sclr(rst),
        .data(SYNTHESIZED_WIRE_1),
        
        .full(full),
        .empty(empty),
        .q(SYNTHESIZED_WIRE_2)
    );

    //------------------------------------------------------------------------
    // 手轮脉冲倍频模块：根据倍率生成脉冲序列
    //------------------------------------------------------------------------
    puls_hw b2v_inst1(
        .clk(clk),
        .rstn(rstn),
        .empty(empty),
        .i_x1(i_x1),
        .i_x10(i_x10),
        .i_x100(i_x100),
        .q(SYNTHESIZED_WIRE_2),
        
        .rdreq(rdreq),
        .puls_out(puls_out)
    );
    defparam b2v_inst1.F0 = 3'b011;
    defparam b2v_inst1.F1 = 3'b100;
    defparam b2v_inst1.F2 = 3'b101;
    defparam b2v_inst1.F3 = 3'b110;

    //------------------------------------------------------------------------
    // 手轮状态机模块：鉴相和周期测量
    //------------------------------------------------------------------------
    fsm_hw b2v_inst2(
        .clk(clk),
        .rstn(rstn),
        .a_in(A_in1),
        .b_in(B_in1),
        .full(full),
        
        .wrreq(SYNTHESIZED_WIRE_0),
        .dir_out(dir_out),
        .data(SYNTHESIZED_WIRE_1)
    );
    defparam b2v_inst2.M0 = 2'b00;
    defparam b2v_inst2.M1 = 2'b01;
    defparam b2v_inst2.M2 = 2'b10;

    //------------------------------------------------------------------------
    // 轴选择模块：根据轴选择信号分配脉冲和方向
    //------------------------------------------------------------------------
    axis_sel b2v_inst3(
        .clk(clk),
        .rstn(rstn),
        .i_X(i_X),
        .i_Y(i_Y),
        .i_Z(i_Z),
        .i_A(i_A),
        .p(puls_out),
        .dir_in(dir_out),
        
        .dir_x(dir_x),
        .dir_y(dir_y),
        .dir_z(dir_z),
        .dir_a(dir_a),
        .puls_x(puls_x),
        .puls_y(puls_y),
        .puls_z(puls_z),
        .puls_a(puls_a)
    );

    //------------------------------------------------------------------------
    // 编码器信号滤波：B相
    //------------------------------------------------------------------------
    filter_encode b2v_inst5(
        .clk(clk),
        .rst_n(rstn),
        .puls(b_in),
        
        .filter(A_in1)
    );

    //------------------------------------------------------------------------
    // 编码器信号滤波：A相
    //------------------------------------------------------------------------
    filter_encode b2v_inst6(
        .clk(clk),
        .rst_n(rstn),
        .puls(a_in),
        
        .filter(B_in1)
    );

endmodule