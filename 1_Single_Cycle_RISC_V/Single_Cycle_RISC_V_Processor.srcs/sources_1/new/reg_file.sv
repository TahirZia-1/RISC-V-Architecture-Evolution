`timescale 1ns/1ps

module REG_FILE (
    input      [4:0]  read_reg_num1, read_reg_num2, write_reg,
    input      [31:0] write_data,
    output     [31:0] read_data1, read_data2,
    input             regwrite, clock, reset
);
    reg [31:0] reg_memory [31:0];
    integer i;

    always@(posedge clock or posedge reset) begin
        if (reset) begin 
            for (i = 0; i < 32; i = i + 1) begin
                reg_memory[i] <= 32'b0; 
            end
        end
        else if (regwrite && (write_reg != 0)) begin
            reg_memory[write_reg] <= write_data;
        end
    end

    assign read_data1 = reg_memory[read_reg_num1];
    assign read_data2 = reg_memory[read_reg_num2];
endmodule