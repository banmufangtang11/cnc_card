//-------v5.0---------
module tool_set_ctrl(clk,rst_ts,aux_data,
                                enable_tlset); 

	input  			clk		; //use tlpclk
	input  			rst_ts		;  //reset this module 
	input  			[31:0]aux_data;  //command data, the bit31-0 in 32bits data
//	input trigger,      //toolsetter probe trigger 
//	input out_range,   //toolsetter probe run out of range
//	input breakdown,   //toolsetter breakdown
	
//	output  reg[31:0] aux_feedback; //save in the auxiliary function feedback register
	output  reg	enable_tlset; //enable the toolsetter

	
	always@(posedge clk or negedge rst_ts) 
	     begin
              	if(!rst_ts) 
					     begin
					              enable_tlset<=1'b0;
								end
					else   
					     begin
						        case (aux_data[3:0])      //a latch
								        4'b0010: enable_tlset<=1'b1;    //enable
										  4'b0011: enable_tlset<=1'b0;    //enable cancel
								  endcase
						  end
	     end

endmodule
