module jog_sel(clk,hw_valid,
          dir_x,dir_y,dir_z,dir_a,puls_x,puls_y,puls_z,puls_a,
			 dir_x_hw,dir_y_hw,dir_z_hw,dir_a_hw,puls_x_hw,puls_y_hw,puls_z_hw,puls_a_hw,
			 dir_x_jog,dir_y_jog,dir_z_jog,dir_a_jog,puls_x_jog,puls_y_jog,puls_z_jog,puls_a_jog);

input clk,hw_valid;
input dir_x_hw,dir_y_hw,dir_z_hw,dir_a_hw,puls_x_hw,puls_y_hw,puls_z_hw,puls_a_hw;
input dir_x_jog,dir_y_jog,dir_z_jog,dir_a_jog,puls_x_jog,puls_y_jog,puls_z_jog,puls_a_jog;
output dir_x,dir_y,dir_z,dir_a,puls_x,puls_y,puls_z,puls_a;

reg [6:0]count9;
reg flag9;

always @(posedge clk)
	begin
	if(!hw_valid)
		 begin
		if(count9 == 7'h7d)//延时1us，去抖动
			begin flag9 <= 1'b1; count9 <= 7'h0; end
		else
			begin flag9 <= flag9; count9 <= count9 + 7'h1; end
		end
	else
		begin
		flag9 <= 1'b0; count9 <= 7'h0;
		end
	end  


assign	dir_x  =  (flag9) ? dir_x_hw  : dir_x_jog;
assign	dir_y  =  (flag9) ? dir_y_hw  : dir_y_jog; 
assign	dir_z  =  (flag9) ? dir_z_hw  : dir_z_jog;
assign	dir_a  =  (flag9) ? dir_a_hw  : dir_a_jog;
assign	puls_x =  (flag9) ? puls_x_hw : puls_x_jog;
assign	puls_y =  (flag9) ? puls_y_hw : puls_y_jog;
assign	puls_z =  (flag9) ? puls_z_hw : puls_z_jog;
assign	puls_a =  (flag9) ? puls_a_hw : puls_a_jog;

endmodule 