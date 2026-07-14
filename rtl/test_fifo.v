`timescale 1ns / 1ps

module test_fifo(
    input           clk         ,
    input           rst         ,
    input           rdempty     ,
    input   [8:0] rddw        ,
    input   [10:0] dw          ,
    output  reg    fifo31_inwr ,
    output  reg    fiford
);

    localparam IDLE    = 0;
    localparam RDWRST  = 1;
    localparam WAITST1 = 2;
    localparam WAITST2 = 3;
    localparam WAITST3 = 4;
    localparam WAITST4 = 5;
    localparam WAITST5 = 6;
    localparam WAITST6 = 7;

    reg [2:0] pre_state;
    reg [2:0] nxt_state;

    always @(*) begin
        case (pre_state)
            IDLE:    if (rdempty == 1'b0 && dw <= 11'b011111010000) nxt_state = RDWRST;
                     else nxt_state = IDLE;
            RDWRST:  if (rddw <= 9'b000000100 || dw > 11'b011111010000) nxt_state = WAITST1;
                     else nxt_state = RDWRST;
            WAITST1: nxt_state = WAITST2;
            WAITST2: nxt_state = WAITST3;
            WAITST3: nxt_state = WAITST4;
            WAITST4: nxt_state = WAITST5;
            WAITST5: nxt_state = WAITST6;
            WAITST6: nxt_state = IDLE;
            default: nxt_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            pre_state <= IDLE;
            fifo31_inwr <= 1'b0;
            fiford <= 1'b0;
        end else begin
            pre_state <= nxt_state;

            if (pre_state == RDWRST) begin
                fifo31_inwr <= 1'b1;
                fiford <= 1'b1;
            end else begin
                fifo31_inwr <= 1'b0;
                fiford <= 1'b0;
            end
        end
    end

endmodule