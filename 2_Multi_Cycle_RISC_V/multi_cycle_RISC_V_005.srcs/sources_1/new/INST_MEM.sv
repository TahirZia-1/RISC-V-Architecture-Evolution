//`timescale 1ns/1ps

//module INST_MEM(
//input clk, MemWrite,
//input [31:0] Adr, WD,
//output reg [31:0] RD
//);

//// Byte-addressable memory: 1024 bytes (1 KB)
//// 8 bits wide, 1024 slots deep
//reg [7:0] Memory [1023:0];

//initial begin
    

    
//    // Instruction 0: J-Type (jal x3, 12)
//    // Machine Code: 00_C0_01_EF
//    Memory[0] = 8'hEF;
//    Memory[1] = 8'h01;
//    Memory[2] = 8'hC0;
//    Memory[3] = 8'h00;

//    // Instruction 1: R-Type (add x2, x1, x1)
//    // Machine Code: 00_10_81_33
//    Memory[4] = 8'h33;
//    Memory[5] = 8'h81;
//    Memory[6] = 8'h10;
//    Memory[7] = 8'h00;

//    // Instruction 2: S-Type (sw x2, 4(x0))
//    // Machine Code: 00_20_22_23
//    Memory[8]  = 8'h23;
//    Memory[9]  = 8'h22;
//    Memory[10] = 8'h20;
//    Memory[11] = 8'h00;

//    // Instruction 3: I-Type (lw x1, 100(x0)) 06402083
//    // Machine Code: 00_00_20_83
//    Memory[12] = 8'h83;
//    Memory[13] = 8'h20;
//    Memory[14] = 8'h40;
//    Memory[15] = 8'h06;

//    // Instruction 4: B-Type (beq x0, x0, -12)
//    // Machine Code: FE_00_0A_E3
//    Memory[16] = 8'hE3;
//    Memory[17] = 8'h0A;
//    Memory[18] = 8'h00;
//    Memory[19] = 8'hFE;


//    // We will place '42' (Hex 2A) at address 100 just as an example.
//    Memory[100] = 8'h2A;
//    Memory[101] = 8'h00;
//    Memory[102] = 8'h00;
//    Memory[103] = 8'h00;
//end


//always @(posedge clk) begin
//    if (MemWrite) begin
//        Memory[Adr]     <= WD[7:0];   // LSB
//        Memory[Adr+1]   <= WD[15:8];
//        Memory[Adr+2]   <= WD[23:16];
//        Memory[Adr+3]   <= WD[31:24]; // MSB
//    end
//end
    

//always @(*) begin
//    RD = {Memory[Adr+3], Memory[Adr+2], Memory[Adr+1], Memory[Adr]};
//end

//endmodule

`timescale 1ns/1ps

module INST_MEM(
    input clk, MemWrite,
    input [31:0] Adr, WD,
    output reg [31:0] RD
);

// Byte-addressable memory: 1024 bytes (1 KB)
reg [7:0] Memory [1023:0];

initial begin

    // Address 0: srli x24, x14, 10 (00_A7_5C_13)
    Memory[0] = 8'h13;
    Memory[1] = 8'h5c;
    Memory[2] = 8'ha7;
    Memory[3] = 8'h00;

//initial begin
//    Memory[100] = 8'h00;  // will be overwritten by sw

//    // Address 0: addi x1, x0, 10  Machine Code: (0x00_A0_00_93)
//    Memory[0] = 8'h93;
//    Memory[1] = 8'h00;
//    Memory[2] = 8'hA0;
//    Memory[3] = 8'h00;

//    // Address 4: add x2, x1, x1  Machine Code: (0x00_10_81_33)
//    Memory[4] = 8'h33;
//    Memory[5] = 8'h81;
//    Memory[6] = 8'h10;
//    Memory[7] = 8'h00;

//    // Address 8: sw x2, 100(x0) Machine Code:  (0x06_20_22_23) 
//    Memory[8]  = 8'h23;
//    Memory[9]  = 8'h22;
//    Memory[10] = 8'h20;
//    Memory[11] = 8'h06;

//    // Address 12: lw x3, 100(x0) Machine Code: (0x06_40_21_83) 
//    Memory[12] = 8'h83;
//    Memory[13] = 8'h21;
//    Memory[14] = 8'h40;
//    Memory[15] = 8'h06;

//    // Address 16: beq x1, x0, 8 Machine Code:  (0x00_00_84_63) – NOT taken 
//    Memory[16] = 8'h63;
//    Memory[17] = 8'h84;
//    Memory[18] = 8'h00;
//    Memory[19] = 8'h00;

//    // Address 20: beq x3, x2, 8  Machine Code: (0x00_21_84_63) – TAKEN
//    Memory[20] = 8'h63;
//    Memory[21] = 8'h84;
//    Memory[22] = 8'h21;
//    Memory[23] = 8'h00;

//    // Address 24: NOP (unused, but keep zero)
//    Memory[24] = 8'h00;
//    Memory[25] = 8'h00;
//    Memory[26] = 8'h00;
//    Memory[27] = 8'h00;

//    // Address 28: jal x4, -8   Machine Code:    (0xFF_9F_F2_6F) 0xFF9FF26F
//    Memory[28] = 8'h6F;
//    Memory[29] = 8'hF2;
//    Memory[30] = 8'h9F;
//    Memory[31] = 8'hFF;
//end

always @(posedge clk) begin
    if (MemWrite) begin
        Memory[Adr]     <= WD[7:0];
        Memory[Adr+1]   <= WD[15:8];
        Memory[Adr+2]   <= WD[23:16];
        Memory[Adr+3]   <= WD[31:24];
    end
end

always @(*) begin
    RD = {Memory[Adr+3], Memory[Adr+2], Memory[Adr+1], Memory[Adr]};
end

endmodule