module spindle_key(       
	input clk,  
	input rstn,   
	
	input start,
	input s_dir,
	input	vfd_rst,     
	input [2:0] switch, 
	
	output  reg start_flag, 
	output  reg s_dir_flag, 
	output  reg vfd_rst_flag, 
	output  reg [2:0] flag	
);
reg [6:0] count1,count2,count3,count4;
reg [6:0] count5,count6,count7;
reg [6:0] count_a,count_b,count_c;

always @(posedge clk or negedge rstn )
begin
	if(!rstn)
		begin
			flag <= 3'b000; count1 <= 7'h0;count2 <= 7'h0;count3 <= 7'h0;
			count4 <= 7'h0;count5 <= 7'h0;count6 <= 7'h0;count7 <= 7'h0;
		end
	else
		begin
			if(switch == 3'b001)
				begin
					if(count1 == 7'h7d)//  1us
						begin flag <= 3'b001; count1 <= 7'h0; end
					else
						begin flag <= flag; count1 <= count1 + 7'h1; end
				end
			else if(switch == 3'b010)
				begin
					if(count2 == 7'h7d)//  1us
						begin flag <= 3'b010; count2 <= 7'h0; end
					else
						begin flag <= flag; count2 <= count2 + 7'h1; end
				end
			else if(switch == 3'b011)
				begin
					if(count3 == 7'h7d)//  1us
						begin flag <= 3'b011; count3 <= 7'h0; end
					else
						begin flag <= flag; count3 <= count3 + 7'h1; end
				end
			else if(switch == 3'b100)
				begin
					if(count4 == 7'h7d)//  1us
						begin flag <= 3'b100; count4 <= 7'h0; end
					else
						begin flag <= flag; count4 <= count4 + 7'h1; end
				end
			else if(switch == 3'b101)
				begin
					if(count5 == 7'h7d)//  1us
						begin flag <= 3'b101; count5 <= 7'h0; end
					else
						begin flag <= flag; count5 <= count5 + 7'h1; end
				end
			else if(switch == 3'b110)
				begin
					if(count6 == 7'h7d)//  1us
						begin flag <= 3'b110; count6 <= 7'h0; end
					else
						begin flag <= flag; count6 <= count6 + 7'h1; end
				end
			else if(switch == 3'b111)
				begin
					if(count7 == 7'h7d)//  1us
						begin flag <= 3'b111; count7 <= 7'h0; end
					else
						begin flag <= flag; count7 <= count7 + 7'h1; end
				end
			else
				begin
					flag <= 3'b000; count1 <= 7'h0;count2 <= 7'h0;count3 <= 7'h0;
					count4 <= 7'h0;count5 <= 7'h0;count6 <= 7'h0;count7 <= 7'h0;
				end
		end
end

always @(posedge clk)
begin
	if (start==1)
	begin
		if(count_a == 7'h7d)//  1us
		begin start_flag <= 1'b1; count_a <= 7'h0; end
		else
			begin start_flag <= start_flag; count_a <= count_a + 7'h1; end
	end
	else begin start_flag <= 1'b0; count_a <= 7'h0; end
end

always @(posedge clk)
begin
	if (s_dir==1)
	begin
		if(count_b == 7'h7d)//  1us
		begin s_dir_flag <= 1'b1; count_b <= 7'h0; end
		else
			begin s_dir_flag <= s_dir_flag; count_b <= count_b + 7'h1; end
	end
	else begin s_dir_flag <= 1'b0; count_b <= 7'h0; end
end

always @(posedge clk)
begin
	if (vfd_rst==1)
	begin
		if(count_c == 7'h7d)//  1us
		begin vfd_rst_flag <= 1'b1; count_c <= 7'h0; end
		else
			begin vfd_rst_flag <= vfd_rst_flag; count_c <= count_c + 7'h1; end
	end
	else begin vfd_rst_flag <= 1'b0; count_c <= 7'h0; end
end


endmodule
