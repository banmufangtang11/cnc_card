module axis_sel(clk,rstn,i_X,i_Y,i_Z,i_A,
						p,dir_in,
						dir_x,dir_y,dir_z,dir_a,
						puls_x,puls_y,puls_z,puls_a);
						
input clk,rstn;
input i_X,i_Y,i_Z,i_A;
input p,dir_in;

output dir_x,dir_y,dir_z,dir_a,
		 puls_x,puls_y,puls_z,puls_a;

reg dir_x,dir_y,dir_z,dir_a,
	 puls_x,puls_y,puls_z,puls_a;
reg [6:0] count1,count2,count3,count4;
reg flag1,flag2,flag3,flag4;
	 
//-------------------------------------------------------------------	 
always @(posedge clk )
	begin
	if(!rstn)
		begin
		flag1 <= 1'b0; count1 <= 7'h0;
		end
	else
	begin
		if(!i_X)
			begin
				if(count1 == 7'h7d)//???1us???????
					begin flag1 <= 1'b1; count1 <= 7'h0; end
				else
					begin flag1 <= flag1; count1 <= count1 + 7'h1; end
			end
		else
			begin
				flag1 <= 1'b0; count1 <= 7'h0;
			end
	end
end
			 
always @(posedge clk )
begin
	if(!rstn)
		begin
		flag2 <= 1'b0; count2 <= 7'h0;
		end
	else
		begin
			if(!i_Y)
				begin
					if(count2 == 7'h7d)//???1us???????
						begin flag2 <= 1'b1; count2 <= 7'h0; end
					else
						begin flag2 <= flag2; count2 <= count2 + 7'h1; end
				end
			else
				begin
					flag2 <= 1'b0; count2 <= 7'h0;
				end
		end
end

always @(posedge clk )
begin
	if(!rstn)
		begin
			flag3 <= 1'b0; count3 <= 7'h0;
		end
	else
		begin
			if(!i_Z)
				begin
					if(count3 == 7'h7d)//???1us???????
						begin flag3 <= 1'b1; count3 <= 7'h0; end
					else
						begin flag3 <= flag3; count3 <= count3 + 7'h1; end
				end
			else
				begin
					flag3 <= 1'b0; count3 <= 7'h0;
				end
	end
end

always @(posedge clk )
begin
	if(!rstn)
		begin
			flag4 <= 1'b0; count4 <= 7'h0;
		end
	else
		begin
			if(!i_A)
				begin
					if(count4 == 7'h7d)//???1us???????
						begin flag4 <= 1'b1; count4 <= 7'h0; end
					else
						begin flag4 <= flag4; count4 <= count4 + 7'h1; end
				end
			else
				begin
					flag4 <= 1'b0; count4 <= 7'h0;
				end
		end
end
	
//---------------------------------------------------------------------------	
	 
always @(posedge clk or negedge rstn)
begin
	if(!rstn)
		begin 
			dir_x <= 1'b0; dir_y <= 1'b0; dir_z <= 1'b0; dir_a <= 1'b0;
			puls_x <= 1'b0; puls_y <= 1'b0; puls_z <= 1'b0; puls_a <= 1'b0;
		end
	else
		begin
			if(flag1)
				begin
					dir_x <= dir_in; dir_y <= 1'b0; dir_z <= 1'b0; dir_a <= 1'b0;
					puls_x <= p; puls_y <= 1'b0; puls_z <= 1'b0; puls_a <= 1'b0;
				end
			else if(flag2)
				begin
					dir_x <= 1'b0; dir_y <= dir_in; dir_z <= 1'b0; dir_a <= 1'b0;
					puls_x <= 1'b0; puls_y <= p; puls_z <= 1'b0; puls_a <= 1'b0;
				end
			else if(flag3)
				begin
					dir_x <= 1'b0; dir_y <= 1'b0; dir_z <= dir_in; dir_a <= 1'b0;
					puls_x <= 1'b0; puls_y <= 1'b0; puls_z <= p; puls_a <= 1'b0;
				end
			else if(flag4)
				begin
					dir_x <= 1'b0; dir_y <= 1'b0; dir_z <= 1'b0; dir_a <= dir_in;
					puls_x <= 1'b0; puls_y <= 1'b0; puls_z <= 1'b0; puls_a <= p;
				end
			else
				begin
					dir_x <= 1'b0; dir_y <= 1'b0; dir_z <= 1'b0; dir_a <= 1'b0;
					puls_x <= 1'b0; puls_y <= 1'b0; puls_z <= 1'b0; puls_a <= 1'b0;
				end
		end
end

endmodule
