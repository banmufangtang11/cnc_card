module	check(clk,start,stop,empty,valid,s1,s2,s3,s4,s5,s6,s7);   //add s7(s7 is connected to aux_intrupt) --v5.13.1
input	clk,start,stop,empty,s1,s2,s3,s4,s5,s6,s7;
output	valid;

reg		flag_start,flag_stop,valid,f1,f2,f3,f4,f5,f6,f7;  //add f7 --v5.13.1
reg		[6:0] count1,count2;
reg     [6:0] c1,c2,c3,c4,c5,c6,c7;    //add c7 --v5.13.1
//----------------------------------------------------------------------------------
always @(posedge clk)
  begin
	if(start)
			begin if(count1 == 7'h7d)//��ʱ1us��ȥ����
						begin flag_start <= 1'b1; count1 <= 7'h0; end
				  else
						begin count1 <= count1 + 7'h1; end
			end
	else
		begin flag_start <= 1'b0; count1 <= 7'h0; end
  end	
//----------------------------------------------------------------------------------	
always @(posedge clk )
  begin
	if(stop)
			begin if(count2 == 7'h7d)//��ʱ1us��ȥ����
						begin flag_stop <= 1'b1; count2 <= 7'h0; end
				   else
						begin count2 <= count2 + 7'h1; end			
			end
	else
		begin flag_stop <= 1'b0; count2 <= 7'h0; end
  end
//---------------------------------------------------------------------------------
always @(posedge clk )
  begin
	 if(s1)
			begin if(c1 == 7'h7d)//��ʱ1us��ȥ����
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
			begin if(c2 == 7'h7d)//��ʱ1us��ȥ����
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
			begin if(c3 == 7'h7d)//��ʱ1us��ȥ����
						begin f3 <= 1'b1; c3 <= 7'h0; end
				  else
						begin c3 <= c3 + 7'h1; end
			end
	else
		begin f3 <= 1'b0; c3 <= 7'h0; end
  end	
//---------------------------------------------------------------------------------
//---------------------------------------------------------------------------------
always @(posedge clk )
  begin
	if(s4)
			begin if(c4 == 7'h7d)//��ʱ1us��ȥ����
						begin f4 <= 1'b1; c4 <= 7'h0; end
				  else
						begin c4 <= c4 + 7'h1; end
			end
	else
		begin f4 <= 1'b0; c4 <= 7'h0; end
  end	
//---------------------------------------------------------------------------------
//---------------------------------------------------------------------------------
always @(posedge clk )
  begin
    if(s5)
			begin if(c5 == 7'h7d)//��ʱ1us��ȥ����
						begin f5 <= 1'b1; c5 <= 7'h0; end
				  else
						begin c5 <= c5 + 7'h1; end
			end
	else
		begin f5 <= 1'b0; c5 <= 7'h0; end
  end	
//---------------------------------------------------------------------------------
//---------------------------------------------------------------------------------
always @(posedge clk )
  begin
	if(s6)
			begin if(c6 == 7'h7d)//��ʱ1us��ȥ����
						begin f6 <= 1'b1; c6 <= 7'h0; end
				  else
						begin c6 <= c6 + 7'h1; end
			end
	else
		begin f6 <= 1'b0; c6 <= 7'h0; end
  end	
//---------------------------------------------------------------------------------
//---------v5.13.1----------------------------------------------------------------
always @(posedge clk )
  begin
	if(s7)
			begin if(c7 == 7'h7d)   //delay 1 us, to eliminate the effects of mistouch
						begin f7 <= 1'b1; c7 <= 7'h0; end
				  else
						begin c7 <= c7 + 7'h1; end
			end
	else
		begin f7 <= 1'b0; c7 <= 7'h0; end
  end	 
//---------------------------------------------------------------------------------
always @(posedge clk )
  begin
	    if(flag_stop)
			valid <= 1'b0;
		 else if(f1)
			valid <= 1'b0;
	    else if(f2)
			valid <= 1'b0;
	    else if(f3)
			valid <= 1'b0;
	    else if(f4)
			valid <= 1'b0;
	    else if(f5)
			valid <= 1'b0;
	    else if(f6)
			valid <= 1'b0;
		 else if(f7)      //v5.13.1
			valid <= 1'b0;
		 else if(flag_start)
			valid <= 1'b1;
		 else if(empty)
			valid <= 1'b0;
		else
	    valid <= 1'b0;

  end

endmodule




