module 	interpolation(clk,valid,data,q);
input	clk,valid;
input	[16:0]data;//
output	reg q;
reg q_t;
reg q_tt;
reg [31:0] clk_num;
reg clk_flag;
wire plus_pos;
reg delta_flag;
reg [31:0] plus_num;
reg [31:0] plus_num_t;
reg [31:0] delta;
reg [31:0] data_reg;
reg [31:0] plus_total;
reg [31:0] sum	;
localparam clk_delay = 249999;
localparam clocks = 250000; 
assign plus_pos = (!q_tt && q_t);

always @(posedge clk)begin
	if(!valid)
		data_reg  <= 'd0;
	else 
		data_reg  <= data;//
end

always @(posedge clk)begin
	if(!valid)
		delta  <= 'd0;
	else
		delta  <= data_reg - plus_num_t;	
end


always @(posedge clk)begin
	if(!valid)
		delta_flag  <= 'd0;
	else if(delta_flag == 1 && clk_flag==1)
		delta_flag  <= 'd0;
	else if(delta!=0 && clk_flag==1)
		delta_flag <= 'd1;
	else
		delta_flag  <= delta_flag;
end

always @(posedge clk)begin
	if(!valid)
			clk_flag  <= 'd0;
	else if(clk_num == clk_delay-1'b1 )
			clk_flag  <= 'd1;
	else
		   clk_flag  <= 'd0;
end

always @(posedge clk)begin
	if(!valid)
		sum  <= 'd0;
	else if(clk_flag == 'd1)
		sum  <= 'd0;
	else	if(sum >= clocks)
		sum <= sum - clocks;
	else
		sum <= sum + data_reg;
end

always @(posedge clk)begin
	if(!valid)
			q  <= 'd0;
	else if(clk_flag == 'd1)
			q  <= 'd0;
	else if(sum >= clocks/2 && sum < clocks)
			q  <= 'd1;
	else if(sum >= clocks)
			q  <= 'd0;
	else
			q  <=  q;
end

always @(posedge clk)begin
	if(!valid)
			clk_num  <= 'd0;
	else if(clk_num == clk_delay-1'b1)
			clk_num <= 'd0;
	else
		clk_num <= clk_num + 1'b1;
end

always @(posedge clk)begin
	if(!valid)
		plus_num <= 'd0;
	else if(clk_flag  == 'd1)
		plus_num <= 'd0;
	else if(plus_pos)
		plus_num <= plus_num + 1'b1;
	else
		plus_num <= plus_num;
end

always @(posedge clk)begin
	if(!valid)
		plus_num_t <= 'd0;
	else
		plus_num_t <= plus_num;
end

always @(posedge clk)begin
	if(!valid)
		plus_total <= 'd0;
	else if(plus_pos)
		plus_total <= plus_total + 1'b1;
	else
		plus_total <= plus_total;
end

always @(posedge clk)begin
	if(!valid)
		begin
			q_t 	<= 'd0	;
			q_tt	<= 'd0	;
		end
	else
		begin
			q_t 	<= q		;
			q_tt	<= q_t	;
		end
end


endmodule 