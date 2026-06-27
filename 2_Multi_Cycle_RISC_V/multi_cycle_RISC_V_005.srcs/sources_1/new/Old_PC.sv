`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/19/2026 10:35:36 AM
// Design Name: 
// Module Name: Old_PC
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Combined Enabled Register for OldPC and Instruction
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module Old_PC(
input clk, rst, IRWrite,
input [31:0] pc_in, inst_mem_in,
output reg [31:0] old_pc_out, inst_mem_out);

always @(posedge clk) begin
    if (rst) begin
        old_pc_out <= 32'b0;
        inst_mem_out <= 32'b0;
    end
    else if (IRWrite) begin
        old_pc_out <= pc_in;
        inst_mem_out <= inst_mem_in;
    end
    end

endmodule

module PC_32bit(
    input clk, rst, PCWrite, 
    input [31:0] pc_in,  
    output reg [31:0] pc_out);

always @(posedge clk) begin

if (rst) begin
    pc_out <= 32'b0;
end
else if (PCWrite) begin
    pc_out <= pc_in;
end
end

endmodule