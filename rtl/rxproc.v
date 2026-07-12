`timescale 1ns / 1ps

// 模块功能：PCIe RX 数据包处理模块
// 负责从 FIFO 读取 RX 数据，解析 TLP 头部，识别 TLP 类型（内存读/写、IO读/写、配置读/写、CPLD等）
// 根据 TLP 类型执行相应操作：内存写直接写入外部接口，内存读生成 DMA 请求，CPLD 数据写入 DMA 读 FIFO

module rxproc (
    input clk,  // 时钟信号
    input rst,  // 复位信号（低有效）

    // FIFO 接口输入信号（来自 rsstinf 模块）
    input        fifoempty,    // FIFO 空标志
    input        fifoalempty,  // FIFO 半空标志
    input [ 9:0] rxdw,         // FIFO 中数据深度（剩余字数）
    input [95:0] rxdq,         // 96 位 FIFO 数据（包含 RX 数据和控制信号）

    // 外部接口地址和片选信号
    output     [21:0] ext_add,  // 外部接口地址（22位）
    output            iosel,    // IO 空间选择（未使用，固定为0）
    output reg        memsel1,  // 内存空间片选1
    output reg        memsel2,  // 内存空间片选2

    // 外部接口双向数据总线
    inout [31:0] extdq,  // 32位外部数据总线

    // 外部接口控制信号
    output ext_rd,  // 外部读使能
    output ext_wr,  // 外部写使能
    output fiford,  // FIFO 读使能
    output led0,    // LED0 指示（CPLD 数据接收）
    output led1,    // LED1 指示（CPL 包）
    output led2,    // LED2 指示（CPL 包）
    output led3,    // LED3 指示（未使用）

    // DMA 读请求信号（发送到 txproc 模块）
    output [ 7:0] tag,      // TLP 标签（用于 CPL 匹配）
    output [15:0] reqid,    // 请求者 ID
    output        memrdrq,  // 内存读请求
    output [ 1:0] attrib,   // 属性字段
    output [ 2:0] tc,       // 流量类别

    // 外部接口反馈信号
    input extdfer,  // 外部写完成标志
    input memrdack, // 内存读完成标志

    // DMA 读 FIFO 接口（输出到 txproc 模块）
    output        dmardfifowr,  // DMA 读 FIFO 写使能
    output [63:0] dmardfifodq,  // DMA 读 FIFO 数据
    input  [ 8:0] dmardfifodw   // DMA 读 FIFO 深度
);

    // 状态机状态定义（RX 数据包处理状态）
    localparam IDLE = 0;  // 空闲状态，等待 SOP
    localparam RDHEAD1 = 1;  // 读取 TLP 头部第一拍（64位）
    localparam HEADPRO1 = 2;  // 处理 TLP 头部第一拍
    localparam RDHEAD2 = 3;  // 读取 TLP 头部第二拍（地址等）
    localparam HEADPRO2 = 4;  // 处理 TLP 头部第二拍
    localparam WAITST1 = 5;  // 等待状态，根据 TLP 类型跳转
    localparam DATAST1 = 6;  // 数据处理状态1（读取数据）
    localparam DATAST2 = 7;  // 数据处理状态2（准备写入）
    localparam MEMWRST1 = 8;  // 内存写状态1
    localparam MEMWRST2 = 9;  // 内存写状态2（发出写使能）
    localparam MEMWRST3 = 10;  // 内存写状态3（等待写完成）
    localparam MEMWRST4 = 11;  // 内存写状态4（完成）
    localparam UNSP1 = 12;  // 未支持 TLP 处理状态1
    localparam UNSP2 = 13;  // 未支持 TLP 处理状态2
    localparam MEMRDST1 = 14;  // 内存读状态1
    localparam MEMRDST2 = 15;  // 内存读状态2（发出读使能）
    localparam MEMRDST3 = 16;  // 内存读状态3（等待读完成）
    localparam MEMRDST4 = 17;  // 内存读状态4（完成）
    localparam CPLDWAITST1 = 18;  // CPLD（Completion with Data）等待状态1
    localparam CPLDDATAST1 = 19;  // CPLD 数据处理状态（写入 DMA 读 FIFO）
    localparam CPLDWAITST6 = 20;  // CPLD 等待状态6（FIFO 满时等待）
    localparam CPLDWAITST7 = 21;  // CPLD 等待状态7
    localparam CPLDWAITST8 = 22;  // CPLD 等待状态8
    localparam CPLDWAITST9 = 23;  // CPLD 等待状态9（等待 FIFO 有空间）

    // 状态机寄存器
    reg [ 4:0] pre_state;  // 当前状态
    reg [ 4:0] nxt_state;  // 下一状态

    // RX 数据寄存器
    reg [63:0] rxdata;  // 当前读取的 RX 数据（64位）
    reg [63:0] headrega;  // TLP 头部第一拍寄存器（包含 fmt/ty/tag/reqid 等）
    reg [63:0] headregb;  // TLP 头部第二拍寄存器（包含地址等）
    reg [ 7:0] rxbe;  // 字节使能（来自 FIFO [71:64]）
    reg [ 7:0] rxbardec;  // 地址解码（来自 FIFO [79:72]）
    reg        rxvalid;  // 数据有效标志（来自 FIFO [80]）
    reg        rxerr;  // 错误标志（来自 FIFO [81]）
    reg        rxsop;  // 包开始标志（来自 FIFO [82]）
    reg        rxeop;  // 包结束标志（来自 FIFO [83]）

    // TLP 头部解析信号
    reg        td;  // TD（Type/Data）位
    reg        ep;  // EP（End Pointer）位
    reg        dw3sel;  // 3DW/4DW 头部选择（fmt[0]）
    reg        rxen;  // RX 使能（FIFO 深度 >= 2）
    reg        tlpover;  // TLP 处理完成标志
    reg        dqoen;  // 外部数据总线输出使能
    reg [ 1:0] fmt;  // TLP 格式字段（fmt[1:0]）
    reg [ 4:0] tysel;  // TLP 类型字段（type[4:0]）
    reg [ 9:0] lenth;  // TLP 长度字段
    reg [ 9:0] dwlength;  // 双字长度（用于 CPLD 数据计数）
    reg [ 3:0] fbe;  // 首个双字字节使能（FBE）
    reg [31:0] addr;  // TLP 地址字段
    reg [31:0] extdqreg;  // 外部数据总线输出寄存器

    // TLP 类型选择信号
    reg        memrdsel;  // 内存读 TLP 选择
    reg        memwrsel;  // 内存写 TLP 选择
    reg        iordsel;  // IO 读 TLP 选择
    reg        iowrsel;  // IO 写 TLP 选择
    reg        cfgrdsel;  // 配置读 TLP 选择
    reg        cfgwrsel;  // 配置写 TLP 选择
    reg        messrdsel;  // 消息读 TLP 选择
    reg        messwrsel;  // 消息写 TLP 选择
    reg        cplsel;  // Completion TLP 选择
    reg        cpldsel;  // Completion with Data TLP 选择

    // LED 寄存器
    reg        led0_reg;  // LED0 状态寄存器（CPLD 数据接收指示）

    // 输出赋值：地址、TLP 头部字段
    assign ext_add     = {addr[21:2], 2'b00};  // 外部地址（低2位对齐为0）
    assign tag         = headrega[47:40];  // TLP 标签（用于 CPL 匹配）
    assign reqid       = headrega[63:48];  // 请求者 ID
    assign attrib      = headrega[13:12];  // 属性字段
    assign tc          = headrega[21:19];  // 流量类别

    // DMA 读 FIFO 数据输出
    assign dmardfifodq = rxdata;  // CPLD 数据直接输出到 DMA 读 FIFO

    // 外部数据总线（三态输出）
    assign extdq       = (dqoen == 1'b1) ? extdqreg : 32'hZZZZZZZZ;

    // FIFO 数据解析（96位 → 分离控制信号和数据）
    always @(posedge clk) begin
        rxdata   <= rxdq[63:0];
        rxbe     <= rxdq[71:64];
        rxbardec <= rxdq[79:72];
        rxvalid  <= rxdq[80];
        rxerr    <= rxdq[81];
        rxsop    <= rxdq[82];
        rxeop    <= rxdq[83];
    end

    // LED0 控制：CPLD 数据接收时点亮
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            led0_reg <= 1'b0;
        end else if (cpldsel == 1'b1) begin
            led0_reg <= 1'b1;
        end
    end

    // TLP 头部第一拍寄存器（包含 fmt/ty/tag/reqid 等）
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            headrega <= 64'hFFFFFFFFFFFFFFFF;
        end else if (pre_state == RDHEAD1) begin
            headrega <= rxdata;
        end
    end

    // 双字长度计数器（用于 CPLD 数据计数）
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            dwlength <= 10'h000;
        end else if (pre_state == RDHEAD1) begin
            dwlength <= rxdata[9:0];
        end else if (pre_state == CPLDDATAST1) begin
            dwlength[9:1] <= dwlength[9:1] - 1;
        end
    end

    // TLP 头部第二拍寄存器（包含地址等）
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            headregb <= 64'h0000000000000000;
        end else if (pre_state == RDHEAD2) begin
            headregb <= rxdata;
        end
    end

    // TLP 类型解码（组合逻辑）
    always @(*) begin
        // 内存读 TLP：type[4:0]=00000/00001, fmt[1]=0
        if ((headrega[28:24] == 5'b00000 || headrega[28:24] == 5'b00001) && headrega[30] == 1'b0) begin
            memrdsel = 1'b1;
        end else begin
            memrdsel = 1'b0;
        end

        // 内存写 TLP：type[4:0]=00000, fmt[1]=1
        if (headrega[28:24] == 5'b00000 && headrega[30] == 1'b1) begin
            memwrsel = 1'b1;
        end else begin
            memwrsel = 1'b0;
        end

        // IO 读 TLP：type[4:0]=00010, fmt[1]=0
        if (headrega[28:24] == 5'b00010 && headrega[30] == 1'b0) begin
            iordsel = 1'b1;
        end else begin
            iordsel = 1'b0;
        end

        // IO 写 TLP：type[4:0]=00010, fmt[1]=1
        if (headrega[28:24] == 5'b00010 && headrega[30] == 1'b1) begin
            iowrsel = 1'b1;
        end else begin
            iowrsel = 1'b0;
        end

        // 配置读 TLP：type[4:0]=00100/00101, fmt[1]=0
        if ((headrega[28:24] == 5'b00100 || headrega[28:24] == 5'b00101) && headrega[30] == 1'b0) begin
            cfgrdsel = 1'b1;
        end else begin
            cfgrdsel = 1'b0;
        end

        // 配置写 TLP：type[4:0]=00100/00101, fmt[1]=1
        if ((headrega[28:24] == 5'b00100 || headrega[28:24] == 5'b00101) && headrega[30] == 1'b1) begin
            cfgwrsel = 1'b1;
        end else begin
            cfgwrsel = 1'b0;
        end

        // 消息读 TLP：type[4:3]=10, fmt[1]=0
        if (headrega[28:27] == 2'b10 && headrega[30] == 1'b0) begin
            messrdsel = 1'b1;
        end else begin
            messrdsel = 1'b0;
        end

        // 消息写 TLP：type[4:3]=10, fmt[1]=1
        if (headrega[28:27] == 2'b10 && headrega[30] == 1'b1) begin
            messwrsel = 1'b1;
        end else begin
            messwrsel = 1'b0;
        end

        // Completion TLP（无数据）：type[4:0]=01010/01011, fmt[1]=0
        if ((headrega[28:24] == 5'b01010 || headrega[28:24] == 5'b01011) && headrega[30] == 1'b0) begin
            cplsel = 1'b1;
        end else begin
            cplsel = 1'b0;
        end

        // Completion with Data TLP：type[4:0]=01010/01011, fmt[1]=1, TC=000
        if ((headrega[28:24] == 5'b01010 || headrega[28:24] == 5'b01011) && headrega[30] == 1'b1 && headrega[47:45] == 3'b000) begin
            cpldsel = 1'b1;
        end else begin
            cpldsel = 1'b0;
        end

        // 3DW/4DW 头部选择：fmt[0]=0 为 3DW
        if (headrega[29] == 1'b0) begin
            dw3sel = 1'b1;
        end else begin
            dw3sel = 1'b0;
        end

        // RX 使能：FIFO 中至少有2个字
        if (rxdw >= 10'h002) begin
            rxen = 1'b1;
        end else begin
            rxen = 1'b0;
        end

        // TLP 处理完成：IO读、配置读、消息读、CPL 无需数据处理
        if (iordsel == 1'b1 || cfgrdsel == 1'b1 || messrdsel == 1'b1 || cplsel == 1'b1) begin
            tlpover = 1'b1;
        end else begin
            tlpover = 1'b0;
        end
    end

    // 地址提取：根据 3DW/4DW 头部格式选择不同的地址位置
    always @(posedge clk) begin
        if (dw3sel == 1'b1) begin
            addr[7:2]   <= headregb[7:2];
            addr[15:8]  <= headregb[15:8];
            addr[23:16] <= headregb[23:16];
            addr[31:24] <= headregb[31:24];
        end else begin
            addr[7:2]   <= headregb[39:34];
            addr[15:8]  <= headregb[47:40];
            addr[23:16] <= headregb[55:48];
            addr[31:24] <= headregb[63:56];
        end
        addr[1:0] <= 2'b00;
    end

    // 状态机转移逻辑
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            pre_state <= IDLE;
        end else begin
            case (pre_state)
                IDLE: begin
                    if (rxen == 1'b1 && rxsop == 1'b1) begin
                        pre_state <= RDHEAD1;
                    end else begin
                        pre_state <= IDLE;
                    end
                end
                RDHEAD1: begin
                    pre_state <= HEADPRO1;
                end
                HEADPRO1: begin
                    pre_state <= RDHEAD2;
                end
                RDHEAD2: begin
                    pre_state <= HEADPRO2;
                end
                HEADPRO2: begin
                    pre_state <= WAITST1;
                end
                WAITST1: begin
                    if (memwrsel == 1'b1 && addr[2] == 1'b1 && dw3sel == 1'b1) begin
                        pre_state <= DATAST2;
                    end else if (memwrsel == 1'b1) begin
                        pre_state <= DATAST1;
                    end else if (memrdsel == 1'b1) begin
                        pre_state <= MEMRDST1;
                    end else if (cpldsel == 1'b1) begin
                        pre_state <= CPLDWAITST1;
                    end else begin
                        pre_state <= UNSP1;
                    end
                end
                UNSP1: begin
                    if (rxeop == 1'b1) begin
                        pre_state <= IDLE;
                    end else begin
                        pre_state <= UNSP2;
                    end
                end
                UNSP2: begin
                    pre_state <= UNSP1;
                end
                DATAST1: begin
                    pre_state <= DATAST2;
                end
                DATAST2: begin
                    pre_state <= MEMWRST1;
                end
                MEMWRST1: begin
                    pre_state <= MEMWRST2;
                end
                MEMWRST2: begin
                    pre_state <= MEMWRST3;
                end
                MEMWRST3: begin
                    if (extdfer == 1'b1) begin
                        pre_state <= MEMWRST4;
                    end else begin
                        pre_state <= MEMWRST3;
                    end
                end
                MEMWRST4: begin
                    pre_state <= UNSP1;
                end
                MEMRDST1: begin
                    pre_state <= MEMRDST2;
                end
                MEMRDST2: begin
                    pre_state <= MEMRDST3;
                end
                MEMRDST3: begin
                    if (memrdack == 1'b1) begin
                        pre_state <= MEMRDST4;
                    end else begin
                        pre_state <= MEMRDST3;
                    end
                end
                MEMRDST4: begin
                    pre_state <= UNSP1;
                end
                CPLDWAITST1: begin
                    pre_state <= CPLDDATAST1;
                end
                CPLDDATAST1: begin
                    if (rxeop == 1'b1) begin
                        pre_state <= IDLE;
                    end else if (rxdw < 10'h004 || dmardfifodw > 9'h1F0) begin
                        pre_state <= CPLDWAITST6;
                    end else begin
                        pre_state <= CPLDDATAST1;
                    end
                end
                CPLDWAITST6: begin
                    pre_state <= CPLDWAITST7;
                end
                CPLDWAITST7: begin
                    pre_state <= CPLDWAITST8;
                end
                CPLDWAITST8: begin
                    pre_state <= CPLDWAITST9;
                end
                CPLDWAITST9: begin
                    if (dmardfifodw > 9'h1FC) begin
                        pre_state <= CPLDWAITST9;
                    end else begin
                        pre_state <= CPLDDATAST1;
                    end
                end
                default: begin
                    pre_state <= IDLE;
                end
            endcase
        end
    end

    // 外部数据总线输出寄存器：根据地址选择数据位置
    always @(posedge clk) begin
        if (pre_state == DATAST2) begin
            if (addr[2] == 1'b1 && dw3sel == 1'b1) begin
                extdqreg <= rxdata[63:32];
            end else begin
                extdqreg <= rxdata[31:0];
            end
        end
    end

    // 外部数据总线输出使能：内存写期间有效
    always @(posedge clk) begin
        if (pre_state == MEMWRST1 || pre_state == MEMWRST2 || pre_state == MEMWRST3) begin
            dqoen <= 1'b1;
        end else begin
            dqoen <= 1'b0;
        end
    end

    // 内存片选信号：根据 bardec 解码结果设置
    always @(posedge clk) begin
        if (pre_state == RDHEAD2) begin
            memsel1 <= rxbardec[1];
            memsel2 <= rxbardec[2];
        end
    end

    // 输出赋值：控制信号和 LED
    assign iosel = 1'b0;  // IO 空间选择（未使用）
    assign ext_wr = (pre_state == MEMWRST2 || pre_state == MEMWRST3) ? 1'b1 : 1'b0;  // 外部写使能
    assign ext_rd = (pre_state == MEMRDST2 || pre_state == MEMRDST3) ? 1'b1 : 1'b0;  // 外部读使能
    assign memrdrq = (pre_state == MEMRDST3) ? 1'b1 : 1'b0;  // 内存读请求（发送到 txproc）
    assign fiford = (pre_state == RDHEAD1 || pre_state == DATAST1 || pre_state == UNSP1 || pre_state == CPLDWAITST1 || pre_state == CPLDDATAST1) ? 1'b1 : 1'b0;  // FIFO 读使能
    assign dmardfifowr = (pre_state == CPLDDATAST1) ? 1'b1 : 1'b0;  // DMA 读 FIFO 写使能

    // LED 输出
    assign led0 = led0_reg;  // LED0（CPLD 数据接收）
    assign led1 = cplsel;  // LED1（CPL 包指示）
    assign led2 = cplsel;  // LED2（CPL 包指示）
    assign led3 = 1'b0;  // LED3（未使用）

endmodule
