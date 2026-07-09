module test(in_clk,rst_n,led1,led2);

input in_clk,rst_n;
output reg [55:0] led1;
output reg [25:0] led2;

wire   sys_clk,c1_40m,c2_250m,c3_50m;

cnc_pll	cnc_pll_inst (
	.inclk0 	( in_clk ),
	.c0 		( sys_clk ),        //100MHz
	.c1 		( c1_40m ),
	.c2 		( c2_250m ),
	.c3 		( c3_50m )
	);

	
//qsys
qsys u_qsys (
        .clk_clk       (sys_clk),       //   clk.clk
        .reset_reset_n (rst_n)  // reset.reset_n
    );

	
	

	
	
initial begin
	led1 <= 56'd0;
	led2 <= 26'd0;
end	


////test1	
//always@(posedge sys_clk or negedge rst_n) begin
//	if (!rst_n) begin
//		led1 <= 56'd0;
//		led2 <= 26'd0;
//		end
//	else begin
//		led1 = 56'hff_ffff_ffff_ffff;
//		led2 = 26'h3ff_ffff;
//		end
//	
//
//end 

//test2
reg [23:0] counter;
//计数器对系统时钟计数，计时**秒
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)
        counter <= 24'd0;
    else if (counter < 24'd0900_0000)		//0.2秒
        counter <= counter + 1'b1;
    else
        counter <= 24'd0;
end

//通过移位寄存器控制IO口的高低电平，从而改变LED的显示状态
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)
        led2[3:0] <= 4'b0001;
    else if(counter == 24'd0900_0000) 		//0.2秒
        led2[3:0] <= {led2[2:0],led2[3]};
    else
        led2 <= led2;
end

	
//assign led1 = 56'hff_ffff_ffff_ffff;
//assign led2 = 26'h3ff_ffff;

endmodule
