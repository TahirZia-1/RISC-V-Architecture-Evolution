`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/17/2026 03:17:40 PM
// Design Name: 
// Module Name: adder_32_tb
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


module tb_adder_32;

reg  [31:0] a;
reg  [31:0] b;
wire [31:0] sum;

adder_32 uut (.a(a), .b(b), .sum(sum));

initial begin
    a = 32'd0; 
    b = 32'd0; 
    #10;

    a = 32'd15; 
    b = 32'd25; 
    #10;

    a = 32'd1500; 
    b = 32'd3500; 
    #10;

    a = 32'hFFFFFFFF; 
    b = 32'd1; 
    #10;

    $finish;
end

endmodule
