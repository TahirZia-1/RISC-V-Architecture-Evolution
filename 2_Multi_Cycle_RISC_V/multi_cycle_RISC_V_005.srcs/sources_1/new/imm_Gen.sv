`timescale 1ns/1ps

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
