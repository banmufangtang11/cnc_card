`timescale 1ns / 1ps

// DDA插补模块
// 将32位指令数据分解为4轴(X/Y/Z/A)的插补参数，分别驱动4个interpolation模块生成脉冲

module dda(
    input         clk,       // 时钟信号
    input         valid,     // 数据有效信号
    input  [31:0] data,      // 32位指令数据：[31:28]方向，[27:21]A轴，[20:14]Z轴，[13:7]Y轴，[6:0]X轴
    output        dir_x,     // X轴方向
    output        dir_y,     // Y轴方向
    output        puls_x,    // X轴脉冲
    output        puls_y,    // Y轴脉冲
    output        dir_z,     // Z轴方向
    output        puls_z,    // Z轴脉冲
    output        dir_a,     // A轴方向
    output        puls_a     // A轴脉冲
);

reg        dir_x_reg, dir_y_reg, dir_z_reg, dir_a_reg;
reg [16:0] data_x, data_y, data_z, data_a;

always @(posedge clk) begin
    if (!valid) begin
        data_x <= 17'h0;
        data_y <= 17'h0;
        data_z <= 17'h0;
        data_a <= 17'h0;
        dir_x_reg <= 1'b0;
        dir_y_reg <= 1'b0;
        dir_z_reg <= 1'b0;
        dir_a_reg <= 1'b0;
    end else begin
        data_x <= {10'h0, data[6:0]};
        data_y <= {10'h0, data[13:7]};
        data_z <= {10'h0, data[20:14]};
        data_a <= {10'h0, data[27:21]};
        dir_x_reg <= data[28];
        dir_y_reg <= data[29];
        dir_z_reg <= data[30];
        dir_a_reg <= data[31];
    end
end

interpolation dda_x(
    .clk(clk),
    .valid(valid),
    .data(data_x),
    .q(puls_x)
);

interpolation dda_y(
    .clk(clk),
    .valid(valid),
    .data(data_y),
    .q(puls_y)
);

interpolation dda_z(
    .clk(clk),
    .valid(valid),
    .data(data_z),
    .q(puls_z)
);

interpolation dda_a(
    .clk(clk),
    .valid(valid),
    .data(data_a),
    .q(puls_a)
);

assign dir_x = dir_x_reg;
assign dir_y = dir_y_reg;
assign dir_z = dir_z_reg;
assign dir_a = dir_a_reg;

endmodule