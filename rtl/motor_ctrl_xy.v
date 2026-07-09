`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:04:37 12/13/2015 
// Design Name: 
// Module Name:    motor_ctrl 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module motor_ctrl_xy(
    	input	i_clk	,
    	input	i_key_a	,//zero switch
    	input	i_key_b	,//proximity switch
    	input	i_key_c	,//limit switch
		input z_finished,
    	output	o_dir	,
    	output	o_pluse,
		output   o_set
    	);
    	
	wire	key1_rdy;
	wire	key2_rdy;
	wire	key3_rdy;    	               

//------------delay 100ms for each key------------------
	key_gen 
		i_key_gen (
	    .clk		(i_clk		), 
	    .key1		(1'b0	), 
	    .key2		(i_key_b	), 
	    .key3		(i_key_c	), 
		 
	    .key1_rdy	(key1_rdy	), 
	    .key2_rdy	(key2_rdy	), 
	    .key3_rdy	(key3_rdy	)
	    );
//----------fsm of ZRN-------------	        	
	state_ctrl_xy 
		i_state_ctrl_xy (
	    .i_clk		(i_clk		), 
	    .i_reset	(1'b0		), 
		 .z_finished(z_finished ),
	    .i_key_a	(i_key_a		), 
	    .i_key_b	(key2_rdy	), 
	    .i_key_c	(key3_rdy	), 
		 
	    .o_dir		(o_dir		), 
	    .o_pluse	(o_pluse	),
		 .o_set (o_set)
	    );

endmodule
