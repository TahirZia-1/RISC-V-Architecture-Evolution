`timescale 1ns/1ps

module INST_MEM(
    input  [31:0] PC,
    output [31:0] Instruction_Code
);
    reg [7:0] Memory [31:0];

    initial begin
        
        // Instruction 0: J-Type (jal x3, 12)
        // Machine Code: 00_C0_01_EF
        
        Memory[0] = 8'hEF;
        Memory[1] = 8'h01;
        Memory[2] = 8'hC0;
        Memory[3] = 8'h00;

        // Instruction 1: R-Type (add x2, x1, x1)
        // Machine Code: 00_10_81_33

        Memory[4] = 8'h33;
        Memory[5] = 8'h81;
        Memory[6] = 8'h10;
        Memory[7] = 8'h00;

        // Instruction 2: S-Type (sw x2, 4(x0))
        // Machine Code: 00_20_22_23

        Memory[8]  = 8'h23;
        Memory[9]  = 8'h22;
        Memory[10] = 8'h20;
        Memory[11] = 8'h00;

        // Instruction 3: I-Type (lw x1, 0(x0))
        // Machine Code: 00_00_20_83
      
        Memory[12] = 8'h83;
        Memory[13] = 8'h20;
        Memory[14] = 8'h00;
        Memory[15] = 8'h00;

        // Instruction 4: B-Type (beq x0, x0, -12)
        // Machine Code: FE_00_0A_E3
      
        Memory[16] = 8'hE3;
        Memory[17] = 8'h0A;
        Memory[18] = 8'h00;
        Memory[19] = 8'hFE;

    end

    assign Instruction_Code = {Memory[PC+3], Memory[PC+2], Memory[PC+1], Memory[PC]};
endmodule