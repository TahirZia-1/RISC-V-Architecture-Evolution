`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/16/2026 02:47:25 PM
// Design Name: 
// Module Name: alu_logic_tb
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


`timescale 1ns / 1ps

module tb_ALU();

reg [31:0] in1;
reg [31:0] in2;
reg [2:0] alu_control;

wire [31:0] result;
wire zero_flag;

ALU uut (
    .in1(in1), 
    .in2(in2), 
    .alu_control(alu_control), 
    .result(result), 
    .zero_flag(zero_flag)
);

initial begin
    in1 = 32'b0;
    in2 = 32'b0;
    alu_control = 3'b0;

    #100;
    
    // Test Case 1: AND Operation (3'b000)
    in1 = 32'hAAAA_FFFF;
    in2 = 32'h5555_FFFF;
    alu_control = 3'b000;
    #10; // Expected result = 32'h0000_FFFF
    
    // Test Case 2: OR Operation (3'b001)
    in1 = 32'h0000_FFFF;
    in2 = 32'hFFFF_0000;
    alu_control = 3'b001;
    #10; // Expected result = 32'hFFFF_FFFF

    // Test Case 3: ADD Operation (3'b010)
    in1 = 32'd50;
    in2 = 32'd25;
    alu_control = 3'b010;
    #10; // Expected result = 32'd75

    // --- Test Case 4: SUB Operation (3'b110) ---
    in1 = 32'd50;
    in2 = 32'd25;
    alu_control = 3'b110;
    #10; // Expected result = 32'd25

    // --- Test Case 5: Equality Check Check (3'b011) - Equal ---
    in1 = 32'd100;
    in2 = 32'd100;
    alu_control = 3'b011;
    #10; // Expected result = 32'b0

    // --- Test Case 6: Equality Check Check (3'b011) - Not Equal ---
    in1 = 32'd100;
    in2 = 32'd200;
    alu_control = 3'b011;
    #10; // Expected result = 32'b1
    
    // --- Test Case 7: Default Case (3'b100) ---
    alu_control = 3'b100;
    #10; // Expected result = 32'b0

// Stop the simulation
$stop;
end
      
// Optional: Monitor changes in the console
initial begin
    $monitor("Time=%0t | Control=%b | In1=%h | In2=%h | Result=%h | Zero=%b", 
             $time, alu_control, in1, in2, result, zero_flag);
end

endmodule




