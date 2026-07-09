module encode_pd(
	 // system signals
	input  			clk		,
	input  			rst_n		,
	// others
	input  			plus_A 	,
	input  			 plus_B	,	
	input				renew,
	
	output  reg	[31:0] delta_count,
	output  reg	[31:0] total_count
);

//================================================================\
// ========= Define Parameter and Internal Signals ==========
//================================================================/
reg [17:0] clk_cnt;

reg [31:0] count_up	;
reg [31:0] count_down ;

reg [31:0] count_up_t	;
reg [31:0] count_down_t ;

	reg dir_reg;	
	reg signal_C;
	reg signal_D;
	
	reg count_plus;
	
	reg plus_A_tt;
	reg plus_A_t;
	reg plus_B_t;
	
reg delta_flag;

	reg delta_flag_tt;
	reg delta_flag_t;
	wire delta_pos;
//================================================================\
// ****************     Main    Code    **************
//================================================================/
assign delta_pos = (!delta_flag_tt & delta_flag_t);

always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			clk_cnt	<= 1'b0;
		else if(clk_cnt=='d99999)
			clk_cnt	<= 1'b0;
		else 
			clk_cnt	<= clk_cnt + 1'b1;		
end

always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			delta_flag	<= 1'b0;
		else if(clk_cnt=='d99999)
			delta_flag	<= 1'b1;
		else 
			delta_flag	<= 1'b0;		
end

always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			begin
				delta_flag_t  <=1'b0 ;
				delta_flag_tt   <=1'b0 ;
			end	
		else
			begin
				delta_flag_t   <=	delta_flag 	;
				delta_flag_tt  <=	delta_flag_t ;
			end	
end

always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			signal_C	<= 1'b0;
		else
			signal_C <= plus_A ^ plus_B;  //异或
end

always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			signal_D	<= 1'b0;
		else
			signal_D <= signal_C;
end

always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			count_plus	<= 1'b0;
		else
			count_plus <= signal_C ^ signal_D;
end

always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			begin
				plus_A_tt  <=1'b0 ;
				plus_A_t   <=1'b0 ;
			end	
		else if(count_plus==1)
			begin
				plus_A_t   <=	plus_A 	;
				plus_A_tt  <=	plus_A_t ;
			end
		else
			begin
				plus_A_t   <=	plus_A_t 	;
				plus_A_tt  <=	plus_A_tt ;
			end	
end

always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
				plus_B_t   <=  1'b0 ;		
		else if(count_plus==1)
				plus_B_t   <=	plus_B 	;
		else
				plus_B_t	  <=  plus_B_t	;
end

always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			dir_reg	<= 1'b0;
		else
			dir_reg   <= plus_A_tt ^ plus_B_t;
end

always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			count_up	<= 'd0;			
		else if(renew==1)
			count_up	<= 'd0;
		else if(delta_pos==1)
			count_up	<= 'd0;
		else if(dir_reg==0 && count_plus==1)
			count_up	<= count_up + 1'b1;
		else
			count_up	<= count_up;
end

always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			count_down	<= 'd0;
		else if(renew==1)
			count_down	<= 'd0;
		else if(delta_pos==1)
			count_down	<= 'd0;
		else if(dir_reg==1 && count_plus==1 )
			count_down	<= count_down + 1'b1;
		else
			count_down	<= count_down;
end

always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			count_up_t	<= 'd0;
		else if(renew==1)
			count_up_t	<= 'd0;
		else if(dir_reg==0 && count_plus==1)
			count_up_t	<= count_up_t + 1'b1;
		else
			count_up_t	<= count_up_t;
end


always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			count_down_t	<= 'd0;
		else if(renew==1)
			count_down_t	<= 'd0;
		else if(dir_reg==1 && count_plus==1 )
			count_down_t	<= count_down_t + 1'b1;
		else
			count_down_t	<= count_down_t;
end

always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			delta_count	<= 'd0;	
		else if(delta_flag	== 1'b1)
			delta_count <= count_up + count_down;
		else
			delta_count <= delta_count;
end

always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			total_count	<= 'd0;	
		else if(delta_flag	== 1'b1)
			total_count <= count_up_t + count_down_t;
		else
			total_count <= total_count;
end


endmodule
