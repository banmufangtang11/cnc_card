//-----------v5.0 begin------------
module tool_mag_ctrl(clk,rst_tm,aux_data, ahe_fin,back_fin,rot_count,loos_fin,clr_counts,
                                  aux_feedback,enable_tlmag,go,back,rot_dir,rot,tool_loos,use_axis8
											 );  

	input  			clk		; //using tlpclk
	input  			rst_tm		;  //reset this module 
	input  			[31:0]aux_data; //command data, the bit31-0 in 32bits data
	input ahe_fin;     //tool magazine go ahead finished
	input back_fin;  //tool magazine go backward finished
	input rot_count;   //servo motor rotating count 
	input loos_fin;  //spindle loose the tool 
	input clr_counts;  //clear the rot_number and count_pul  5.9.4.1
	
	output  reg	[31:0] aux_feedback;  //feedback the change finished
	output  reg	enable_tlmag;  //enable the motor, 1 is enable 
	output reg go;  //dive the go ahead cylinder
	output reg back;  //dive the go back cylinder
	output reg rot_dir;  //motor rotate direction, 1 is clockwise, 0 is counter-clockwise
	output reg rot;  //motor pulse
	output reg tool_loos;  //make spindle loose the tool, 0 is loosing
	output reg use_axis8;   //now I use 8th axis to acting rotate. control the "co8", 1 is on
	
	
	//some unused register
	//reg[31:0] aux_data_in;
	//reg[31:0] aux_back_out;
	//reg[3:0]  aux_data_bit30;
	//reg[4:0]   aux_data_bit84;

   reg  [19:0] count15=20'haaaa;  //turnning 15 degree needs 43690 pulse
   reg  [19:0] target_number;  //How many 15 degrees does it take to determine rotation
	reg  [19:0] rot_number;  //rotate number to count the rot_count
	reg  [19:0] count_pul;   //to count the number of reversals
	reg  rot_state;   //rotate state to keep the aux_data, 1 is rotating
	
	reg [15:0] time_delay;  ////count to 16'h3d09, then turn over the pulse state  5.9.4.1
	reg [6:0] time_delay_two;    //count 7'h7d
	
	
//------count the time of rotate	
/*always@( negedge rot_count or posedge clr_counts )begin
      if(clr_counts==1'b1) rot_number<=20'h0;
		else rot_number<=rot_number+20'h1;
end*/

always@(posedge clk or negedge rst_tm)begin
      if(!rst_tm) 
		     begin 
				rot_number<=20'h0;	
		     end
		else     //5.9.4.1
         begin		
		      if(clr_counts==1'b1)   
				  begin 
				    rot_number<=20'h0;	
					 time_delay_two<=7'h0;
		        end
	         else  
				  begin
				     if(rot_count==1'b0)
				        begin
						     if(time_delay_two==7'h7d)   //delay 1us
							      begin
									   rot_number<=rot_number+20'h1;
										time_delay_two<=7'h0;
									end
							  else
							      begin
									   rot_number<=rot_number;
										time_delay_two<=time_delay_two+7'h1;
									end
						  end
				  
				  end
			end
end


//-----------------------rotate control----------------------------
             //-pulse making and counting   818
always@( posedge clk or negedge rst_tm)begin
   if(!rst_tm) 
		     begin 
					rot<=1'b0;
					rot_dir <=1'b0;
					//target_number=20'h0;  
		      end
	else
	     begin
		     if(rot_state==1'b1 ) 
			    begin
				    if(time_delay==16'h3d09)		 
					     begin
			              rot<=~rot; 
							  rot_dir<=1'b1;
						     count_pul<=count_pul+20'h1;
							  time_delay<=16'h0;
						  end
					 else
				        begin
						     time_delay<=time_delay+16'h1;
							  rot<=rot;
							  rot_dir<=rot_dir;
						  end 
				  end 
            else 
              begin
	              rot<=1'b0;
					  rot_dir <=1'b0;
					  count_pul<=20'h0;
					  time_delay<=16'h0;
	           end
		  end

end
	
//--------------------------------control data assign-----------------------------------------------------	
always@( posedge clk or negedge rst_tm)begin
	   if(!rst_tm) 
		     begin      //initial when reset
		              enable_tlmag<=1'b0;
						  go<=1'b0;
						  back<=1'b0;
						  tool_loos<=1'b0;
						  rot_state<=1'b0;
		      end
	   else 
	     begin
				//reset the state if magazine stopped at the target tool
				if(rot_number==target_number)  //v5.8.3.2
				           begin
					               rot_state<=1'b0;   //stop rotating
									   use_axis8<=1'b0; 	
		             			   target_number<=20'h0;
								 end	 		       
				
            //---judge tool number----5bits				  //latch type
				case(aux_data[8:4])
				       //5'b00000 : target_number<=20'h0;
				       5'b00001 : target_number<=20'h1;
						 5'b00010 : target_number<=20'h2;
						 5'b00011 : target_number<=20'h3;
						 5'b00100 : target_number<=20'h4;
						 5'b00101 : target_number<=20'h5;
						 5'b00110 : target_number<=20'h6;
						 5'b00111 : target_number<=20'h7;
						 5'b01000 : target_number<=20'h8;
						 5'b01001 : target_number<=20'h9;
						 5'b01010 : target_number<=20'ha;
						 5'b01011 : target_number<=20'hb;
						 5'b01100 : target_number<=20'hc;
						 5'b01101 : target_number<=20'hd;
						 5'b01110 : target_number<=20'he;
						 5'b01111 : target_number<=20'hf;
						 5'b10000 : target_number<=20'h10;
						 5'b10001 : target_number<=20'h11;
						 5'b10010 : target_number<=20'h12;
						 5'b10011 : target_number<=20'h13;
						 5'b10100 : target_number<=20'h14;
						 5'b10101 : target_number<=20'h15;
						 5'b10110 : target_number<=20'h16;
						 5'b10111 : target_number<=20'h17;
						 5'b11000 : target_number<=20'h18;    //magazine have 24 tools
						 //default : target_number=20'd0;
				  endcase   
				
				//-------just assign without considering feedback signals---4bits
				//don't use "else if & else", try to make a latch
				if (aux_data[3:0] == 4'b0100) begin         //m code:m50 -> 4H
				         enable_tlmag<=1'b1;
				       end
				if (aux_data[3:0] == 4'b0101) begin         //m code:m51 -> 5H
				         enable_tlmag<=1'b0;
				       end
	         if (aux_data[3:0] == 4'b0110) begin         //m code:m52 -> 6H
				         go<=1'b1;
				       end
				if (aux_data[3:0] == 4'b0111) begin         //m code:m56 -> 7H
				         back<=1'b1;
				       end
	         if (aux_data[3:0] == 4'b1000) begin         //m code:m53 -> 8H
				         tool_loos<=1'b1;   //v5.9.4.2
				       end
	         if (aux_data[3:0] == 4'b1001) begin         //m code:m55 -> 9H
				         tool_loos<=1'b0;    //v5.9.4.2
				       end
				if (aux_data[3:0] == 4'b1010 )  begin            //m code:m54 -> AH
				          rot_state<=1'b1;  	
				          //rot_dir<=1'b0;  //v5.8.3.2
							 use_axis8<=1'b1;
						  end	 		
							 
				//------accept feedback signals and refect
            if(ahe_fin == 1'b0) begin
					           go<=1'b0;     //stop going ahead
					      end 
				if(back_fin == 1'b0) begin
					           back<=1'b0;     //stop going back
							end
			
		  end			
end


				 
//------------------------some feedback data making------32bits-------------------------------	
always@( posedge clk or negedge rst_tm)begin	
		if(!rst_tm) begin	
				               aux_feedback<=32'b0000_0000_0000_0000_0000_0000_0000_0000;
							end
					else 	
					    begin
					        if(back_fin==1'b0 && enable_tlmag==1'b0) 
					          begin     
					            aux_feedback<=32'b00000000000000000000000001000000;  //judging tool change complieted or not
								 end
							  else if(rot_state==1'b0)   //5.10.2 add
							     begin     
					            aux_feedback<=32'b00000000000000000000000000001000;  //judging rotate complieted or not
								  end
							  else      //5.10.2 add
							     begin     
					            aux_feedback<=32'b00000000000000000000000000000000;  
								  end
                   end	
end	
	 
  
endmodule
//----------v5.0 end-------------