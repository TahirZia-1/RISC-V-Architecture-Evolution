`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/22/2026 01:14:18 AM
// Design Name: 
// Module Name: design
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


// Code your design here
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

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/19/2026 10:58:04 AM
// Design Name: 
// Module Name: buff_reg
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


module buff_reg(
input clk, rst,
input [31:0] data_in,
output reg [31:0] data_out);

always@(posedge clk or posedge rst) begin
if (rst) data_out <= 32'b0;
else data_out <= data_in;
end

endmodule

module buff_reg_file(
input clk, rst,
input [31:0] RD1, RD2,
output reg [31:0] data_out_1, data_out_2);

always@(posedge clk or posedge rst) begin
if(rst) begin 
data_out_1 <= 32'b0; 
data_out_2 <= 32'b0; end
else begin 
data_out_1 <= RD1; 
data_out_2 <= RD2;
end
end

endmodule

`timescale 1ns/1ps

// ==========================================
// 1. TOP LEVEL CONTROL UNIT
// ==========================================
module control_unit(
    input        clk, rst,      
    input  [6:0] op,
    input  [2:0] funct3,
    input        funct7_5,
    input        Zero,
    
    output       PCWrite,
    output       AdrSrc,
    output       MemWrite,
    output       IRWrite,
    output [1:0] ResultSrc,
    output [1:0] ALUSrcA,
    output [1:0] ALUSrcB,
    output [1:0] ImmSrc,
    output       RegWrite,
    output [2:0] ALUControl
);

    wire       PCUpdate;
    wire       Branch;
    wire [1:0] ALUOp;

    // PCWrite Logic: Update if the FSM forces it (PCUpdate) OR if it's a successful Branch
    assign PCWrite = PCUpdate | (Branch & Zero);

    // Instantiate the Finite State Machine
    main_fsm fsm_inst (
        .clk(clk),
        .rst(rst),
        .op(op),
        .PCUpdate(PCUpdate),
        .Branch(Branch),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .IRWrite(IRWrite),
        .ResultSrc(ResultSrc),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ALUOp(ALUOp),
        .AdrSrc(AdrSrc)
    );

    // Instantiate the ALU Decoder
    alu_decoder ad_inst (
        .ALUOp(ALUOp),
        .funct3(funct3),
        .op_5(op[5]),
        .funct7_5(funct7_5),
        .ALUControl(ALUControl)
    );

    // Instantiate the Immediate Decoder
    instr_decoder id_inst (
        .op(op),
        .ImmSrc(ImmSrc)
    );

endmodule


// ==========================================
// 2. THE FINITE STATE MACHINE (Main Decoder)
// ==========================================
module main_fsm(
    input            clk, rst,
    input      [6:0] op,
    
    output reg       PCUpdate, Branch,
    output reg       RegWrite, MemWrite, IRWrite,
    output reg [1:0] ResultSrc, ALUSrcA, ALUSrcB, ALUOp,
    output reg       AdrSrc
);

    // State Encoding
    parameter FETCH    = 4'd0;
    parameter DECODE   = 4'd1;
    parameter MEMADR   = 4'd2;
    parameter MEMREAD  = 4'd3;
    parameter MEMWB    = 4'd4;
    parameter MEMWRITE = 4'd5;
    parameter EXECUTER = 4'd6;
    parameter ALUWB    = 4'd7;
    parameter EXECUTEI = 4'd8;
    parameter JAL      = 4'd9;
    parameter BEQ      = 4'd10;

    reg [3:0] state, next_state;

    // State Register (Synchronous)
    always @(posedge clk) begin
        if (rst) state <= FETCH;
        else     state <= next_state;
    end

    // Next State Logic (Combinational)
    always @(*) begin
        case(state)
            FETCH:  next_state = DECODE;
            DECODE: begin
                case(op)
                    7'b0000011: next_state = MEMADR;   // lw
                    7'b0100011: next_state = MEMADR;   // sw
                    7'b0110011: next_state = EXECUTER; // R-type
                    7'b0010011: next_state = EXECUTEI; // I-type ALU
                    7'b1101111: next_state = JAL;      // jal
                    7'b1100011: next_state = BEQ;      // beq
                    default:    next_state = FETCH;
                endcase
            end
            MEMADR: begin
                if (op == 7'b0000011) next_state = MEMREAD; // lw
                else                  next_state = MEMWRITE; // sw
            end
            MEMREAD:  next_state = MEMWB;
            MEMWB:    next_state = FETCH;
            MEMWRITE: next_state = FETCH;
            EXECUTER: next_state = ALUWB;
            EXECUTEI: next_state = ALUWB;
            ALUWB:    next_state = FETCH;
            JAL:      next_state = ALUWB;
            BEQ:      next_state = FETCH;
            default:  next_state = FETCH;
        endcase
    end

    // Output Logic (Combinational)
    always @(*) begin
        // Default all signals to 0 to prevent latches
        PCUpdate=0; Branch=0; RegWrite=0; MemWrite=0; IRWrite=0; AdrSrc=0;
        ResultSrc=2'b00; ALUSrcA=2'b00; ALUSrcB=2'b00; ALUOp=2'b00;

        case(state)
            FETCH: begin
                AdrSrc    = 1'b0;
                IRWrite   = 1'b1;
                ALUSrcA   = 2'b00; // PC
                ALUSrcB   = 2'b10; // [FIXED] 10 maps to 4
                ALUOp     = 2'b00; // Add
                ResultSrc = 2'b10; // ALUResult
                PCUpdate  = 1'b1;
            end
            DECODE: begin
                ALUSrcA   = 2'b01; // OldPC
                ALUSrcB   = 2'b01; // [FIXED] 01 maps to ImmExt
                ALUOp     = 2'b00; // Add (Calculates Branch Target)
            end
            MEMADR: begin
                ALUSrcA   = 2'b10; // A (rs1)
                ALUSrcB   = 2'b01; // [FIXED] 01 maps to ImmExt
                ALUOp     = 2'b00; // Add
            end
            MEMREAD: begin
                ResultSrc = 2'b00; // ALUOut
                AdrSrc    = 1'b1;  // Result wire
            end
            MEMWB: begin
                ResultSrc = 2'b01; // Data from Memory
                RegWrite  = 1'b1;
            end
            MEMWRITE: begin
                ResultSrc = 2'b00; // ALUOut
                AdrSrc    = 1'b1;  // Result wire
                MemWrite  = 1'b1;
            end
            EXECUTER: begin
                ALUSrcA   = 2'b10; // A (rs1)
                ALUSrcB   = 2'b00; // B (rs2)
                ALUOp     = 2'b10; // Use funct3/7
            end
            EXECUTEI: begin
                ALUSrcA   = 2'b10; // A (rs1)
                ALUSrcB   = 2'b01; // [FIXED] 01 maps to ImmExt
                ALUOp     = 2'b10; // Use funct3/7
            end
            ALUWB: begin
                ResultSrc = 2'b00; // ALUOut
                RegWrite  = 1'b1;
            end
            JAL: begin
                ALUSrcA   = 2'b01; // OldPC
                ALUSrcB   = 2'b10; // [FIXED] 10 maps to 4
                ALUOp     = 2'b00; // Add (Calculates OldPC + 4 to save to Reg)
                ResultSrc = 2'b00; // ALUOut (Routes branch target to PC)
                PCUpdate  = 1'b1;
            end
            BEQ: begin
                ALUSrcA   = 2'b10; // A (rs1)
                ALUSrcB   = 2'b00; // B (rs2)
                ALUOp     = 2'b01; // Sub (For comparison)
                ResultSrc = 2'b00; // ALUOut (Routes branch target to PC if Zero=1)
                Branch    = 1'b1;
            end
        endcase
    end
endmodule


// ==========================================
// 3. IMMEDIATE DECODER
// ==========================================
module instr_decoder(
    input  [6:0] op,
    output reg [1:0] ImmSrc
);
    always @(*) begin
        case(op)
            7'b0100011: ImmSrc = 2'b01; // sw
            7'b1100011: ImmSrc = 2'b10; // beq
            7'b1101111: ImmSrc = 2'b11; // jal
            default:    ImmSrc = 2'b00; // lw, R-type, I-type
        endcase
    end
endmodule


// ==========================================
// 4. ALU DECODER
// ==========================================
module alu_decoder(
    input      [1:0] ALUOp,
    input      [2:0] funct3,
    input            op_5,
    input            funct7_5,
    output reg [2:0] ALUControl
);
    always @(*) begin
        case (ALUOp)
            2'b00: ALUControl = 3'b000; 
            2'b01: ALUControl = 3'b001; 
            2'b10: begin 
                case (funct3)
                    3'b000: begin
                        if (op_5 & funct7_5) 
                            ALUControl = 3'b001; 
                        else                 
                            ALUControl = 3'b000; 
                    end
                    3'b010: ALUControl = 3'b101; 
                    3'b110: ALUControl = 3'b011; 
                    3'b111: ALUControl = 3'b010; 
                    default: ALUControl = 3'b000; 
                endcase
            end
            default: ALUControl = 3'b000;
        endcase
    end
endmodule

//`timescale 1ns/1ps

//// Extender Block
//module imm_Gen(
//    input      [31:0] instruction,
//    input      [1:0]  ImmSrc,           
//    output reg [31:0] immediate_output
//);
//    wire [11:0] load_im;
//    wire [11:0] store_im;
//    wire [12:0] branch_im;
//    wire [20:0] jump_im;

//    assign load_im   = instruction[31:20];
//    assign store_im  = {instruction[31:25], instruction[11:7]};
//    assign branch_im = {instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    
//    assign jump_im   = {instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

//    always @(*) begin
//        case(ImmSrc)
//            2'b00: immediate_output = {{20{load_im[11]}}, load_im};
//            2'b01: immediate_output = {{20{store_im[11]}}, store_im};
//            2'b10: immediate_output = {{19{branch_im[12]}}, branch_im};
//            2'b11: immediate_output = {{11{jump_im[20]}}, jump_im};
//            default: immediate_output = 32'b0;
//        endcase
//    end
//endmodule

module imm_Gen (
    input  [31:0] instruction,
    input  [1:0]  ImmSrc,
    output reg [31:0] immediate_output
);
    always @(*) begin
        case(ImmSrc)
            2'b00: // I-Type (lw, addi)
                immediate_output = {{20{instruction[31]}}, instruction[31:20]};
            
            2'b01: // S-Type (sw)
                immediate_output = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            
            2'b10: // B-Type (beq)
                immediate_output = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            
            2'b11: // [NEW] J-Type (jal)
                immediate_output = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            
            default: 
                immediate_output = 32'b0;
        endcase
    end
endmodule

`timescale 1ns/1ps

module INST_MEM(
input clk, MemWrite,
input [31:0] Adr, WD,
output reg [31:0] RD
);

// Byte-addressable memory: 1024 bytes (1 KB)
// 8 bits wide, 1024 slots deep
reg [7:0] Memory [1023:0];

initial begin
    
    // ----------------------------------------------------
    // INSTRUCTION MEMORY SEGMENT (Starts at Address 0)
    // ----------------------------------------------------
    
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

    // ----------------------------------------------------
    // DATA MEMORY SEGMENT (Can be placed further down)
    // ----------------------------------------------------
    // Pre-loading the data we need for the 'lw' instruction.
    // We will place '42' (Hex 2A) at address 100 just as an example.
    Memory[100] = 8'h2A;
    Memory[101] = 8'h00;
    Memory[102] = 8'h00;
    Memory[103] = 8'h00;
end

// ==========================================
// WRITE LOGIC (Synchronous)
// ==========================================
// Executes only on the clock edge when MemWrite is high
always @(posedge clk) begin
    if (MemWrite) begin
        // Slice the 32-bit Write Data (WD) into four 8-bit chunks
        Memory[Adr]     <= WD[7:0];   // LSB
        Memory[Adr+1]   <= WD[15:8];
        Memory[Adr+2]   <= WD[23:16];
        Memory[Adr+3]   <= WD[31:24]; // MSB
    end
end
    
// ==========================================
// READ LOGIC (Asynchronous / Combinational)
// ==========================================
// Instantly outputs the 32-bit word at the current Address
always @(*) begin
    RD = {Memory[Adr+3], Memory[Adr+2], Memory[Adr+1], Memory[Adr]};
end

endmodule

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


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/19/2026 10:35:36 AM
// Design Name: 
// Module Name: Old_PC
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Combined Enabled Register for OldPC and Instruction
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module Old_PC(
input clk, rst, IRWrite,
input [31:0] pc_in, inst_mem_in,
output reg [31:0] old_pc_out, inst_mem_out);

always @(posedge clk) begin
    if (rst) begin
        old_pc_out <= 32'b0;
        inst_mem_out <= 32'b0;
    end
    else if (IRWrite) begin
        old_pc_out <= pc_in;
        inst_mem_out <= inst_mem_in;
    end
    end

endmodule

module PC_32bit(
    input clk, rst, PCWrite, 
    input [31:0] pc_in,  
    output reg [31:0] pc_out);

always @(posedge clk) begin

if (rst) begin
    pc_out <= 32'b0;
end
else if (PCWrite) begin
    pc_out <= pc_in;
end
end

endmodule

`timescale 1ns/1ps

module REG_FILE (
    input      [4:0]  read_reg_num1, read_reg_num2, write_reg,
    input      [31:0] write_data,
    output     [31:0] read_data1, read_data2,
    input             regwrite, clock, reset
);
    reg [31:0] reg_memory [31:0]; // 32 bit 32 registers 
    integer i;

    always@(posedge clock or posedge reset) begin
        if (reset) begin 
            for (i = 0; i < 32; i = i + 1) begin
                reg_memory[i] <= 32'b0; 
            end
        end
        else if (regwrite && (write_reg != 0)) begin // target is x0 (write_reg != 0) 
            reg_memory[write_reg] <= write_data;
        end
    end

    assign read_data1 = reg_memory[read_reg_num1];
    assign read_data2 = reg_memory[read_reg_num2];
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/16/2026 02:32:17 PM
// Design Name: 
// Module Name: top
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

module top (
    input clk, rst,
    output wire [31:0] pc,    
    output wire [31:0] insn, 
// [NEW] Memory Interface Outputs for debugging
    output wire [31:0] mem_adr,  // Address going into memory
    output wire [31:0] mem_wd,   // Data being written to memory
    output wire        mem_we,   // Memory Write Enable flag
    output wire [31:0] mem_rd    // Data coming out of memory
);

    wire [31:0] mux_1_to_inst_mem;
    wire [31:0] pc_out;
    wire [31:0] extend_out;
    wire [31:0] inst_mem_out;
    wire [31:0] read_data_1_wire;
    wire [31:0] read_data_2_wire;
    wire [31:0] ALU_result_wire;

    wire [4:0]  inst_mem_to_reg_file_1;
    wire [4:0]  inst_mem_to_reg_file_2;
    wire [4:0]  inst_mem_to_reg_file_3;
    
    // new wires added to existing single-cycle:
    
    wire [31:0] read_data_out;
    wire [31:0] old_pc_out;
    wire [31:0] reg_buff_data_out_1;
    wire [31:0] reg_buff_data_out_2;
    wire [31:0] mux_2_to_ALU;
    wire [31:0] mux_3_to_ALU;
    wire [31:0] buff_1_to_mux4;
    wire [31:0] buff_2_to_mux4;
    wire [31:0] mux_4_out;
    
    // control wires
    // wire [6:0]  Op;
    wire AdrSrc;
    wire PCWrite;
    wire MemWrite;
    wire IRWrite;
    wire Regwrite;
    wire [1:0] ImmSrc;
    wire [1:0] ALUSrcA;
    wire [1:0] ALUSrcB;
    wire [2:0] ALUControl;
    wire zero_out;
    wire [1:0] ResultSrc;
    

    // Instantiations
    mux_2x1 mux_1 (.out(mux_1_to_inst_mem), 
                   .x(pc_out), 
                   .y(mux_4_out), 
                   .s(AdrSrc)); 

    PC_32bit pc_1 (.clk(clk), 
                   .rst(rst), 
                   .PCWrite(PCWrite),  
                   .pc_in(mux_4_out), 
                   .pc_out(pc_out));
                   
    INST_MEM inst (.clk(clk), 
                   .MemWrite(MemWrite),
                   .Adr(mux_1_to_inst_mem), 
                   .WD(reg_buff_data_out_2),  
                   .RD(read_data_out)); 
                   
    Old_PC pcold (.clk(clk), .rst(rst),
                  .IRWrite(IRWrite),
                  .pc_in(pc_out),
                  .inst_mem_in(read_data_out),
                  .old_pc_out(old_pc_out),
                  .inst_mem_out(inst_mem_out));
                  
    assign inst_mem_to_reg_file_1 = inst_mem_out[19:15];
    assign inst_mem_to_reg_file_2 = inst_mem_out[24:20];
    assign inst_mem_to_reg_file_3 = inst_mem_out[11:7];
                  
    REG_FILE reg_f (.clock(clk), .reset(rst),
                    .read_reg_num1(inst_mem_to_reg_file_1), 
                    .read_reg_num2(inst_mem_to_reg_file_2), 
                    .write_reg(inst_mem_to_reg_file_3), 
                    .write_data(mux_4_out), 
                    .read_data1(read_data_1_wire), 
                    .read_data2(read_data_2_wire), 
                    .regwrite(Regwrite));
                
    buff_reg_file reg_ff (.clk(clk), .rst(rst),
                   .RD1(read_data_1_wire),
                   .RD2(read_data_2_wire),
                   .data_out_1(reg_buff_data_out_1),
                   .data_out_2(reg_buff_data_out_2));
                                    
    mux_3x1 mux_2 (
            .out(mux_2_to_ALU),
            .d0(pc_out),             
            .d1(old_pc_out),
            .d2(reg_buff_data_out_1),            
            .s(ALUSrcA)); // from control unit
                  
    imm_Gen imm (.instruction(inst_mem_out), 
                 .immediate_output(extend_out), 
                 .ImmSrc(ImmSrc)); // ImmSrc [1:0]      
                 
    mux_3x1 mux_3 (
            .out(mux_3_to_ALU), 
            .d0(read_data_2_wire),             
            .d1(extend_out),
            .d2(32'd4),            
            .s(ALUSrcB)); // from control unit  
            
    ALU alu (.in1(mux_2_to_ALU), 
             .in2(mux_3_to_ALU), 
             .result(ALU_result_wire), 
             .zero_flag(zero_out), 
             .alu_control(ALUControl)); // [2:0]
             
    buff_reg buff_1 (.clk(clk), .rst(rst),
              .data_in(read_data_out), 
              .data_out(buff_1_to_mux4));             
             
    buff_reg buff_2 (.clk(clk), .rst(rst),
              .data_in(ALU_result_wire), 
              .data_out(buff_2_to_mux4));
              
    mux_3x1 mux_4 (
            .out(mux_4_out),
            .d0(buff_2_to_mux4),             
            .d1(buff_1_to_mux4),
            .d2(ALU_result_wire),            
            .s(ResultSrc)); // from control unit
            
    assign pc   = pc_out;
    assign insn = inst_mem_out;

    // [NEW] Map your internal memory wires to the outside world!
    // I am using the exact wire names from your top module code.
    assign mem_adr = mux_1_to_inst_mem;   
    assign mem_wd  = reg_buff_data_out_2; 
    assign mem_we  = MemWrite;            
    assign mem_rd  = read_data_out;     
    
    
    wire [6:0] Op;
    wire [2:0] funct3;
    wire       funct7_5;

    assign Op       = inst_mem_out[6:0];
    assign funct3   = inst_mem_out[14:12];
    assign funct7_5 = inst_mem_out[30];  
    
    control_unit control_inst (
        .clk(clk),
        .rst(rst),
        .op(Op),
        .funct3(funct3),
        .funct7_5(funct7_5),
        .Zero(zero_out),

        .PCWrite(PCWrite),
        .AdrSrc(AdrSrc),
        .MemWrite(MemWrite),
        .IRWrite(IRWrite),
        .ResultSrc(ResultSrc),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ImmSrc(ImmSrc),
        .RegWrite(Regwrite),  // Matches your 'Regwrite' wire declaration
        .ALUControl(ALUControl)
    );

endmodule
