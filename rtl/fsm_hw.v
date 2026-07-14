`timescale 1ns / 1ps

// 手轮状态机模块
// 对手轮A/B相信号进行鉴相和周期测量
// 将测量结果写入FIFO，供后续倍频模块使用

module fsm_hw(
    // 系统信号
    input         clk,          // 时钟信号
    input         rstn,         // 复位信号(低有效)

    // 输入信号
    input         a_in,         // 滤波后A相信号
    input         b_in,         // 滤波后B相信号
    input         full,         // FIFO满标志

    // 输出信号
    output reg        wrreq,        // FIFO写请求
    output reg        dir_out,      // 方向输出
    output reg [21:0] data          // 周期测量数据输出
);

    // 内部寄存器声明
    reg a0, a1;                // A相延时寄存器
    reg b0, b1;                // B相延时寄存器
    reg deal_sign;             // 信号变化标志
    reg S_timer;               // 超时标志
    reg [21:0] t0;             // 周期计数器

    // 状态机状态定义
    parameter [1:0] M0 = 2'b00;  // 空闲状态
    parameter [1:0] M1 = 2'b01;  // 周期测量状态
    parameter [1:0] M2 = 2'b10;  // 数据写入状态

    reg [1:0] curr_state_M;    // 当前状态
    reg [1:0] next_state_M;    // 下一状态

    //------------------------------------------------------------------------
    // A/B相信号延时处理(用于边缘检测)
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            a0 <= 1'b0; a1 <= 1'b0;
            b0 <= 1'b0; b1 <= 1'b0;
        end else begin
            a0 <= a_in; a1 <= a0;
            b0 <= b_in; b1 <= b0;
        end
    end

    //------------------------------------------------------------------------
    // 信号变化检测：异或运算提取信号边缘
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            deal_sign <= 1'b0;
        end else begin
            deal_sign <= (a1 ^ a0) | (b1 ^ b0);
        end
    end

    //------------------------------------------------------------------------
    // 脉冲鉴相：根据A相上升沿时B相的状态判断方向
    //------------------------------------------------------------------------
    always @(posedge a1 or negedge rstn) begin
        if (!rstn) begin
            dir_out <= 1'b0;
        end else begin
            if (b1 == 1'b0) begin
                dir_out <= 1'b0;      // 正方向
            end else if (b1 == 1'b1) begin
                dir_out <= 1'b1;      // 反方向
            end else begin
                dir_out <= dir_out;
            end
        end
    end

    //------------------------------------------------------------------------
    // 状态机状态寄存器
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            curr_state_M <= M0;
        end else begin
            curr_state_M <= next_state_M;
        end
    end

    //------------------------------------------------------------------------
    // 状态机下一状态判断
    //------------------------------------------------------------------------
    always @(*) begin
        case (curr_state_M)
            M0: begin
                if (!deal_sign) begin
                    next_state_M <= M0;
                end else begin
                    next_state_M <= M1;
                end
            end
            M1: begin
                if (S_timer == 1'b0 && deal_sign == 1'b0) begin
                    next_state_M <= M1;
                end else if (S_timer == 1'b1 && deal_sign == 1'b0) begin
                    next_state_M <= M0;  // 超时，回到空闲状态
                end else begin
                    next_state_M <= M2;  // 检测到信号变化，进入写入状态
                end
            end
            M2: begin
                if (deal_sign == 1'b0) begin
                    next_state_M <= M1;  // 信号稳定，回到测量状态
                end else begin
                    next_state_M <= M2;  // 继续保持写入状态
                end
            end
            default: begin
                next_state_M <= M0;
            end
        endcase
    end

    //------------------------------------------------------------------------
    // 状态机输出逻辑
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            t0 <= 22'h0;
            S_timer <= 1'b0;
            data <= 22'h0;
            wrreq <= 1'b0;
        end else begin
            case (next_state_M)
                M0: begin
                    t0 <= 22'h0;
                    S_timer <= 1'b0;
                    data <= 22'h0;
                    wrreq <= 1'b0;
                end
                M1: begin
                    data <= t0;
                    wrreq <= 1'b0;
                    if (t0 >= 22'h2625a0) begin  // 约10ms超时(50MHz)
                        S_timer <= 1'b1;
                        t0 <= t0;
                    end else begin
                        S_timer <= 1'b0;
                        t0 <= t0 + 22'h1;
                    end
                end
                M2: begin
                    if (full != 1'b1) begin
                        wrreq <= 1'b1;
                        data <= t0;
                        t0 <= 22'h0;
                        S_timer <= 1'b0;
                    end else begin
                        wrreq <= 1'b0;
                        data <= 22'h0;
                        t0 <= 22'h0;
                        S_timer <= 1'b0;
                    end
                end
                default: begin
                    t0 <= 22'h0;
                    S_timer <= 1'b0;
                    data <= 22'h0;
                    wrreq <= 1'b0;
                end
            endcase
        end
    end

endmodule