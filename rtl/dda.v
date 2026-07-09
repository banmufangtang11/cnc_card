//dda�岹ģ��
module	dda(clk,data,valid,dir_x,dir_y,puls_x,puls_y,dir_z,puls_z,dir_a,puls_a);
input	clk,valid;
input	[31:0]data;
output	dir_x,dir_y,puls_x,puls_y,dir_z,puls_z,dir_a,puls_a;
wire	puls_x,puls_y,puls_z,puls_a;
reg		dir_x,dir_y,dir_z,dir_a;
reg		[16:0]data_x,data_y,data_z,data_a;

//reg     [31:0]data_free;

//----------��ȡ��x,y,z,a��������Ӧ����--------------------------------------------------
always @(posedge clk)
  begin
	if(!valid)
		begin 
			data_x <= 17'h0; data_y <= 17'h0; data_z <= 17'h0; data_a <= 17'h0;
			dir_x <= 1'b0; dir_y <= 1'b0; dir_z <= 1'b0; dir_a <= 1'b0;
		end
	else 
		begin 
//			data_x[16:0] <= {10'h0,data[6:0]} +  {10'h0,data[6:0]};
//			data_y[16:0] <= {10'h0,data[13:7]} +  {10'h0,data[13:7]};
//			data_z[16:0] <= {10'h0,data[20:14]} +  {10'h0,data[20:14]};
//			data_a[16:0] <= {10'h0,data[27:21]} +  {10'h0,data[27:21]};
			data_x[16:0] <= {10'h0,data[6:0]}; 
			data_y[16:0] <= {10'h0,data[13:7]}; 
         data_z[16:0] <= {10'h0,data[20:14]};
			data_a[16:0] <= {10'h0,data[27:21]};
			dir_x <= data[28:28]; dir_y <= data[29:29]; dir_z <= data[30:30]; dir_a <= data[31:31];
		end
  end
//-------------------------------------------------------------------------------------
interpolation	dda_x(
						.clk(clk),
						.valid(valid),
						.data(data_x),
						.q(puls_x)
					  );
					
interpolation	dda_y(
						.clk(clk),
						.valid(valid),
						.data(data_y),
						.q(puls_y)
					  );
					
interpolation	dda_z(
						.clk(clk),
						.valid(valid),
						.data(data_z),
						.q(puls_z)
					  );
interpolation	dda_a(
						.clk(clk),
						.valid(valid),
						.data(data_a),
						.q(puls_a)
					  );
endmodule 	
