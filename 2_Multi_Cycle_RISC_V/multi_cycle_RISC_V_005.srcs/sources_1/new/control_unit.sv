`timescale 1ns/1ps

// 1. TOP LEVEL CONTROL UNIT

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

    assign PCWrite = PCUpdate | (Branch & Zero);

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

    alu_decoder ad_inst (
        .ALUOp(ALUOp),
        .funct3(funct3),
        .op_5(op[5]),
        .funct7_5(funct7_5),
        .ALUControl(ALUControl)
    );

    instr_decoder id_inst (
        .op(op),
        .ImmSrc(ImmSrc)
    );

endmodule


// 2. THE FINITE STATE MACHINE (Main Decoder)

module main_fsm(
    input clk, rst,
    input [6:0] op,
    
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

    always @(posedge clk) begin
        if (rst) state <= FETCH;
        else     state <= next_state;
    end

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

    always @(*) begin
        PCUpdate=0; Branch=0; RegWrite=0; MemWrite=0; IRWrite=0; AdrSrc=0; // for no latches
        ResultSrc=2'b00; ALUSrcA=2'b00; ALUSrcB=2'b00; ALUOp=2'b00;

        case(state)
            FETCH: begin
                AdrSrc    = 1'b0;
                IRWrite   = 1'b1;
                ALUSrcA   = 2'b00; // PC
                ALUSrcB   = 2'b10; 
                ALUOp     = 2'b00; // Add
                ResultSrc = 2'b10; // ALUResult
                PCUpdate  = 1'b1;
            end
            DECODE: begin
                ALUSrcA   = 2'b01; // OldPC
                ALUSrcB   = 2'b01; 
                ALUOp     = 2'b00; 
            end
            MEMADR: begin
                ALUSrcA   = 2'b10; // A (rs1)
                ALUSrcB   = 2'b01; 
                ALUOp     = 2'b00; // Add
            end
            MEMREAD: begin
                ResultSrc = 2'b00; // ALUOut
                AdrSrc    = 1'b1;  // Result wire
            end
            MEMWB: begin
                ResultSrc = 2'b01; 
                RegWrite  = 1'b1;
            end
            MEMWRITE: begin
                ResultSrc = 2'b00; // ALUOut
                AdrSrc    = 1'b1;  
                MemWrite  = 1'b1;
            end
            EXECUTER: begin
                ALUSrcA   = 2'b10; // A (rs1)
                ALUSrcB   = 2'b00; // B (rs2)
                ALUOp     = 2'b10; 
            end
            EXECUTEI: begin
                ALUSrcA   = 2'b10; 
                ALUSrcB   = 2'b01; 
                ALUOp     = 2'b10; 
            end
            ALUWB: begin
                ResultSrc = 2'b00; // ALUOut
                RegWrite  = 1'b1;
            end
            JAL: begin
                ALUSrcA   = 2'b01; // OldPC
                ALUSrcB   = 2'b10; 
                ALUOp     = 2'b00; // Add (Calculates OldPC + 4 to save to Reg)
                ResultSrc = 2'b00; 
                PCUpdate  = 1'b1;
            end
            BEQ: begin
                ALUSrcA   = 2'b10; // A (rs1)
                ALUSrcB   = 2'b00; // B (rs2)
                ALUOp     = 2'b01; 
                ResultSrc = 2'b00; 
                Branch    = 1'b1;
            end
        endcase
    end
endmodule


// 3. IMMEDIATE DECODER

module instr_decoder(
    input [6:0] op,
    output reg [1:0] ImmSrc
);
    always @(*) begin
        case(op)
            7'b0100011: ImmSrc = 2'b01;
            7'b1100011: ImmSrc = 2'b10; 
            7'b1101111: ImmSrc = 2'b11; 
            default:    ImmSrc = 2'b00; 
        endcase
    end
endmodule


// 4. ALU DECODER

module alu_decoder(
    input [1:0] ALUOp,
    input [2:0] funct3,
    input op_5,
    input funct7_5,
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