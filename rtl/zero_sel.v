module zero_sel(clk,szero,
          dir_x,dir_y,dir_z,puls_x,puls_y,puls_z,
			 dir_x_zero,dir_y_zero,dir_z_zero,puls_x_zero,puls_y_zero,puls_z_zero,
			 dir_x_jog,dir_y_jog,dir_z_jog,puls_x_jog,puls_y_jog,puls_z_jog);

input clk,szero;
input dir_x_zero,dir_y_zero,dir_z_zero,puls_x_zero,puls_y_zero,puls_z_zero;
input dir_x_jog,dir_y_jog,dir_z_jog,puls_x_jog,puls_y_jog,puls_z_jog;
output dir_x,dir_y,dir_z,puls_x,puls_y,puls_z;

reg [6:0]count9;
reg flag9;

always @(posedge clk)
	begin
	if(szero)	//回零运动
		 begin
		if(count9 == 7'h7d)//延时1us，去回零按钮抖动
			begin flag9 <= 1'b1; count9 <= 6'h0; end
		else
			begin flag9 <= flag9; count9 <= count9 + 6'h1; end
		end
	else			//电动运动
		begin
		flag9 <= 1'b0; count9 <= 6'h0;
		end
	end  


assign	dir_x  =  (flag9) ? dir_x_zero  : dir_x_jog;
assign	dir_y  =  (flag9) ? dir_y_zero  : dir_y_jog; 
assign	dir_z  =  (flag9) ? dir_z_zero  : dir_z_jog;
assign	puls_x =  (flag9) ? puls_x_zero : puls_x_jog;
assign	puls_y =  (flag9) ? puls_y_zero : puls_y_jog;
assign	puls_z =  (flag9) ? puls_z_zero : puls_z_jog;

endmodule 