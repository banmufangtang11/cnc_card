`timescale 1ns / 1ps

// 手轮脉冲倍频模块
// 根据倍率选择(X1/X10/X100)对FIFO中的周期数据进行倍频处理
// 生成相应的脉冲序列输出

module puls_hw(
    // 系统信号
    input         clk,          // 时钟信号
    input         rstn,         // 复位信号(低有效)

    // 输入信号
    input         empty,        // FIFO空标志
    input  [21:0] q,            // FIFO读出数据
    input         i_x1,         // X1倍率选择(低有效)
    input         i_x10,        // X10倍率选择(低有效)
    input         i_x100,       // X100倍率选择(低有效)

    // 输出信号
    output reg    rdreq,        // FIFO读请求
    output reg    puls_out      // 倍频脉冲输出
);

    // 状态机状态定义
    parameter [2:0] F0 = 3'b011;  // 空闲状态
    parameter [2:0] F1 = 3'b100;  // 读取数据状态
    parameter [2:0] F2 = 3'b101;  // 计数状态
    parameter [2:0] F3 = 3'b110;  // 脉冲输出状态

    // 内部寄存器声明
    reg [2:0] curr_state_F;     // 当前状态
    reg [2:0] next_state_F;     // 下一状态
    reg F_timer;                // 计数完成标志
    reg [7:0] c0;               // 倍率系数
    reg [7:0] c1;               // 当前倍频计数
    reg [21:0] sum;             // 累加计数器
    reg p;                      // 内部脉冲信号
    reg [21:0] q_out;           // 输出周期数据
    reg [21:0] q_in;            // 输入周期数据
    reg q_sign;                 // 数据有效标志
    reg [6:0] count1, count2, count3;  // 消抖计数器
    reg flag1, flag2, flag3;     // 倍率选择标志(消抖后)

    //------------------------------------------------------------------------
    // 数据有效判断
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            q_sign <= 1'b0;
        end else begin
            if (q_in == 22'h0) begin
                q_sign <= 1'b0;
            end else begin
                q_sign <= 1'b1;
            end
        end
    end

    //------------------------------------------------------------------------
    // X1倍率选择消抖
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rstn) begin
            flag1 <= 1'b0;
            count1 <= 7'h0;
        end else begin
            if (!i_x1) begin
                if (count1 == 7'h7d) begin  // 消抖延时约1us(50MHz)
                    flag1 <= 1'b1;
                    count1 <= 7'h0;
                end else begin
                    flag1 <= flag1;
                    count1 <= count1 + 7'h1;
                end
            end else begin
                flag1 <= 1'b0;
                count1 <= 7'h0;
            end
        end
    end

    //------------------------------------------------------------------------
    // X10倍率选择消抖
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rstn) begin
            flag2 <= 1'b0;
            count2 <= 7'h0;
        end else begin
            if (!i_x10) begin
                if (count2 == 7'h7d) begin
                    flag2 <= 1'b1;
                    count2 <= 7'h0;
                end else begin
                    flag2 <= flag2;
                    count2 <= count2 + 7'h1;
                end
            end else begin
                flag2 <= 1'b0;
                count2 <= 7'h0;
            end
        end
    end

    //------------------------------------------------------------------------
    // X100倍率选择消抖
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rstn) begin
            flag3 <= 1'b0;
            count3 <= 7'h0;
        end else begin
            if (!i_x100) begin
                if (count3 == 7'h7d) begin
                    flag3 <= 1'b1;
                    count3 <= 7'h0;
                end else begin
                    flag3 <= flag3;
                    count3 <= count3 + 7'h1;
                end
            end else begin
                flag3 <= 1'b0;
                count3 <= 7'h0;
            end
        end
    end

    //------------------------------------------------------------------------
    // 倍率系数选择
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            c0 <= 8'h0;
        end else begin
            if (flag1) begin
                c0 <= 8'h2;   // X1: 倍率系数=2
            end else if (flag2) begin
                c0 <= 8'hc;   // X10: 倍率系数=12
            end else if (flag3) begin
                c0 <= 8'h20;  // X100: 倍率系数=32
            end else begin
                c0 <= 8'h0;
            end
        end
    end

    //------------------------------------------------------------------------
    // 脉冲输出赋值
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            puls_out <= 1'b0;
        end else begin
            puls_out <= p;
        end
    end

    //------------------------------------------------------------------------
    // 状态机状态寄存器
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            curr_state_F <= F0;
        end else begin
            curr_state_F <= next_state_F;
        end
    end

    //------------------------------------------------------------------------
    // 状态机下一状态判断
    //------------------------------------------------------------------------
    always @(*) begin
        case (curr_state_F)
            F0: begin
                if (empty) begin
                    next_state_F <= F0;
                end else begin
                    next_state_F <= F1;
                end
            end
            F1: begin
                if (q_sign) begin
                    next_state_F <= F2;
                end else begin
                    next_state_F <= F1;
                end
            end
            F2: begin
                if (F_timer == 1'b1) begin
                    next_state_F <= F3;
                end else begin
                    next_state_F <= F2;
                end
            end
            F3: begin
                if (c1 == c0 && empty == 1'b1) begin
                    next_state_F <= F0;
                end else if (c1 == c0 && empty == 1'b0) begin
                    next_state_F <= F1;
                end else begin
                    next_state_F <= F2;
                end
            end
            default: begin
                next_state_F <= F0;
            end
        endcase
    end

    //------------------------------------------------------------------------
    // 状态机输出逻辑
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            c1 <= 8'h0;
            F_timer <= 1'b0;
            sum <= 22'h0;
            rdreq <= 1'b0;
            p <= 1'b0;
            q_out <= 22'h0;
            q_in <= 22'h0;
        end else begin
            case (next_state_F)
                F0: begin
                    c1 <= 8'h0;
                    F_timer <= 1'b0;
                    sum <= 22'h0;
                    rdreq <= 1'b0;
                    p <= 1'b0;
                    q_out <= 22'h0;
                    q_in <= 22'h0;
                end
                F1: begin
                    c1 <= 8'h0;
                    sum <= 22'h0;
                    p <= 1'b0;
                    q_out <= q_in;
                    q_in <= q / c0;
                    rdreq <= 1'b1;
                    F_timer <= 1'b0;
                end
                F2: begin
                    q_out <= q_in;
                    rdreq <= 1'b0;
                    c1 <= c1;
                    p <= p;
                    q_in <= q_in;
                    if (sum >= q_out) begin
                        F_timer <= 1'b0;
                        sum <= 22'h0;
                    end else if (sum >= q_out / 2 && sum < q_out) begin
                        F_timer <= 1'b1;
                        sum <= sum + c0;
                    end else begin
                        F_timer <= 1'b0;
                        sum <= sum + c0;
                    end
                end
                F3: begin
                    p <= ~p;
                    c1 <= c1 + 8'h1;
                    rdreq <= 1'b0;
                    q_out <= q_out;
                    F_timer <= 1'b0;
                    sum <= 22'h0;
                    q_in <= q_in;
                end
                default: begin
                    c1 <= 8'h0;
                    F_timer <= 1'b0;
                    sum <= 22'h0;
                    rdreq <= 1'b0;
                    p <= 1'b0;
                    q_out <= 1'b0;
                    q_in <= 22'h0;
                end
            endcase
        end
    end

endmodule