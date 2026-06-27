`timescale 1ns/1ps

module REG_FILE_TB;

reg [4:0] read_reg_num1;
reg [4:0] read_reg_num2;
reg [4:0] write_reg;
reg [31:0] write_data;
reg clock, reset, regwrite;
wire [31:0] read_data1;
wire [31:0] read_data2;

REG_FILE uut (
        .read_reg_num1(read_reg_num1),
        .read_reg_num2(read_reg_num2),
        .write_reg(write_reg),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .regwrite(regwrite),
        .clock(clock),
        .reset(reset));
        
always #5 clock = ~clock;

initial begin

read_reg_num1 = 0;
read_reg_num2 = 0;
write_reg = 0;
write_data = 0;
clock = 0;
reset = 1;
regwrite = 0;

$monitor("Time=%0t | reset=%b | regwrite=%b | write_reg=%0d | write_data=%0d | read_reg1=%0d | read_reg2=%0d | read_data1=%0d | read_data2=%0d" ,
$time, reset, regwrite, write_reg, write_data, read_reg_num1, read_reg_num2, read_data1, read_data2);

#10 reset = 0;

// write value 10 to reg x5
#10 regwrite = 1;
write_reg = 5;
write_data = 10;
#10 regwrite = 0;

// read register x5
read_reg_num1 = 5;

// try writing to x0
#10 regwrite = 1;   // Control Signal
write_reg = 0;      // Address
write_data = 99;    // should be ignored
#10 regwrite = 0;

end
endmodule


