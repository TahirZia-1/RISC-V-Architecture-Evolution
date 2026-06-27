`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/17/2026 03:21:28 PM
// Design Name: 
// Module Name: mux_2x1
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


module mux_2x1 (
    output logic [31:0] out,
    input  logic        s,
    input  logic [31:0] x,y
);
    assign out = s ? y : x;
endmodule

module mux_3x1 (
    output logic [31:0] out,
    input  logic [1:0]  s,
    input  logic [31:0] d0, d1, d2
);
    assign out = (s == 2'b00) ? d0 : 
                 (s == 2'b01) ? d1 : 
                                d2;
endmodule
