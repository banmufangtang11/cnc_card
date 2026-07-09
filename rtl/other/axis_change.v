module axis_change(
							input clk,rstn,
							input button,
							input d2,p2,d4,p4,
							output reg dy,py,da,pa
							);

reg [6:0] count;
reg flag;

always @(posedge clk )
	begin
	if(!rstn)
		begin
		flag <= 1'b0; count <= 7'h0;
		end
	else
	begin
		if(button)
			begin
				if(count == 7'h7d)//???1us???????
					begin flag <= 1'b1; count <= 7'h0; end
				else
					begin flag <= flag; count <= count + 7'h1; end
			end
		else
			begin
				flag <= 1'b0; count <= 7'h0;
			end
	end
end

always @(posedge clk)
begin
	if(!rstn)
		begin
			dy <= 1'b0; py <= 1'b0;
			da <= 1'b0; pa <= 1'b0;
		end
	else if(flag)
		begin
			dy <= 1'b0; py <= 1'b0;
			da <= d2; pa <= p2;
		end
	else if(!flag)
		begin
			dy <= d2; py <= p2;
			da <= d4; pa <= p4; 
		end
	else
		begin
			dy <= d2; py <= p2;
			da <= d4; pa <= p4; 
		end
end

endmodule
 