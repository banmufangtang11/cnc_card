module motion(
	input clk,
	input rst,

	input flu_ctr,
	input blow_ctr,
	input clamp_ctr,
	
	inout  reg [31:0] auxiliary,
	
	output chip_flu,
	output blow,
	output clamp,
	output run_led,
	output fau_led,
	output reg [31:0] dcsr	
	
);

endmodule
