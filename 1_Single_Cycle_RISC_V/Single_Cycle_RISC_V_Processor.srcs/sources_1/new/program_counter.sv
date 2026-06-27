`timescale 1ns / 1ps

module PC_32bit(
    input            clk, rst, 
    input      [31:0] pc_in,  
    output reg [31:0] pc_out
);
    always@(posedge clk) begin
        if (rst) pc_out <= 32'b0;
        else     pc_out <= pc_in;
    end
endmodule