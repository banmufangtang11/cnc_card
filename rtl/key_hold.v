module key_hold(clk,key_in,key_out);

input clk,key_in;
output key_out;

reg [6:0]count;
reg flag;

always @(posedge clk)
	begin
	if(key_in)
		 begin
		if(count == 7'h7d)//延时1us，去抖动
			begin flag <= 1'b1; count <= 6'h0; end
		else
			begin flag <= flag; count <= count + 6'h1; end
		end
	else
		begin
		flag <= 1'b0; count <= 6'h0;
		end
	end

assign	key_out  =  (flag) ?  1'b1 : 1'b0;
	
endmodule 