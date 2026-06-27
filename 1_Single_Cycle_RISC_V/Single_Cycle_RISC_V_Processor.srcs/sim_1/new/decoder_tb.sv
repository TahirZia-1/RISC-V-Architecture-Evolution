`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/16/2026 04:17:22 PM
// Design Name: 
// Module Name: decoder_tb
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



module decoder_tb;

reg [31:0] instruction;
wire [2:0] func3;
wire [6:0] func7;
wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] rd;
wire [11:0] imm;

decoder uut (.instruction(instruction), .func3(func3), .func7(func7), .rs1(rs1), .rs2(rs2), .rd(rd), .imm(imm));

initial begin

$monitor("Time=%0t | instr=%b | rs1=%b | rs2=%b | func7=%b | imm=%b", $time, instruction, rd, rs1, rs2, func3, func7, imm);


// add x1 x2 x3
instruction = 32'b0000000_00011_00010_000_00001_0110011; // R-type
#10;

// sw x3 8(x2)
instruction = 32'b0000000_00011_00010_010_01000_0100011; // S-type
#10;

// lw x1 16(x2)
instruction = 32'b000000000100_00010_010_00001_0000011; // I-type
#10;

// beq x1 x2 x12
instruction = 32'b0000000_00010_00001_000_00011_1100011; // B-type
#10;

$finish;
end
  
endmodule
