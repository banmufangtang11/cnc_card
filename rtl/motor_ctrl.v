`timescale 1ns / 1ps

module motor_ctrl(
    input       i_clk    ,
    input       i_key_a  ,
    input       i_key_b  ,
    input       i_key_c  ,
    output      o_dir    ,
    output      o_pluse  ,
    output      o_set
);

    wire key1_rdy;
    wire key2_rdy;
    wire key3_rdy;

    key_gen u_key_gen (
        .clk        (i_clk    ),
        .key1       (i_key_a  ),
        .key2       (i_key_b  ),
        .key3       (i_key_c  ),
        .key1_rdy   (key1_rdy ),
        .key2_rdy   (key2_rdy ),
        .key3_rdy   (key3_rdy )
    );

    state_ctrl u_state_ctrl (
        .i_clk      (i_clk    ),
        .i_reset    (1'b0     ),
        .i_key_a    (key1_rdy ),
        .i_key_b    (key2_rdy ),
        .i_key_c    (key3_rdy ),
        .o_dir      (o_dir    ),
        .o_pluse    (o_pluse  ),
        .o_set      (o_set    )
    );

endmodule