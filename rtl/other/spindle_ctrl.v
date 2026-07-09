module spindle_ctrl(       
	input clk,  
	input rstn,   
	
	input start_flag,
	input s_dir_flag,
	input	vfd_rst_flag,     
	input [2:0] flag, 
	
	output  reg vfd_M0, 
	output  reg vfd_M1, 
	output  reg vfd_M2, 
	output  reg vfd_M3,
	output  reg vfd_M4,
	output  reg vfd_M5	
);


always @(posedge clk or negedge rstn) 
begin
	if(!rstn )
		begin
			vfd_M3 <= 1'b0; vfd_M4 <= 1'b0; vfd_M5 <= 1'b0;
		end
	else begin
		case(flag)
		3'b001:  begin vfd_M3 <= 1'b1; vfd_M4 <= 1'b0; vfd_M5 <= 1'b0; end
		3'b010:  begin vfd_M3 <= 1'b0; vfd_M4 <= 1'b1; vfd_M5 <= 1'b0; end
		3'b011:  begin vfd_M3 <= 1'b1; vfd_M4 <= 1'b1; vfd_M5 <= 1'b0; end
		3'b100:  begin vfd_M3 <= 1'b0; vfd_M4 <= 1'b0; vfd_M5 <= 1'b1; end
		3'b101:  begin vfd_M3 <= 1'b1; vfd_M4 <= 1'b0; vfd_M5 <= 1'b1; end
		3'b110:  begin vfd_M3 <= 1'b0; vfd_M4 <= 1'b1; vfd_M5 <= 1'b1; end
		3'b111:  begin vfd_M3 <= 1'b1; vfd_M4 <= 1'b1; vfd_M5 <= 1'b1; end
		default: begin vfd_M3 <= 1'b0; vfd_M4 <= 1'b0; vfd_M5 <= 1'b0; end
		endcase
	end
end

always @(posedge clk or negedge rstn ) 
begin
	if(!rstn )
		vfd_M0 <= 1'b0;
	else if(start_flag == 1)
		vfd_M0 <= 1'b1;
		else
		vfd_M0 <= 1'b0;
end

always @(posedge clk or negedge rstn ) 
begin
	if(!rstn )
		vfd_M1 <= 1'b0;
	else if(s_dir_flag == 1)
		vfd_M1 <= 1'b1;
		else
		vfd_M1 <= 1'b0;
end

always @(posedge clk or negedge rstn ) 
begin
	if(!rstn )
		vfd_M2 <= 1'b0;
	else if(vfd_rst_flag == 1)
		vfd_M2 <= 1'b1;
		else
		vfd_M2 <= 1'b0;
end

endmodule
