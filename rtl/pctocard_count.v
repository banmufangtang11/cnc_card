module pctocard_count(
	 // system signals
	input  			clk		,
	input  			rst_n		,
	// others
	input  			plus		,
	input				dir      ,
	input				renew		,
	output  reg	[31:0] card_count
);

//================================================================\
// ========= Define Parameter and Internal Signals ==========
//================================================================/
reg [17:0] clk_cnt;

reg [31:0] count_up	;
reg [31:0] count_down ;

	
	
	reg plus_tt;
	reg plus_t;
wire 	plus_flag;

//================================================================\
// ****************     Main    Code    **************
//================================================================/
assign plus_flag = (!plus_tt & plus_t);
always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			begin
				plus_tt  <=1'b0 ;
				plus_t   <=1'b0 ;
			end	
		else
			begin
				plus_t   <=	plus 	;
				plus_tt  <=	plus_t ;
			end	
end

//always@(posedge clk or negedge rst_n)begin
//		if(!rst_n)
//			count_up	<= 'd0;
//		else if(renew==1)
//			count_up	<= 'd0;			
//		else if(dir==0 && plus_flag==1)
//			count_up	<= count_up + 1'b1;
//		else
//			count_up	<= count_up;
//end
//
//always@(posedge clk or negedge rst_n)begin
//		if(!rst_n)
//			count_down	<= 'd0;
//		else if(renew==1)
//			count_down	<= 'd0;			
//		else if(dir==1 && plus_flag==1 )
//			count_down	<= count_down + 1'b1;
//		else
//			count_down	<= count_down;
//end
//
//
//always@(posedge clk or negedge rst_n)begin
//		if(!rst_n)
//			card_count	<= 'd0;		
//		else
//			card_count <= count_up - count_down;
//end

always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			card_count	<= 'd0;	
		else if(renew==1)
			card_count	<= 'd0;	
		else if(plus_flag==1 )
			card_count <= card_count + 1'b1;
		else
			card_count <= card_count;
end

endmodule
