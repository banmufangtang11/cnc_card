module puls_hw(clk,rstn,
					empty,q,i_x1,i_x10,i_x100,
					rdreq,puls_out);
input clk,rstn;
input empty;
input [21:0] q;
input i_x1,i_x10,i_x100;

output rdreq;
output puls_out;

reg [2:0] curr_state_F, next_state_F;
reg F_timer;
reg [7:0] c0,c1;
reg [21:0] sum;
reg p,rdreq;
reg [21:0] q_out;
reg [21:0] q_in;
reg puls_out;
reg q_sign;
reg [6:0] count1,count2,count3;
reg flag1,flag2,flag3;

parameter [2:0] F0 = 3'b011,		//脉冲序列输出状态代hao 
					 F1 = 3'b100,
					 F2 = 3'b101,
					 F3 = 3'b110;

//-----------------------------------------判断计数值是否输��ckh18.12.03------------------
always @(posedge clk or negedge rstn)
begin
	if(!rstn) 
		begin q_sign <= 1'b0; end
	else
		begin
			if(q_in == 22'h0)		q_sign <= 1'b0;
			else						q_sign <= 1'b1;
		end
end

//-------------------------------------------------------------------------------
always @(posedge clk )
begin
	if(!rstn)
		begin
			flag1 <= 1'b0; count1 <= 7'h0;
		end
	else
		begin
			if(!i_x1)
				begin
					if(count1 == 7'h7d)//xiaodou  1us
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
			if(!i_x10)
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
	if(!i_x100)
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
			
//----------------------------------------------------------------------------------					 
//----------------------------------------------------------------------------------
always @(posedge clk or negedge rstn)			//倍率选择
begin
	if(!rstn)
		begin c0 <= 8'h0; end
	else
		begin
			if(flag1) 		 	c0 <= 8'h2;		//=2   1.75um
			else if(flag2)		c0 <= 8'hc;		//=12  10.5um
			else if(flag3)	   c0 <= 8'h20;	//=32  28um
			else					c0 <= 8'h0;
		end
end

//-----------------------------------------------------------------------------------
always @(posedge clk or negedge rstn)					//脉冲赋值输��
begin
	if(!rstn)
		begin puls_out <= 1'b0; end
	else
		begin puls_out <= p; end
end

//------------------------------------------------------------------------------------------
//-------------------------------------倍频脉冲序列输出状态机----------------------------------
//------------------------------------------------------------------------------------------

always @(posedge clk or negedge rstn) 
begin
	if(!rstn)
		curr_state_F <= F0;
	else
		curr_state_F <= next_state_F;
end
 
always @(clk or curr_state_F or empty or F_timer or c1 or q_sign) 
begin	
	case(curr_state_F)
	F0:	begin
  			if(empty)	         							next_state_F <= F0;
			else													next_state_F <= F1;
		end
	F1:	begin
			if(q_sign)											next_state_F <= F2;
			else													next_state_F <= F1;
		end
	F2:	begin
			if(F_timer == 1'b1)								next_state_F <= F3;	//F_timer == 1'b1满足计数
  			else													next_state_F <= F2;
		end
	F3:	begin
			if(c1 == c0 && empty == 1'b1)					next_state_F <= F0;
			else if(c1 == c0 && empty == 1'b0)			next_state_F <= F1;
			else													next_state_F <= F2;
		end
	default:begin
																	next_state_F <= F0;	// 不加这个default��输出会一直是000!!!
		end
	endcase
end
 
always @(posedge clk or negedge rstn) 
begin
	if(!rstn)
		begin c1 <= 8'h0; F_timer <= 1'b0; sum <= 22'h0; rdreq <= 1'b0; p <= 1'b0; q_out <= 22'h0; q_in <= 22'h0;  end
	else begin
		
		case(next_state_F)
		F0:	begin
				c1 <= 8'h0; F_timer <= 1'b0; sum <= 22'h0; rdreq <= 1'b0; p <= 1'b0; q_out <= 22'h0; q_in <= 22'h0;
			end
		F1:	begin
				c1 <= 8'h0; sum <= 22'h0; p <= 1'b0; q_out <= q_in; q_in <= q/c0;
				rdreq <= 1'b1;  F_timer <= 1'b0;
			end
		F2:	begin
				q_out <= q_in; rdreq <= 1'b0; c1 <= c1; p <= p; q_in <= q_in;
				if(sum >= q_out)			//设置输出单位脉冲序列周期的一半，输出电平翻转一次记一次数，单次倍频输出5个脉冲计数总值为10
					begin F_timer <= 1'b0; sum <= 22'h0; end
				else if(sum>=q_out/2 && sum<q_out)
					begin F_timer <= 1'b1; sum <= sum + c0; end
				else 
				   begin F_timer<=1'b0; sum<=sum+c0; end		//？？
			end
		F3:	begin
				p <= ~p; c1 <= c1 + 8'h1; rdreq <= 1'b0; q_out <= q_out; F_timer <= 1'b0; sum <= 22'h0; q_in <= q_in;
			end
		default:begin
				c1 <= 8'h0; F_timer <= 1'b0; sum <= 22'h0; rdreq <= 1'b0; p<= 1'b0; q_out <= 1'b0; q_in <= 22'h0;	//不加这个default 复位前信号都为不定值X
			end
		endcase
	end
end



endmodule
