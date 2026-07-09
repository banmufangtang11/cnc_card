//-----------v5.0---------------
module aux_fbac(       //auxiliary feedback module
	input  clk,  //use tlpclk
	input  rst,  //reset this module 
	
	input  [31:0]data,  //32bits feedback data 
	
	//toolsetter's
	input trigger,      //toolsetter probe trigger 
	input out_range,   //toolsetter probe run out of range
	input breakdown,   //toolsetter breakdown
	
	//tool magazine's
	input ahe_fin,     //tool magazine go ahead finished
	input back_fin,  //tool magazine go backward finished
	input rot_count,   //servo motor rotating count 
	input loos_fin,  //spindle loose the tool 
	
	output  reg[31:0] data_para, //to the auxiliary feedback register 
	output  reg aux_intrupt  //to the auxiliary feedback register,
);


always@(posedge clk or negedge rst) begin
              if(!rst) 
				       begin
						      data_para<=32'b00000000000000000000000000000000;
								aux_intrupt<=1'b0;
						 end
				  else 
				       begin
				         if(trigger==1'b1) begin   //probe trigger                          
								      aux_intrupt<=1'b1;  //to stop z axis's action
										data_para[0]<=1'b1;  //bit0 assign 1 
										end
						   else begin    //normal state							     
								     aux_intrupt<=1'b0;
								     data_para[0]<=1'b0;     									  
							        end								  
							//---5.10.2	  
							if(out_range==1'b1)    data_para[1]<=1'b1;    //bit1 assign 1
							if(out_range==1'b0)    data_para[1]<=1'b0;
							if(breakdown==1'b1)    data_para[2]<=1'b0;    //bit2 assign 1
							if(breakdown==1'b0)    data_para[2]<=1'b1;
				         if(data==32'b00000000000000000000000000001000) data_para[3]<=1'b1;   //bit3 assign 1
							if(ahe_fin == 1'b0)       data_para[4]<=1'b1;    //bit4 assign 1
							if(ahe_fin == 1'b1)       data_para[4]<=1'b0;
					      if(back_fin == 1'b0)      data_para[5]<=1'b1;    //bit5 assign 1
							if(back_fin == 1'b1)      data_para[5]<=1'b0;
				         if(data==32'b00000000000000000000000001000000) data_para[6]<=1'b1;  //bit6 assign 1
							if(data==32'b00000000000000000000000000000000) begin
								     data_para[3]<=1'b0;
									  data_para[6]<=1'b0;
							end
							if(loos_fin==1'b0)        data_para[7]<=1'b1;    //bit7 assign 1 
							if(loos_fin==1'b1)        data_para[7]<=1'b0;
							//--------
							
							
				      end
end
endmodule