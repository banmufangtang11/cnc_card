module fsm_hw(clk,rstn,
				a_in,b_in,full,data,wrreq,dir_out
				);
input clk,rstn;
input a_in,b_in;
input full;
output wrreq,dir_out;
output [21:0] data;

reg a0,a1,b0,b1;
reg deal_sign;
reg dir_out;
reg S_timer;
reg [21:0] t0;
reg [21:0] data;
reg wrreq;

parameter [1:0] M0 = 2'b00,		//周期测量状态代��
					 M1 = 2'b01,
					 M2 = 2'b10;


//----------------------------------------------------------------------------------					 
always @(posedge clk or negedge rstn)
begin
	if(!rstn)
		begin a0 <= 1'b0; a1 <= 1'b0; b0 <= 1'b0; b1 <= 1'b0; end
	else
		begin 
			a0 <= a_in; a1 <= a0;			//D触发器延时处理手轮脉冲，用于信号边缘提取判断
			b0 <= b_in; b1 <= b0;
		end
end

//-------------------------------------------------------------------------------
always @(posedge clk or negedge rstn)
begin
	if(!rstn)
		begin deal_sign <= 1'b0; end
	else
		begin 
			deal_sign <= (a1 ^ a0) | (b1 ^ b0);  //异或运算，信号边缘提取，用于信号处理判断
		end
end

//----------------------------------------------------------------------------------		
always @(posedge a1 or negedge rstn)					//脉冲鉴相
begin
	if(!rstn) dir_out <= 1'b0;
	else
		begin
			if(b1 == 1'b0)	dir_out <= 1'b0;				//正方向
			else if(b1 == 1'b1)	dir_out <= 1'b1;		//反
			else	dir_out <= dir_out;
		end
end



//------------------------------------------------------------------------------------------
//---------------------------------------周期测量状态机---------------------------------------
//------------------------------------------------------------------------------------------

reg [1:0] curr_state_M, next_state_M;
 
always @(posedge clk or negedge rstn) 
begin
	if(!rstn)
		curr_state_M <= M0;
	else
		curr_state_M <= next_state_M;
end
 
always @(clk or curr_state_M or deal_sign or S_timer) 
begin	
	case(curr_state_M)
	M0:	begin
			if(!deal_sign)	         						next_state_M <= M0;
			else													next_state_M <= M1;
		end
	M1:	begin
			if(S_timer == 1'b0 && deal_sign == 1'b0)	next_state_M <= M1;
			else if(S_timer == 1'b1 && deal_sign == 1'b0)	next_state_M <= M0;	//stimer为1，说明超时（超过设定速度值），回到M0状态
			else													next_state_M <= M2;
		end
	M2:	begin
 			if(deal_sign == 1'b0)							next_state_M <= M1;	//要不要保持这个状态？
			else													next_state_M <= M2;
		end
	default:begin
																	next_state_M <= M0;	// 不加这个default，输出会一直是000!!!
		end
	endcase
end
 
always @(posedge clk or negedge rstn) 
begin
	if(!rstn)
		begin t0 <= 22'h0; S_timer <= 1'b0; data <= 22'h0; wrreq <= 1'b0; end
	else begin
		case(next_state_M)
		M0:	begin
				t0 <= 22'h0; S_timer <= 1'b0; data <= 22'h0; wrreq <= 1'b0;
			end
		M1:	begin
				//wrreq为0，data禁止送入FIFO
				data <= t0; wrreq <= 1'b0;
				if(t0 >= 22'h2625a0)
					begin S_timer <= 1'b1; t0 <= t0; end		//超时（超过设定速度值）
				else
					begin S_timer <= 1'b0; t0 <= t0 + 22'h1; end
			end
		M2:	begin
				if(full != 1'b1)
					begin wrreq <= 1'b1; data <= t0; t0 <= 22'h0; S_timer <= 1'b0; end
				else
					begin wrreq <= 1'b0; data <= 22'h0; t0 <= 22'h0; S_timer <= 1'b0; end
			end
		default:begin
				t0 <= 22'h0; S_timer <= 1'b0; data <= 22'h0; wrreq <= 1'b0;		//不加这个default 复位前信号都为不定值X
			end
		endcase
	end
end
 


endmodule
