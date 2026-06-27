`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/19/2026 10:58:04 AM
// Design Name: 
// Module Name: buff_reg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module buff_reg(
input clk, rst,
input [31:0] data_in,
output reg [31:0] data_out);

always@(posedge clk or posedge rst) begin
if (rst) data_out <= 32'b0;
else data_out <= data_in;
end

endmodule

module buff_reg_file(
input clk, rst,
input [31:0] RD1, RD2,
output reg [31:0] data_out_1, data_out_2);

always@(posedge clk or posedge rst) begin
if(rst) begin 
data_out_1 <= 32'b0; 
data_out_2 <= 32'b0; end
else begin 
data_out_1 <= RD1; 
data_out_2 <= RD2;
end
end

endmodule