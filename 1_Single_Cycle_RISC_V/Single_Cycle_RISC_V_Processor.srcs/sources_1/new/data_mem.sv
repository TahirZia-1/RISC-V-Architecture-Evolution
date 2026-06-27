`timescale 1ns/1ps

module data_mem (
    input             CLK,     
    input             WE,      
    input      [31:0] A,       
    input      [31:0] WD,      
    output reg [31:0] RD       
);
    reg [7:0] memory [1023:0];

    always @(posedge CLK) begin
        if (WE) begin
            memory[A]     <= WD[7:0];
            memory[A + 1] <= WD[15:8];
            memory[A + 2] <= WD[23:16];
            memory[A + 3] <= WD[31:24];
        end
    end

    always @(*) begin
        RD[7:0]   = memory[A];
        RD[15:8]  = memory[A + 1];
        RD[23:16] = memory[A + 2];
        RD[31:24] = memory[A + 3];
    end
endmodule