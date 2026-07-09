module filter_encode(
	 // system signals
	input  clk	   ,
	input  rst_n	,
	input	 puls,
	// others
	output reg filter


);

//================================================================\
// ========= Define Parameter and Internal Signals ==========
//================================================================/
//localparam filter_cnt_end = 'd8;
localparam filter_cnt_end = 'd20;
//localparam bps_cnt_end = 'd2;
reg [7:0] filter_cnt;

reg puls_t;		//延迟一个时钟
reg puls_tt;	//延迟两个时钟

reg flag;		
reg flag_cnt;

wire puls_neg;	//脉冲上升沿
wire puls_pos;

//================================================================\
// ****************     Main    Code    **************
//================================================================/
assign puls_neg = (puls_tt & !puls_t);	//上升沿产生的脉冲
assign puls_pos = (!puls_tt & puls_t);	//下降沿产生的脉冲

always@(posedge clk or negedge rst_n )begin
		if(!rst_n)
			begin
			puls_t<=1'b1;
			puls_tt<=1'b1;
			end
		else 
			begin
			puls_t<=puls;
			puls_tt<=puls_t;
			end
end

always@(posedge clk or negedge rst_n )begin
		if(!rst_n)
			filter_cnt	<= 'd0;
		else if(filter_cnt==filter_cnt_end || puls_neg ==1 || puls_pos==1)
			filter_cnt	<=	'd0;	//用来脉冲后计时
		else if(flag_cnt==1)		//计时使能
			filter_cnt	<=	filter_cnt	+	1'b1;
		else
			filter_cnt	<=	filter_cnt;
end

always@(posedge clk or negedge rst_n )begin
		if(!rst_n)
			flag_cnt	<= 'd0;
		else if(filter_cnt==filter_cnt_end)
			flag_cnt	<= 'd0;
		else if(puls_neg ==1 || puls_pos==1)
			flag_cnt	<= 'd1;
		else
			flag_cnt	<= flag_cnt;
end

always@(*)begin
		if(!rst_n)
			flag	<= 'd1;
		else if(filter_cnt==filter_cnt_end)
			flag 	<=	'd1;	
		else
			flag 	<=	'd0;
end

always@(posedge clk or negedge rst_n )begin
		if(!rst_n)
			filter	<= 'd0;
		else if(flag==1)
			filter	<=puls_tt;
		else
			filter <= filter;
end

endmodule

