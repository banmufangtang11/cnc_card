module count_model(clk,rstn,pos,neg,count_zero,count_out);

input clk,rstn,pos,neg;
input [31:0] count_zero;
output [31:0]count_out;

reg key1,key2;
reg [31:0] count1,count2,count3;
reg [6:0] c1,c2;
reg [15:0] c3,c4;




always @(posedge clk )
	begin
	if(pos)
		begin
		if(c1 == 7'h7d)
			begin key1 <= 1'b1; c1 <= 7'h0; end
		else
			begin key1 <= key1; c1 <= c1 + 7'h1; end
		end
	else
		begin
		key1 <= 1'b0; c1 <= 7'h0;
		end
	end


always @(posedge clk )
	begin
	if(neg)
		begin
		if(c2 == 7'h7d)
			begin key2 <= 1'b1; c2 <= 7'h0; end
		else
			begin key2 <= key2; c2 <= c2 + 7'h1; end
		end
	else
		begin
		key2 <= 1'b0; c2 <= 7'h0;
		end
	end
	
always @(posedge clk)
begin
  if(rstn==0)
    begin count1<= 32'h0;end
  else
    begin
  if(key1)
    begin
	 if(c3 == 16'h7a12)
	   begin count1 <= count1+32'h1; c3 <= 16'h0; end
	 else
	   begin count1 <= count1; c3 <= c3 +16'h1; end
	 end
	 end
end

always @(posedge clk)
begin
  if(rstn==0)
    begin count2<= 32'h0;end
  else
    begin
  if(key2)
    begin
	 if(c4 == 16'h7a12)
	   begin count2 <= count2+32'h1; c4 <= 16'h0; end
	 else
	   begin count2 <= count2; c4 <= c4 +16'h1; end
	 end
	 end
end
	
assign count_out = count1 - count2 + count_zero;

endmodule 