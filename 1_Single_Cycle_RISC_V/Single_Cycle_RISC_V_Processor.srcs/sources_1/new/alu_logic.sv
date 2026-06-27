`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/16/2026 02:26:59 PM
// Design Name: 
// Module Name: alu_logic
// Project Name: Complete Single-Cycle Processor
// Description: ALU updated to match Control Unit encodings
// 
//////////////////////////////////////////////////////////////////////////////////

module ALU(
    input      [31:0] in1, 
    input      [31:0] in2,
    input      [2:0]  alu_control,
    output reg [31:0] result,
    output reg        zero_flag
);
    always @(*) begin
        result = 32'b0;

        case(alu_control)
            3'b000: result = in1 + in2; 
            3'b001: result = in1 - in2; 
            3'b010: result = in1 & in2; 
            3'b011: result = in1 | in2; 
            3'b101: result = ($signed(in1) < $signed(in2)) ? 32'd1 : 32'd0; 
            default: result = 32'b0;    
        endcase

        zero_flag = (result == 32'b0) ? 1'b1 : 1'b0;
    end
endmodule