`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/16/2026 02:32:48 PM
// Design Name: 
// Module Name: program_counter_tb
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


module PC_32bit_tb();

reg clk,rst;
wire [31:0] count;

PC_32bit uut (.clk(clk), .rst(rst), .count(count));

always #5 clk = ~clk;

initial begin

$monitor("Time = %0t | clk = %b | rst = %b | count = %b", $time, clk, rst, count);

clk = 0;
rst = 1;
#10;

rst = 0;
#200;

$finish;
end

endmodule
