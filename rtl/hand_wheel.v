// Copyright (C) 1991-2013 Altera Corporation
// Your use of Altera Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License 
// Subscription Agreement, Altera MegaCore Function License 
// Agreement, or other applicable license agreement, including, 
// without limitation, that your use is for the sole purpose of 
// programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the 
// applicable agreement for further details.
//
// PROGRAM		"Quartus II 64-Bit"
// VERSION		"Version 13.1.0 Build 162 10/23/2013 SJ Full Version"
// CREATED		"Thu Dec 06 11:39:39 2018"

module hand_wheel(
	clk_50m,
	rstn,
	b_in,
	a_in,
	i_x1,
	i_x10,
	i_x100,
	i_X,
	i_Y,
	i_Z,
	i_A,
	dir_x,
	dir_y,
	dir_z,
	dir_a,
	puls_x,
	puls_y,
	puls_z,
	puls_a
);


input wire	clk_50m;
input wire	rstn;
input wire	b_in;
input wire	a_in;
input wire	i_x1;
input wire	i_x10;
input wire	i_x100;
input wire	i_X;
input wire	i_Y;
input wire	i_Z;
input wire	i_A;
output wire	dir_x;
output wire	dir_y;
output wire	dir_z;
output wire	dir_a;
output wire	puls_x;
output wire	puls_y;
output wire	puls_z;
output wire	puls_a;

wire	A_in1;
wire	B_in1;
wire	clk;
wire	dir_out;
wire	empty;
wire	full;
wire	puls_out;
wire	rdreq;
wire	rst;
wire	SYNTHESIZED_WIRE_0;
wire	[21:0] SYNTHESIZED_WIRE_1;
wire	[21:0] SYNTHESIZED_WIRE_2;





queue	b2v_inst(
	.wrreq(SYNTHESIZED_WIRE_0),
	.rdreq(rdreq),
	.clock(clk),
	.sclr(rst),
	.data(SYNTHESIZED_WIRE_1),
	
	.full(full),
	.empty(empty),
	.q(SYNTHESIZED_WIRE_2));


puls_hw	b2v_inst1(
	.clk(clk),
	.rstn(rstn),
	.empty(empty),
	.i_x1(i_x1),
	.i_x10(i_x10),
	.i_x100(i_x100),
	.q(SYNTHESIZED_WIRE_2),
	
	.rdreq(rdreq),
	.puls_out(puls_out));
	defparam	b2v_inst1.F0 = 3'b011;
	defparam	b2v_inst1.F1 = 3'b100;
	defparam	b2v_inst1.F2 = 3'b101;
	defparam	b2v_inst1.F3 = 3'b110;


fsm_hw	b2v_inst2(
	.clk(clk),
	.rstn(rstn),
	.a_in(A_in1),
	.b_in(B_in1),
	.full(full),
	
	.wrreq(SYNTHESIZED_WIRE_0),
	.dir_out(dir_out),
	.data(SYNTHESIZED_WIRE_1));
	defparam	b2v_inst2.M0 = 2'b00;
	defparam	b2v_inst2.M1 = 2'b01;
	defparam	b2v_inst2.M2 = 2'b10;


axis_sel	b2v_inst3(
	.clk(clk),
	.rstn(rstn),
	.i_X(i_X),
	.i_Y(i_Y),
	.i_Z(i_Z),
	.i_A(i_A),
	.p(puls_out),
	.dir_in(dir_out),
	
	.dir_x(dir_x),
	.dir_y(dir_y),
	.dir_z(dir_z),
	.dir_a(dir_a),
	.puls_x(puls_x),
	.puls_y(puls_y),
	.puls_z(puls_z),
	.puls_a(puls_a));

assign	rst =  ~rstn;


filter_encode	b2v_inst5(
	.clk(clk),
	.rst_n(rstn),
	.puls(b_in),
	
	.filter(A_in1));


filter_encode	b2v_inst6(
	.clk(clk),
	.rst_n(rstn),
	.puls(a_in),
	
	.filter(B_in1));

assign	clk = clk_50m;

endmodule
