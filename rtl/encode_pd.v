`timescale 1ns / 1ps

// 编码器脉冲检测模块(X/Y/Z轴)
// 使用异或逻辑检测编码器A/B相信号，实现正反向计数
// 输出增量计数(delta_count)和累计计数(total_count)
// delta_count在1ms周期内更新，total_count持续累加

module encode_pd(
    // 系统信号
    input         clk,           // 时钟信号
    input         rst_n,         // 复位信号(低有效)
    
    // 编码器输入
    input         plus_A,        // 编码器A相信号
    input         plus_B,        // 编码器B相信号
    input         renew,         // 清零信号
    
    // 计数输出
    output reg [31:0] delta_count,  // 增量计数(1ms周期内的脉冲数)
    output reg [31:0] total_count   // 累计计数(总脉冲数)
);

    // 内部寄存器声明
    reg [17:0] clk_cnt;          // 1ms周期计数器
    
    reg [31:0] count_up;         // 正向脉冲计数(1ms周期内)
    reg [31:0] count_down;       // 反向脉冲计数(1ms周期内)
    
    reg [31:0] count_up_t;       // 正向累计计数
    reg [31:0] count_down_t;     // 反向累计计数
    
    reg dir_reg;                 // 方向寄存器
    reg signal_C;                // A^B异或结果
    reg signal_D;                // signal_C延时一拍
    
    reg count_plus;              // 计数脉冲标志
    
    reg plus_A_tt;               // A相延时两拍
    reg plus_A_t;                // A相延时一拍
    reg plus_B_t;                // B相延时一拍
    
    reg delta_flag;              // 1ms周期标志
    reg delta_flag_tt;           // delta_flag延时两拍
    reg delta_flag_t;            // delta_flag延时一拍
    wire delta_pos;              // delta_flag上升沿
    
    // delta_flag上升沿检测
    assign delta_pos = (!delta_flag_tt & delta_flag_t);

    //------------------------------------------------------------------------
    // 1ms周期计数器(125MHz时钟下计数到99999)
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 1'b0;
        end else if (clk_cnt == 'd99999) begin
            clk_cnt <= 1'b0;
        end else begin
            clk_cnt <= clk_cnt + 1'b1;
        end
    end

    //------------------------------------------------------------------------
    // 1ms周期标志生成
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            delta_flag <= 1'b0;
        end else if (clk_cnt == 'd99999) begin
            delta_flag <= 1'b1;
        end else begin
            delta_flag <= 1'b0;
        end
    end

    //------------------------------------------------------------------------
    // delta_flag延时寄存器(用于上升沿检测)
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            delta_flag_t  <= 1'b0;
            delta_flag_tt <= 1'b0;
        end else begin
            delta_flag_t  <= delta_flag;
            delta_flag_tt <= delta_flag_t;
        end
    end

    //------------------------------------------------------------------------
    // 编码器A/B相异或逻辑
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_C <= 1'b0;
        end else begin
            signal_C <= plus_A ^ plus_B;  // 异或运算
        end
    end

    //------------------------------------------------------------------------
    // signal_C延时一拍
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_D <= 1'b0;
        end else begin
            signal_D <= signal_C;
        end
    end

    //------------------------------------------------------------------------
    // 计数脉冲生成：检测signal_C变化
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_plus <= 1'b0;
        end else begin
            count_plus <= signal_C ^ signal_D;
        end
    end

    //------------------------------------------------------------------------
    // A相信号延时寄存器(用于方向判断)
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            plus_A_tt <= 1'b0;
            plus_A_t  <= 1'b0;
        end else if (count_plus == 1'b1) begin
            plus_A_t  <= plus_A;
            plus_A_tt <= plus_A_t;
        end else begin
            plus_A_t  <= plus_A_t;
            plus_A_tt <= plus_A_tt;
        end
    end

    //------------------------------------------------------------------------
    // B相信号延时寄存器(用于方向判断)
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            plus_B_t <= 1'b0;
        end else if (count_plus == 1'b1) begin
            plus_B_t <= plus_B;
        end else begin
            plus_B_t <= plus_B_t;
        end
    end

    //------------------------------------------------------------------------
    // 方向判断：根据A/B相异或结果判断旋转方向
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dir_reg <= 1'b0;
        end else begin
            dir_reg <= plus_A_tt ^ plus_B_t;
        end
    end

    //------------------------------------------------------------------------
    // 正向脉冲计数(1ms周期内)
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_up <= 'd0;
        end else if (renew == 1'b1) begin
            count_up <= 'd0;
        end else if (delta_pos == 1'b1) begin
            count_up <= 'd0;
        end else if (dir_reg == 1'b0 && count_plus == 1'b1) begin
            count_up <= count_up + 1'b1;
        end else begin
            count_up <= count_up;
        end
    end

    //------------------------------------------------------------------------
    // 反向脉冲计数(1ms周期内)
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_down <= 'd0;
        end else if (renew == 1'b1) begin
            count_down <= 'd0;
        end else if (delta_pos == 1'b1) begin
            count_down <= 'd0;
        end else if (dir_reg == 1'b1 && count_plus == 1'b1) begin
            count_down <= count_down + 1'b1;
        end else begin
            count_down <= count_down;
        end
    end

    //------------------------------------------------------------------------
    // 正向累计计数
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_up_t <= 'd0;
        end else if (renew == 1'b1) begin
            count_up_t <= 'd0;
        end else if (dir_reg == 1'b0 && count_plus == 1'b1) begin
            count_up_t <= count_up_t + 1'b1;
        end else begin
            count_up_t <= count_up_t;
        end
    end

    //------------------------------------------------------------------------
    // 反向累计计数
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_down_t <= 'd0;
        end else if (renew == 1'b1) begin
            count_down_t <= 'd0;
        end else if (dir_reg == 1'b1 && count_plus == 1'b1) begin
            count_down_t <= count_down_t + 1'b1;
        end else begin
            count_down_t <= count_down_t;
        end
    end

    //------------------------------------------------------------------------
    // 增量计数输出(1ms周期内的脉冲数)
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            delta_count <= 'd0;
        end else if (delta_flag == 1'b1) begin
            delta_count <= count_up + count_down;
        end else begin
            delta_count <= delta_count;
        end
    end

    //------------------------------------------------------------------------
    // 累计计数输出(总脉冲数)
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_count <= 'd0;
        end else if (delta_flag == 1'b1) begin
            total_count <= count_up_t + count_down_t;
        end else begin
            total_count <= total_count;
        end
    end

endmodule