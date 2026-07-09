`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:41:40 12/13/2015 
// Design Name: 
// Module Name:    state_ctrl 
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
module state_ctrl_xy(
    	input 	i_clk	,
    	input 	i_reset	,
      input 	i_key_a	,
    	input 	i_key_b	,
    	input 	i_key_c	,
		input		z_finished,
		
    	output 	o_dir	,
    	output 	o_pluse ,
		output  o_set    //cch
    	);
	
	reg	[2:0]	r_state 	= 3'b000;	//״̬��״̬
	reg	[25:0]	r_cnt_data	=0;//����10KHZƵ�ʼ�����
	reg			r_dir		=0;//��������
	reg			r_pluse_zero=0;		//1-pluse freq=0Hz.	
	reg	[27:0]	r_state3_cnt=0;		//use for 2s count.
	reg			r_state2_zero=0;	//1-state2 to 0, r_state to idle.
	//gen clk for rom read.iaa
	reg [20:0]	r_clkdiv_cnt=0;
	reg			r_clkdiv	=0;
	//rom ctrl.
	reg			r_rom_ena	=0;
	reg[6:0]	r_rom_cnt	=7'b1111111;
	reg[6:0]	r_rom_addra	=7'b1111111;
	wire[25:0]	r_rom_data	;
	
	reg			r_pluse		=0;
	reg			r_set		=0;  //cch
	reg[25:0]	r_cnt		=0;   
	
	reg [27:0]	c_2s		=	200000000; //80000;��������ʱ��	//cch--5S��ȥ��ʱ��
	
	
	assign	o_dir	=	r_dir	;
	assign	o_pluse =	r_pluse	;
	assign	o_set =	r_set	;   //cch 自动记录参考点位置
	
//-----------״̬ת�Ƴ���--�������Ƿɴ�����4.3.1��-------------------------
	always @(posedge i_clk) begin
		case (r_state)
      		3'b000  : begin	//idle.
      		            if(i_key_a == 1'b1 && z_finished == 1'b1) begin	//when z_finished's rising_edge.
      		            	r_state	<=	3'b001;
      		            end
      		        	else	begin
      		        		r_state	<=	r_state;	
      		        	end
      		        	
      		        	r_pluse_zero	<=	1;
      		        	r_cnt_data		<=	4000;	
      		        	r_dir		    <=	1;
      		        	r_state3_cnt	<=	0;
						   //r_set  <=  0;  //cch
      		         end
      		3'b001  : begin	
      		         	if(i_key_b==1'b1) begin
      		         		r_state	<=	3'b010;
      		         	end
      		        	else if(i_key_c==1'b1) begin
      		        		r_state	<=	3'b100;
      		        	end
      		         	else	begin
      		         		r_state	<=	r_state;
      		         	end 
      		        	
      		        	r_pluse_zero	<=	0;
      		        	r_cnt_data		<=	4000;	
      		        	r_dir		    <=	1; 
      		        	r_state3_cnt	<=	0;     		         	  
      		         end
      		3'b010  : begin
      		            if(r_state2_zero==1'b1) begin
      		            	r_state	<=	3'b000;	//to idle.
      		            end
      		            else	begin
      		            	r_state	<=	r_state;
      		            end      		            
      		        	
      		        	r_pluse_zero	<=	0; 
      		        	r_cnt_data		<=	r_rom_data;	
      		        	r_dir		    <=	1;
      		        	r_state3_cnt	<=	0;     		            
      		         end
      		3'b011  : begin
      		         	if(r_state3_cnt<c_2s) begin
      		         		r_state3_cnt	<=	r_state3_cnt + 28'h1;
      		         	end
      		        	else	begin
      		        		r_state3_cnt	<=	r_state3_cnt;
      		        	end   
      		        	
      		        	if(r_state3_cnt==c_2s) begin
      		        		r_state	<=	3'b001;	//2s count rdy.
      		        	end
      		        	else	begin
      		        		r_state	<=	r_state;
      		        	end
      		        	
      		        	r_pluse_zero	<=	0;      		        	
      		        	r_cnt_data		<=	4000;	
      		        	r_dir		    <=	0;       		        	
      		         end
				3'b100  : begin
      		         	if(i_key_b==1'b1) begin	//when key_b's rising_edge.
      		            	r_state	<=	3'b011;
      		            end
      		        	else	begin
      		        		r_state	<=	r_state;	
      		        	end
								
      		        	r_pluse_zero	<=	0;      		        	
      		        	r_cnt_data		<=	4000;	
      		        	r_dir		   	<= 0;
							r_state3_cnt	<= 0;
      		         end			
							
							
      		default: begin
      		          	r_cnt_data		<=	4000;	   
								r_dir		      <=	1;        
								r_state3_cnt	<=	0;         
                        r_state			<=	0;
								r_pluse_zero   <= 1;
      		         end
   		endcase	    
	end 
	
	//4s/100=40ms.1600000
	reg [20:0] 	c_40ms	=	1600000;	//16000;	//
	reg	[20:0]	c_20ms	=	800000;	//8000;	//20ms��ROM��ȡһ������
//--------------20ms��ROM��ȡһ������--20ms�źŲ���------------
	always @(posedge i_clk)
	begin
		if(r_clkdiv_cnt < (c_40ms-1)) begin
			r_clkdiv_cnt	<=	r_clkdiv_cnt + 21'h1;
		end
		else	begin
			r_clkdiv_cnt	<=	0;
		end
		
		if(r_clkdiv_cnt	< c_20ms) begin
			r_clkdiv	<=	1;
		end
		else	begin
			r_clkdiv	<=	0;
		end
	end

//---------��ROMȡ��100�����ݼ���--�ı�״̬����Ӧ��״̬�ź�---------	
	always @(posedge r_clkdiv)
	begin
		if(r_state==3'b010) begin
			if(r_rom_cnt<100) begin
				r_rom_cnt	<=	r_rom_cnt + 7'h1;
			end
			else	begin
				r_rom_cnt	<=	r_rom_cnt;
			end
		end
		else	begin
			r_rom_cnt	<=	0;
		end
		
		if(r_rom_cnt < 100) begin
			r_rom_ena	<=	1;
		end
		else	begin
			r_rom_ena	<=	0;
		end
		
		r_rom_addra	<=	r_rom_cnt;
		
		if(r_rom_cnt==100) begin
			r_state2_zero	<=	1;
			r_set  <=  1;  //cch
		end
		else	begin
			r_state2_zero	<=	0;
			r_set  <=  0;  //cch
		end
	end
//----------S���ٶȼ�������Ƶ��ֵ�洢��ROM��------------------
	line_rom_ip 
		u_line_rom_ip (
  				.clock	(r_clkdiv	)	, 
  				.clken	(r_rom_ena	)	, 
  				.address(r_rom_addra)	, 
  				.q		(r_rom_data	) 		
				);	
//----------------����10KHZƵ��-------------------				
	always @(posedge i_clk) 
	begin
		if(r_cnt < r_cnt_data-1) begin
			r_cnt	<=	r_cnt + 26'h1;
		end
		else	begin
			r_cnt	<=	0;
		end
		
		if(r_pluse_zero	== 1) begin
			r_pluse	<=	0;
		end
		else	begin 
			if(r_cnt	< r_cnt_data/2) begin
				r_pluse	<=	1;
			end
			else	begin
				r_pluse	<=	0;
			end
		end
	end				
        
endmodule 