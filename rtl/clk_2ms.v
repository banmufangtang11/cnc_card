//valid有效时开始产生读fifo信号，间隔2ms
module	clk_2ms(clk,valid,clkout,empty);
input	clk,valid,empty;
output	clkout; //读有效信号
reg		clkout;
reg		[17:0] counter;

always @(posedge clk)
  begin
	if(!empty && valid)
		begin if(counter == 18'h3d090)
				  begin clkout <= 1'b1; counter <= 18'h0; end
			  else  	
				  begin counter <= counter + 18'h1; clkout <= 1'b0; end
		end
	else
		begin	clkout <= 1'b0; counter <= 18'h0; end
	
  end
endmodule 