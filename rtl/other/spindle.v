module spindle(       
	input clk,  
	input rstn,   
	
	input start,
	input s_dir,
	input	vfd_rst,     
	input [2:0] switch,

	inout  reg [31:0] auxiliary,
	
	output  reg vfd_M0, 
	output  reg vfd_M1, 
	output  reg vfd_M2, 
	output  reg vfd_M3,
	output  reg vfd_M4,
	output  reg vfd_M5,
	output reg [31:0] dcsr
);

wire start_flag; 
wire s_dir_flag; 
wire vfd_rst_flag;
wire [2:0] flag;	

spindle_key u_spindle_key(       
	.clk				(clk),  
	.rstn				(rstn),   
	
	.start			(start),
	.s_dir			(s_dir),
	.vfd_rst			(vfd_rst),     
	.switch			(switch), 
	
	.start_flag		(start_flag), 
	.s_dir_flag		(s_dir_flag), 
	.vfd_rst_flag	(vfd_rst_flag), 
	.flag				(flag)
);

spindle_ctrl u_spindle_ctrl(       
	.clk				(clk),  
	.rstn				(rstn),   
	
	.start_flag		(start_flag),
	.s_dir_flag		(s_dir_flag),
	.vfd_rst_flag	(vfd_rst_flag),     
	.flag				(flag), 
	
	.vfd_M0			(vfd_M0), 
	.vfd_M1			(vfd_M1), 
	.vfd_M2			(vfd_M2), 
	.vfd_M3			(vfd_M3),
	.vfd_M4			(vfd_M4),
	.vfd_M5			(vfd_M5)	
);

endmodule
