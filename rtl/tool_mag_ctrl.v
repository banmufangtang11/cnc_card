`timescale 1ns / 1ps

module tool_mag_ctrl(
    input           clk             ,
    input           rst_tm          ,
    input   [31:0] aux_data        ,
    input           ahe_fin         ,
    input           back_fin        ,
    input           rot_count       ,
    input           loos_fin        ,
    input           clr_counts      ,
    output  reg [31:0] aux_feedback   ,
    output  reg    enable_tlmag     ,
    output  reg    go               ,
    output  reg    back             ,
    output  reg    rot_dir          ,
    output  reg    rot              ,
    output  reg    tool_loos        ,
    output  reg    use_axis8
);

    reg [19:0] count15 = 20'haaaa;
    reg [19:0] target_number;
    reg [19:0] rot_number;
    reg [19:0] count_pul;
    reg rot_state;

    reg [15:0] time_delay;
    reg [6:0] time_delay_two;

    always @(posedge clk or negedge rst_tm) begin
        if (!rst_tm) begin
            rot_number <= 20'h0;
        end else begin
            if (clr_counts == 1'b1) begin
                rot_number <= 20'h0;
                time_delay_two <= 7'h0;
            end else begin
                if (rot_count == 1'b0) begin
                    if (time_delay_two == 7'h7d) begin
                        rot_number <= rot_number + 20'h1;
                        time_delay_two <= 7'h0;
                    end else begin
                        rot_number <= rot_number;
                        time_delay_two <= time_delay_two + 7'h1;
                    end
                end
            end
        end
    end

    always @(posedge clk or negedge rst_tm) begin
        if (!rst_tm) begin
            rot <= 1'b0;
            rot_dir <= 1'b0;
        end else begin
            if (rot_state == 1'b1) begin
                if (time_delay == 16'h3d09) begin
                    rot <= ~rot;
                    rot_dir <= 1'b1;
                    count_pul <= count_pul + 20'h1;
                    time_delay <= 16'h0;
                end else begin
                    time_delay <= time_delay + 16'h1;
                    rot <= rot;
                    rot_dir <= rot_dir;
                end
            end else begin
                rot <= 1'b0;
                rot_dir <= 1'b0;
                count_pul <= 20'h0;
                time_delay <= 16'h0;
            end
        end
    end

    always @(posedge clk or negedge rst_tm) begin
        if (!rst_tm) begin
            enable_tlmag <= 1'b0;
            go <= 1'b0;
            back <= 1'b0;
            tool_loos <= 1'b0;
            rot_state <= 1'b0;
        end else begin
            if (rot_number == target_number) begin
                rot_state <= 1'b0;
                use_axis8 <= 1'b0;
                target_number <= 20'h0;
            end

            case (aux_data[8:4])
                5'b00001: target_number <= 20'h1;
                5'b00010: target_number <= 20'h2;
                5'b00011: target_number <= 20'h3;
                5'b00100: target_number <= 20'h4;
                5'b00101: target_number <= 20'h5;
                5'b00110: target_number <= 20'h6;
                5'b00111: target_number <= 20'h7;
                5'b01000: target_number <= 20'h8;
                5'b01001: target_number <= 20'h9;
                5'b01010: target_number <= 20'ha;
                5'b01011: target_number <= 20'hb;
                5'b01100: target_number <= 20'hc;
                5'b01101: target_number <= 20'hd;
                5'b01110: target_number <= 20'he;
                5'b01111: target_number <= 20'hf;
                5'b10000: target_number <= 20'h10;
                5'b10001: target_number <= 20'h11;
                5'b10010: target_number <= 20'h12;
                5'b10011: target_number <= 20'h13;
                5'b10100: target_number <= 20'h14;
                5'b10101: target_number <= 20'h15;
                5'b10110: target_number <= 20'h16;
                5'b10111: target_number <= 20'h17;
                5'b11000: target_number <= 20'h18;
                default:  target_number <= target_number;
            endcase

            if (aux_data[3:0] == 4'b0100) enable_tlmag <= 1'b1;
            if (aux_data[3:0] == 4'b0101) enable_tlmag <= 1'b0;
            if (aux_data[3:0] == 4'b0110) go <= 1'b1;
            if (aux_data[3:0] == 4'b0111) back <= 1'b1;
            if (aux_data[3:0] == 4'b1000) tool_loos <= 1'b1;
            if (aux_data[3:0] == 4'b1001) tool_loos <= 1'b0;
            if (aux_data[3:0] == 4'b1010) begin
                rot_state <= 1'b1;
                use_axis8 <= 1'b1;
            end

            if (ahe_fin == 1'b0) go <= 1'b0;
            if (back_fin == 1'b0) back <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_tm) begin
        if (!rst_tm) begin
            aux_feedback <= 32'b0;
        end else begin
            if (back_fin == 1'b0 && enable_tlmag == 1'b0) begin
                aux_feedback <= 32'b00000000000000000000000001000000;
            end else if (rot_state == 1'b0) begin
                aux_feedback <= 32'b00000000000000000000000000001000;
            end else begin
                aux_feedback <= 32'b0;
            end
        end
    end

endmodule