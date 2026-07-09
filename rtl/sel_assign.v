module 	sel_assign(
  valid,empty,datain,dataout,
  dir_x,dir_x0,dir_x1,
  dir_y,dir_y0,dir_y1,
  dir_z,dir_z0,dir_z1,
  dir_a,dir_a0,dir_a1,
  puls_x,puls_x0,puls_x1,
  puls_y,puls_y0,puls_y1,
  puls_z,puls_z0,puls_z1,
  puls_a,puls_a0,puls_a1);
  
input	valid,empty;
input	dir_x0,dir_x1;
input	dir_y0,dir_y1;
input	dir_z0,dir_z1;
input	dir_a0,dir_a1;
input	puls_x0,puls_x1;
input	puls_y0,puls_y1;
input	puls_z0,puls_z1;
input	puls_a0,puls_a1;
output	dir_x,dir_y,dir_z,dir_a;
output	puls_x,puls_y,puls_z,puls_a;

input [31:0]datain;
output [31:0]dataout;

assign	dataout = (empty) ? 32'h0 : datain;

//--------------------------------���мӹ�����ʱ���㶯��ʹ��----------------------------------------------
assign	dir_x  =  (valid) ? dir_x1  : dir_x0;
assign	dir_y  =  (valid) ? dir_y1  : dir_y0; 
assign	dir_z  =  (valid) ? dir_z1  : dir_z0;
assign	puls_x =  (valid) ? puls_x1 : puls_x0;
assign	puls_y =  (valid) ? puls_y1 : puls_y0;
assign	puls_z =  (valid) ? puls_z1 : puls_z0;
assign	dir_a  =  (valid) ? dir_a1  : dir_a0;
assign	puls_a =  (valid) ? puls_a1 : puls_a0;

endmodule 