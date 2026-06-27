`timescale 1ns / 1ps

module INST_MEM_tb();

reg [31:0] PC;
wire [31:0] Instruction_Code;

INST_MEM uut (.PC(PC) ,.Instruction_Code(Instruction_Code));

initial begin

$monitor("%0t\t%h\t%h", $time, PC, Instruction_Code);

end

initial begin

PC = 32'd0;        #20;
PC = 32'd4;        #20;
PC = 32'd8;        #20;
PC = 32'd12;        #20;
PC = 32'd16;        #20;
PC = 32'd20;        #20;
PC = 32'd24;        #20;
PC = 32'd28;        #20;

#20 $finish;
end

endmodule

