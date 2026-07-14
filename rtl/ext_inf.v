`timescale 1ns / 1ps

module ext_inf(
    input           clk             ,
    input           rst             ,
    input           valid           ,
    inout   [31:0] dq              ,
    input           data_rd_out     ,
    input           data_wr         ,
    input   [21:0] ext_add         ,
    output  reg    ext_rd          ,
    output  reg    ext_wr          ,
    output  reg    led0            ,
    output  reg    led1            ,
    output  reg    led2            ,
    output  reg    led3            ,
    input           empty           ,
    input           full            ,
    input           almost_empty    ,
    input           almost_full     ,
    input           iosel           ,
    input           memsel1         ,
    input           memsel2         ,
    input           app_int_ack     ,
    output  reg    ext_int_req     ,
    output  [31:0] fifo_in         ,
    input   [31:0] fifo_out        ,
    output  reg    wrreq
);

    reg [31:0] dqinreg;
    reg intregsel;
    reg pctocardregsel;
    reg [31:0] intreg;
    reg [31:0] pctocardreg;
    reg wr_flag;
    reg [1:0] cnt;

    assign fifo_in = pctocardreg;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            dqinreg <= 32'h00000000;
            intregsel <= 1'b0;
            pctocardregsel <= 1'b0;
            pctocardreg <= 32'h00000000;
            wr_flag <= 1'b0;
        end else begin
            dqinreg <= dq;

            intregsel <= (memsel1 == 1'b1 && ext_add == 22'b0000000000000000000100) ? 1'b1 : 1'b0;
            pctocardregsel <= (memsel1 == 1'b1 && ext_add == 22'b0000000000000000010100) ? 1'b1 : 1'b0;

            if (pctocardregsel == 1'b1 && data_wr == 1'b1) begin
                pctocardreg <= dqinreg;
                wr_flag <= 1'b1;
            end else begin
                wr_flag <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            wrreq <= 1'b0;
            cnt <= 2'b00;
        end else begin
            if (wr_flag == 1'b1 && cnt == 2'b00) begin
                wrreq <= 1'b1;
                cnt <= cnt + 1;
            end else if (cnt == 2'b01) begin
                wrreq <= 1'b0;
                cnt <= 2'b00;
            end else begin
                wrreq <= 1'b0;
                cnt <= 2'b00;
            end
        end
    end

    always @(*) begin
        ext_int_req = (almost_empty == 1'b1 && valid == 1'b1) ? 1'b1 : 1'b0;
    end

endmodule