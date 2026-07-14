`timescale 1ns / 1ps

module state_ctrl_xy(
    input   i_clk       ,
    input   i_reset     ,
    input   i_key_a     ,
    input   i_key_b     ,
    input   i_key_c     ,
    input   z_finished  ,
    output  o_dir       ,
    output  o_pluse     ,
    output  o_set
);

    localparam IDLE   = 3'b000;
    localparam FAST   = 3'b001;
    localparam SLOW   = 3'b010;
    localparam BACK   = 3'b011;
    localparam LIMIT  = 3'b100;

    reg [2:0] r_state;
    reg [25:0] r_cnt_data;
    reg r_dir;
    reg r_pluse_zero;
    reg [27:0] r_state3_cnt;
    reg r_state2_zero;

    reg [20:0] r_clkdiv_cnt;
    reg r_clkdiv;

    reg r_rom_ena;
    reg [6:0] r_rom_cnt;
    reg [6:0] r_rom_addra;
    wire [25:0] r_rom_data;

    reg r_pluse;
    reg r_set;
    reg [25:0] r_cnt;

    reg [27:0] c_2s = 200000000;

    assign o_dir = r_dir;
    assign o_pluse = r_pluse;
    assign o_set = r_set;

    always @(posedge i_clk) begin
        case (r_state)
            IDLE: begin
                if (i_key_a == 1'b1 && z_finished == 1'b1) begin
                    r_state <= FAST;
                end else begin
                    r_state <= r_state;
                end
                r_pluse_zero <= 1;
                r_cnt_data <= 4000;
                r_dir <= 1;
                r_state3_cnt <= 0;
            end
            FAST: begin
                if (i_key_b == 1'b1) begin
                    r_state <= SLOW;
                end else if (i_key_c == 1'b1) begin
                    r_state <= LIMIT;
                end else begin
                    r_state <= r_state;
                end
                r_pluse_zero <= 0;
                r_cnt_data <= 4000;
                r_dir <= 1;
                r_state3_cnt <= 0;
            end
            SLOW: begin
                if (r_state2_zero == 1'b1) begin
                    r_state <= IDLE;
                end else begin
                    r_state <= r_state;
                end
                r_pluse_zero <= 0;
                r_cnt_data <= r_rom_data;
                r_dir <= 1;
                r_state3_cnt <= 0;
            end
            BACK: begin
                if (r_state3_cnt < c_2s) begin
                    r_state3_cnt <= r_state3_cnt + 1;
                end else begin
                    r_state3_cnt <= r_state3_cnt;
                end
                if (r_state3_cnt == c_2s) begin
                    r_state <= FAST;
                end else begin
                    r_state <= r_state;
                end
                r_pluse_zero <= 0;
                r_cnt_data <= 4000;
                r_dir <= 0;
            end
            LIMIT: begin
                if (i_key_b == 1'b1) begin
                    r_state <= BACK;
                end else begin
                    r_state <= r_state;
                end
                r_pluse_zero <= 0;
                r_cnt_data <= 4000;
                r_dir <= 0;
                r_state3_cnt <= 0;
            end
            default: begin
                r_cnt_data <= 4000;
                r_dir <= 1;
                r_state3_cnt <= 0;
                r_state <= 0;
                r_pluse_zero <= 1;
            end
        endcase
    end

    reg [20:0] c_40ms = 1600000;
    reg [20:0] c_20ms = 800000;

    always @(posedge i_clk) begin
        if (r_clkdiv_cnt < (c_40ms - 1)) begin
            r_clkdiv_cnt <= r_clkdiv_cnt + 1;
        end else begin
            r_clkdiv_cnt <= 0;
        end

        if (r_clkdiv_cnt < c_20ms) begin
            r_clkdiv <= 1;
        end else begin
            r_clkdiv <= 0;
        end
    end

    always @(posedge r_clkdiv) begin
        if (r_state == SLOW) begin
            if (r_rom_cnt < 100) begin
                r_rom_cnt <= r_rom_cnt + 1;
            end else begin
                r_rom_cnt <= r_rom_cnt;
            end
        end else begin
            r_rom_cnt <= 0;
        end

        if (r_rom_cnt < 100) begin
            r_rom_ena <= 1;
        end else begin
            r_rom_ena <= 0;
        end

        r_rom_addra <= r_rom_cnt;

        if (r_rom_cnt == 100) begin
            r_state2_zero <= 1;
            r_set <= 1;
        end else begin
            r_state2_zero <= 0;
            r_set <= 0;
        end
    end

    line_rom_ip u_line_rom_ip (
        .clock      (r_clkdiv   ),
        .clken      (r_rom_ena  ),
        .address    (r_rom_addra),
        .q          (r_rom_data )
    );

    always @(posedge i_clk) begin
        if (r_cnt < r_cnt_data - 1) begin
            r_cnt <= r_cnt + 1;
        end else begin
            r_cnt <= 0;
        end

        if (r_pluse_zero == 1) begin
            r_pluse <= 0;
        end else begin
            if (r_cnt < r_cnt_data / 2) begin
                r_pluse <= 1;
            end else begin
                r_pluse <= 0;
            end
        end
    end

endmodule