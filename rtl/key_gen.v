`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:20:11 12/09/2014 
// Design Name: 
// Module Name:    key_gen 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module key_gen(
		input		clk					,
    	input 		key1				,
    	input 		key2				, 
    	input 		key3				,
		
    	output 	reg	key1_rdy			,
    	output 	reg	key2_rdy			,
    	output 	reg	key3_rdy			
    	);
//********signal define*********//
	reg	[21:0] 	count1;	//max is 4194303.
	reg	[21:0] 	count2;
	reg	[21:0] 	count3;	
	reg	[21:0]	c_max	=	4194303;	//4194;	//
	reg	[21:0]	c_button=	4000000;	//4000;		
//******signal define end*******// 
//***********process************//
//---------------------key qu dou.����----------------------
	always @(posedge clk)
	begin
		if(key1==1)
		begin
			if(count1<c_max)
				count1 	<= count1 + 1;
			else
				count1	<=	count1;
		end
		else
		begin
			count1 <= 0;
		end
		
		//gen rising_edge of key1.
		if(count1==c_button)  //延时 1/125*10^6Hz*4000000 秒
			key1_rdy	<=	1;	
		else
			key1_rdy	<=	0;
	end
 //-------------------����------------------
	always @(posedge clk)
	begin
		if(key2==1)
		begin
			if(count2<c_max)
				count2 	<= count2 + 1;
			else
				count2	<=	count2;
		end
		else
		begin
			count2 <= 0;
		end
		
		if(count2==c_button)
			key2_rdy	<=	1;
		else
			key2_rdy	<=	0;
	end
//--------------------����-----------------
	always @(posedge clk)
	begin
		if(key3==1)
		begin
			if(count3<c_max)
				count3 	<= count3 + 1;
			else
				count3	<=	count3;
		end
		else
		begin
			count3 <= 0;
		end
		
		if(count3==c_button)
			key3_rdy	<=	1;
		else
			key3_rdy	<=	0;
	end
//*********process end**********//

endmodule
