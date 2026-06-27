`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/17/2026 03:25:20 PM
// Design Name: 
// Module Name: mux_2x1_tb
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


module tb_mux_2x1;

logic s;
logic [31:0] x;
logic [31:0] y;
logic [31:0] out;

mux_2x1 uut (.out(out), .s(s), .x(x), .y(y));

initial begin
    x = 32'hAAAAAAAA;
    y = 32'h55555555;
    
    s = 1'b0;
    #10;
    
    s = 1'b1;
    #10;
    
    x = 32'h12345678;
    y = 32'h87654321;
    
    s = 1'b0;
    #10;
    
    s = 1'b1;
    #10;
    
    $finish;
end

endmodule
