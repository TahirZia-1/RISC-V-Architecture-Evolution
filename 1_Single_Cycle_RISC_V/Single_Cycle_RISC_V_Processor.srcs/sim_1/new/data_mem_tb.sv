`timescale 1ns/1ps

module DATA_MEM_TB;

reg clk, mem_read, mem_write;
reg [31:0] address, data_in;
wire [31:0] data_out;

data_mem uut (.*);

always #5 clk = ~clk;

initial begin
    clk = 0;
    mem_read = 0;
    mem_write = 0;
    address = 32'b0;
    data_in = 32'b0;

    #20;

    @(posedge clk);
    address   <= 32'd8;
    data_in   <= 32'hAABBCCDD;
    mem_write <= 1'b1;

    @(posedge clk);
    mem_write <= 1'b0;
    
    #20;

    @(posedge clk);
    address  <= 32'd8;
    mem_read <= 1'b1;

    @(posedge clk);
    mem_read <= 1'b0;

    #40;
    $stop;
end

endmodule
