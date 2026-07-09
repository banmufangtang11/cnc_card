module	clk_1s(clk,clkout);
input	clk;
output	clkout; 
reg		clkout;
reg		[28:0] counter;

always @(posedge clk)
  begin
	
		 if(counter == 28'h7735940)
				  begin clkout <= ~clkout; counter <= 18'h0; end
			  else  	
				  begin counter <= counter + 18'h1; clkout <= clkout; end
		end
  
endmodule 