//�㶯����ģ��
module	jog(clk,pos_x,neg_x,pos_y,neg_y,pos_z,neg_z,pos_a,neg_a,s1,s2,s3,s4,s5,s6,dir_x,dir_y,dir_z,dir_a,puls_x,puls_y,puls_z,puls_a);


input	clk,pos_x,neg_x,pos_y,neg_y,pos_z,neg_z,neg_a,pos_a,s1,s2,s3,s4,s5,s6;
output	dir_x,dir_y,dir_z,dir_a,puls_x,puls_y,puls_z,puls_a;


reg		dir_x,dir_y,dir_z,dir_a,puls_x,puls_y,puls_z,puls_a;
reg		flag1,flag2,flag3,flag4,flag5,flag6,flag7,flag8;
reg     f1,f2,f3,f4,f5,f6;
reg		[6:0] count1,count2,count3,count4,count5,count6,count7,count8;
reg     [6:0] c1,c2,c3,c4,c5,c6;
reg		[15:0]count11,count12,count13,count14,count15,count16,count17,count18;
//------------------------------------------------------------------------
always @(posedge clk )
	begin
	if(neg_x)//-x
		begin
		if(count1 == 7'h7d)//消抖 1us
			begin flag1 <= 1'b1; count1 <= 7'h0; end
		else
			begin flag1 <= flag1; count1 <= count1 + 7'h1; end
		end
	else
		begin
		flag1 <= 1'b0; count1 <= 7'h0;
		end
	end
//----------------------------------------------------------------------------
always @(posedge clk )
	begin
	if(pos_x)//+x
		begin
		if(count2 == 7'h7d)//xiao'dou 1us
			begin flag2 <= 1'b1; count2 <= 7'h0; end
		else
			begin flag2 <= flag2; count2 <= count2 + 7'h1; end
		end
	else
		begin
		flag2 <= 1'b0; count2 <= 7'h0;
		end
	end
//----------------------------------------------------------------------------
always @(posedge clk)
	begin
	if(neg_y)//-y
		begin
		if(count3 == 7'h7d)//xiao'dou 1us
			begin flag3 <= 1'b1; count3 <= 7'h0; end
		else
			begin flag3 <= flag3; count3 <= count3 + 7'h1; end
		end
	else
		begin
		flag3 <= 1'b0; count3 <= 7'h0;
		end
	end
//----------------------------------------------------------------------------
always @(posedge clk )
	begin
	if(pos_y)//+y
		begin
		if(count4 == 7'h7d)//xiao'dou 1us
			begin flag4 <= 1'b1; count4 <= 7'h0; end
		else
			begin flag4 <= flag4; count4 <= count4 + 7'h1; end
		end
	else
		begin
		flag4 <= 1'b0; count4 <= 7'h0;
		end
	end
//----------------------------------------------------------------------------
always @(posedge clk)
	begin
	if(neg_z)//-z
		begin
		if(count5 == 7'h7d)//xiao'dou 1us
			begin flag5 <= 1'b1; count5 <= 7'h0; end
		else
			begin flag5 <= flag5; count5 <= count5 + 7'h1; end
		end
	else
		begin
		flag5 <= 1'b0; count5 <= 7'h0;
		end
	end
//----------------------------------------------------------------------------
always @(posedge clk)
	begin
	if(pos_z)//+z
		 begin
		if(count6 == 7'h7d)//��ʱ1us��ȥ����
			begin flag6 <= 1'b1; count6 <= 7'h0; end
		else
			begin flag6 <= flag6; count6 <= count6 + 7'h1; end
		end
	else
		begin
		flag6 <= 1'b0; count6 <= 7'h0;
		end
	end
//----------------------------------------------------------------------------
//---------------------------------------------------------------------------------
always @(posedge clk)
	begin
	if(s1)
			begin if(c1 == 7'h7d)//xiao'dou 1us
						begin f1 <= 1'b1; c1 <= 7'h0; end
				  else
						begin c1 <= c1 + 7'h1; end
			end
	else
		begin f1 <= 1'b0; c1 <= 7'h0; end
  end	
//---------------------------------------------------------------------------------
//---------------------------------------------------------------------------------
always @(posedge clk )
	begin
	if(s2)
			begin if(c2 == 7'h7d)//xiao'dou 1us
						begin f2 <= 1'b1; c2 <= 7'h0; end
				  else
						begin c2 <= c2 + 7'h1; end
			end
	else
		begin f2 <= 1'b0; c2 <= 7'h0; end
  end	
//---------------------------------------------------------------------------------
//---------------------------------------------------------------------------------
always @(posedge clk )
	begin
	if(s3)
			begin if(c3 == 7'h7d)//xiao'dou 1us
						begin f3 <= 1'b1; c3 <= 7'h0; end		//f3为消抖后的s3
				  else
						begin c3 <= c3 + 7'h1; end
			end
	else
		begin f3 <= 1'b0; c3 <= 7'h0; end
  end	
//---------------------------------------------------------------------------------
//---------------------------------------------------------------------------------
always @(posedge clk)
	begin
	if(s4)
			begin if(c4 == 7'h7d)//xiao'dou 1us
						begin f4 <= 1'b1; c4 <= 7'h0; end
				  else
						begin c4 <= c4 + 7'h1; end
			end
	else
		begin f4 <= 1'b0; c4 <= 7'h0; end
  end	
//---------------------------------------------------------------------------------
//---------------------------------------------------------------------------------
always @(posedge clk)
	begin
	if(s5)
			begin if(c5 == 7'h7d)//xiao'dou 1us
						begin f5 <= 1'b1; c5 <= 7'h0; end
				  else
						begin c5 <= c5 + 7'h1; end
			end
	else
		begin f5 <= 1'b0; c5 <= 7'h0; end
  end	
//---------------------------------------------------------------------------------
//---------------------------------------------------------------------------------
always @(posedge clk)
	begin
	if(s6)
			begin if(c6 == 7'h7d)//xiao'dou 1us
						begin f6 <= 1'b1; c6 <= 7'h0; end
				  else
						begin c6 <= c6 + 7'h1; end
			end
	else
		begin f6 <= 1'b0; c6 <= 7'h0; end
  end	
//---------------------------------------------------------------------------------
always @(posedge clk )
 begin 
      if(flag1)			//flag为1 代表按键按下
       begin
			if(f3)			//f3为消抖后的s3
			  begin dir_x<= 1'b0; puls_x <= 1'b0; end//dir=0为负
			  
			else
			 begin 
			    if(count11 == 16'h3d09)
				begin dir_x <= 1'b0; puls_x <= ~ puls_x; count11 <= 16'h0; end//脉宽为0-h3d09
				else
				begin dir_x <= 1'b0; puls_x <=  puls_x; count11 <= count11 + 16'h1; end
			 end
	   end
	  else if(flag2)
	    begin 
	          if(f2)
	           begin dir_x<= 1'b0 ; puls_x <= 1'b0; end
	           else 
	           begin
				if(count12 == 16'h3d09)
					begin dir_x <= 1'b1; puls_x <= ~ puls_x; count12 <= 16'h0; end
				else
					begin dir_x <= 1'b1; puls_x <=   puls_x; count12 <= count12 + 16'h1; end
				end	
		end
		else begin	dir_x <= 1'b0; puls_x <= 1'b0; count11 <= 16'h0; count12 <= 16'h0; end//默认

 end
//---------------------------------------------------------------------------
always @(posedge clk )
 begin 
 
     if(flag3)
       begin
			if(f4)
			  begin dir_y<= 1'b0; puls_y <= 1'b0; end
			  
			else
			 begin 
			    if(count13 == 16'h3d09)
				begin dir_y <= 1'b0; puls_y <= ~ puls_y; count13 <= 16'h0; end
			else
				begin dir_y <= 1'b0; puls_y <=  puls_y; count13 <= count13 + 16'h1; end
			 end
	   end
	  else if(flag4)
	    begin 
	          if(f1)
	           begin dir_y<= 1'b0 ; puls_y <= 1'b0; end
	           else 
	           begin
				if(count14 == 16'h3d09)
					begin dir_y <= 1'b1; puls_y <= ~ puls_y; count14 <= 16'h0; end
				else
					begin dir_y <= 1'b1; puls_y <=   puls_y; count14 <= count14 + 16'h1; end
			   end	
		end
		else begin	dir_y <= 1'b0; puls_y <= 1'b0; count13 <= 16'h0; count14 <= 16'h0; end

 end 
//-------------------------------------------------------------------------------
always @(posedge clk )
 begin 
 
     if(flag5)
       begin
			if(f5)
			  begin dir_z<= 1'b0; puls_z <= 1'b0; end
			  
			else
			 begin 
			    if(count15 == 16'h3d09)
				begin dir_z <= 1'b0; puls_z <= ~ puls_z; count15 <= 16'h0; end
			else
				begin dir_z <= 1'b0; puls_z <=  puls_z; count15 <= count15 + 16'h1; end
			 end
	   end
	  else if(flag6)
	    begin 
	          if(f6)
	           begin dir_z<= 1'b0 ; puls_z <= 1'b0; end
	           else 
	           begin
				if(count16 == 16'h3d09)
					begin dir_z <= 1'b1; puls_z <= ~ puls_z; count16 <= 16'h0; end
				else
					begin dir_z <= 1'b1; puls_z <=   puls_z; count16 <= count16 + 16'h1; end
			   end	
		end
		else begin	dir_z <= 1'b0; puls_z <= 1'b0; count15 <= 16'h0; count16 <= 16'h0; end

 end

//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------
always @(posedge clk)
	begin
	if(neg_a)//-z
		begin
		if(count7 == 7'h7d)//消抖 1us
			begin flag7 <= 1'b1; count7 <= 7'h0; end
		else
			begin flag7 <= flag7; count7 <= count7 + 7'h1; end
		end
	else
		begin
		flag7 <= 1'b0; count7 <= 7'h0;
		end
	end
//----------------------------------------------------------------------------
always @(posedge clk)
	begin
	if(pos_a)
		 begin
		if(count8 == 7'h7d)//消抖 1us
			begin flag8 <= 1'b1; count8 <= 7'h0; end
		else
			begin flag8 <= flag8; count8 <= count8 + 7'h1; end
		end
	else
		begin
		flag8 <= 1'b0; count8 <= 7'h0;
		end
	end
//----------------------------------------------------------------------------
//--------------------------------------------------------------------------------
//-------------------------------------------------------------------------------
always @(posedge clk )
 begin 
 
     if(flag7)
       begin
			if(f5)
			  begin dir_a<= 1'b0; puls_a <= 1'b0; end
			  
			else
			 begin 
			    if(count17 == 16'h3d09)
				begin dir_a <= 1'b0; puls_a <= ~ puls_a; count17 <= 16'h0; end
			else
				begin dir_a <= 1'b0; puls_a <=  puls_a; count17 <= count17 + 16'h1; end
			 end
	   end
	  else if(flag8)
	    begin 
	          if(f6)
	           begin dir_a<= 1'b0 ; puls_a <= 1'b0; end
	           else 
	           begin
				if(count18 == 16'h3d09)
					begin dir_a <= 1'b1; puls_a <= ~ puls_a; count18 <= 16'h0; end
				else
					begin dir_a <= 1'b1; puls_a <=   puls_a; count18 <= count18 + 16'h1; end
			   end	
		end
		else begin	dir_a <= 1'b0; puls_a <= 1'b0; count17 <= 16'h0; count18 <= 16'h0; end

 end

// always @(posedge clk )
// begin
//   if(s1)
//	  begin dir_x<= 1'b0; puls_x <= 1'b0; dir_y<= 1'b0; puls_y <= 1'b0; dir_z<= 1'b0; puls_z <= 1'b0; dir_a<= 1'b0; puls_a <= 1'b0;
//	  end
// end
 
//----------------------------------------------------------------------------------
endmodule 
