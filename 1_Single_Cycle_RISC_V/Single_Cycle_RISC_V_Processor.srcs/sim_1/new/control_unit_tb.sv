`timescale 1ns / 1ps

module tb_main_decoder;

reg  [6:0] Op;
wire       RegWrite;
wire [1:0] ImmSrc;
wire       ALUSrc;
wire       MemWrite;
wire       ResultSrc;
wire       Branch;
wire [1:0] ALUOp;

main_decoder dut(
    .Op(Op),
    .RegWrite(RegWrite),
    .ImmSrc(ImmSrc),
    .ALUSrc(ALUSrc),
    .MemWrite(MemWrite),
    .ResultSrc(ResultSrc),
    .Branch(Branch),
    .ALUOp(ALUOp)
);

initial begin
    $display("---------------------------------------------------------------");
    $display(" Op       RegWrite ImmSrc ALUSrc MemWrite ResultSrc Branch ALUOp");
    $display("---------------------------------------------------------------");

    // lw
    Op = 7'b0000011;
    #10;
    $display("%b     %b       %b      %b       %b        %b        %b     %b",
              Op, RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, Branch, ALUOp);

    // sw
    Op = 7'b0100011;
    #10;
    $display("%b     %b       %b      %b       %b        %b        %b     %b",
              Op, RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, Branch, ALUOp);

    // R-type
    Op = 7'b0110011;
    #10;
    $display("%b     %b       %b      %b       %b        %b        %b     %b",
              Op, RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, Branch, ALUOp);

    // beq
    Op = 7'b1100011;
    #10;
    $display("%b     %b       %b      %b       %b        %b        %b     %b",
              Op, RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, Branch, ALUOp);

    // invalid opcode
    Op = 7'b1111111;
    #10;
    $display("%b     %b       %b      %b       %b        %b        %b     %b",
              Op, RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, Branch, ALUOp);

    $display("---------------------------------------------------------------");
    $finish;
end

endmodule