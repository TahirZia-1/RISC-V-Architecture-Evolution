`timescale 1ns/1ps

module control_unit(
    input  [6:0] op,
    input  [2:0] funct3,
    input        funct7_5,
    input        Zero,
    output       PCSrc,
    output [1:0] ResultSrc,
    output       MemWrite,
    output       ALUSrc,
    output [1:0] ImmSrc,
    output       RegWrite,
    output [2:0] ALUControl
);

    wire [1:0] ALUOp;
    wire       Branch;
    wire       Jump; // Jump signal wire

    assign PCSrc = Jump | (Branch & Zero);

    main_decoder md_inst (
        .Op(op),
        .RegWrite(RegWrite),
        .ImmSrc(ImmSrc),
        .ALUSrc(ALUSrc),
        .MemWrite(MemWrite),
        .ResultSrc(ResultSrc),
        .Branch(Branch),
        .ALUOp(ALUOp),
        .Jump(Jump) 
    );

    alu_decoder ad_inst (
        .ALUOp(ALUOp),
        .funct3(funct3),
        .op_5(op[5]),
        .funct7_5(funct7_5),
        .ALUControl(ALUControl)
    );

endmodule


module main_decoder(
    input      [6:0] Op,
    output reg       RegWrite,
    output reg [1:0] ImmSrc,
    output reg       ALUSrc,
    output reg       MemWrite,
    output reg [1:0] ResultSrc, 
    output reg       Branch,
    output reg [1:0] ALUOp,
    output reg       Jump       // Added Jump signal
);

    always @(*) begin
        case(Op)
            // lw instruction
            7'b0000011: begin
                RegWrite  = 1'b1;
                ImmSrc    = 2'b00;
                ALUSrc    = 1'b1;
                MemWrite  = 1'b0;
                ResultSrc = 2'b01; 
                Branch    = 1'b0;
                ALUOp     = 2'b00;
                Jump      = 1'b0;  
            end

            // sw instruction
            7'b0100011: begin
                RegWrite  = 1'b0;
                ImmSrc    = 2'b01;
                ALUSrc    = 1'b1;
                MemWrite  = 1'b1;
                ResultSrc = 2'bxx;
                Branch    = 1'b0;
                ALUOp     = 2'b00;
                Jump      = 1'b0;  
            end

            // R-type instruction
            7'b0110011: begin
                RegWrite  = 1'b1;
                ImmSrc    = 2'bxx; 
                ALUSrc    = 1'b0;
                MemWrite  = 1'b0;
                ResultSrc = 2'b00; 
                Branch    = 1'b0;
                ALUOp     = 2'b10;
                Jump      = 1'b0;  
            end

            // beq instruction
            7'b1100011: begin
                RegWrite  = 1'b0;
                ImmSrc    = 2'b10;
                ALUSrc    = 1'b0;
                MemWrite  = 1'b0;
                ResultSrc = 2'bxx;
                Branch    = 1'b1;
                ALUOp     = 2'b01;
                Jump      = 1'b0;  
            end

            // [NEW] jal instruction (J-Type)
            7'b1101111: begin
                RegWrite  = 1'b1;     
                ImmSrc    = 2'b11;    
                ALUSrc    = 1'bx;     
                MemWrite  = 1'b0;     
                ResultSrc = 2'b10;    
                Branch    = 1'b0;
                ALUOp     = 2'bxx;
                Jump      = 1'b1;     // Unconditional jump
            end

            // default case
            default: begin
                RegWrite  = 1'b0;
                ImmSrc    = 2'b00;
                ALUSrc    = 1'b0;
                MemWrite  = 1'b0;
                ResultSrc = 2'b00;
                Branch    = 1'b0;
                ALUOp     = 2'b00;
                Jump      = 1'b0; 
            end
        endcase
    end
endmodule



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