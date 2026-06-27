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
    output wire [31:0] insn 
);

    wire [31:0] mux_1_to_pc;
    wire [31:0] pc_out;
    wire [31:0] adder_1_to_mux_1;
    wire [31:0] adder_2_to_mux_1;
    wire [31:0] extend_out;
    wire [31:0] inst_mem_out;
    wire [31:0] read_data_1_wire;
    wire [31:0] read_data_2_wire;
    wire [31:0] mux_2_to_ALU;
    wire [31:0] ALU_result_wire;
    wire        zero_out;
    wire [31:0] read_data_from_mem_to_mux_3;
    wire        mem_write_out;
    wire [31:0] mux_3_to_reg_file;

    wire [4:0]  inst_mem_to_reg_file_1;
    wire [4:0]  inst_mem_to_reg_file_2;
    wire [4:0]  inst_mem_to_reg_file_3;

    wire [6:0]  Op;
    wire        reg_write_to_reg_file;
    wire [1:0]  control_to_extend;
    wire        ALUSrc_to_mux_2;
    wire [1:0]  ResultSrc_to_mux3;
    wire        control_to_mux_1;
    wire [2:0]  aluControl;

    // Instantiations
    mux_2x1 mux_1 (.out(mux_1_to_pc), .x(adder_1_to_mux_1), .y(adder_2_to_mux_1), .s(control_to_mux_1)); 

    PC_32bit pc_1 (.clk(clk), .rst(rst), .pc_in(mux_1_to_pc), .pc_out(pc_out));

    adder_32 add_1 (.a(pc_out), .b(32'd4), .sum(adder_1_to_mux_1));

    adder_32 add_2 (.a(pc_out), .b(extend_out), .sum(adder_2_to_mux_1));

    imm_Gen imm (.instruction(inst_mem_out), .immediate_output(extend_out), .ImmSrc(control_to_extend)); 

    INST_MEM inst (.PC(pc_out), .Instruction_Code(inst_mem_out)); 

    assign inst_mem_to_reg_file_1 = inst_mem_out[19:15];
    assign inst_mem_to_reg_file_2 = inst_mem_out[24:20];
    assign inst_mem_to_reg_file_3 = inst_mem_out[11:7];
    assign Op = inst_mem_out[6:0];

    REG_FILE reg_f (
        .clock(clk), 
        .reset(rst), 
        .read_reg_num1(inst_mem_to_reg_file_1), 
        .read_reg_num2(inst_mem_to_reg_file_2), 
        .write_reg(inst_mem_to_reg_file_3), 
        .write_data(mux_3_to_reg_file), 
        .read_data1(read_data_1_wire), 
        .read_data2(read_data_2_wire), 
        .regwrite(reg_write_to_reg_file)
    );

    mux_2x1 mux_2 (.out(mux_2_to_ALU), .x(read_data_2_wire), .y(extend_out), .s(ALUSrc_to_mux_2));

    ALU alu (.in1(read_data_1_wire), .in2(mux_2_to_ALU), .result(ALU_result_wire), .zero_flag(zero_out), .alu_control(aluControl)); 

    data_mem data_m (.CLK(clk), .WE(mem_write_out), .A(ALU_result_wire), .WD(read_data_2_wire), .RD(read_data_from_mem_to_mux_3));


    mux_3x1 mux_3 (
        .out(mux_3_to_reg_file), 
        .d0(ALU_result_wire),             
        .d1(read_data_from_mem_to_mux_3),
        .d2(adder_1_to_mux_1),            
        .s(ResultSrc_to_mux3)
    );

    wire funct7_5;
    wire [2:0] funct3;
    assign funct3   = inst_mem_out[14:12];
    assign funct7_5 = inst_mem_out[30];

    assign pc   = pc_out;
    assign insn = inst_mem_out;

    control_unit control_dec (
        .op(Op), 
        .RegWrite(reg_write_to_reg_file), 
        .ImmSrc(control_to_extend), 
        .ALUSrc(ALUSrc_to_mux_2), 
        .MemWrite(mem_write_out), 
        .ResultSrc(ResultSrc_to_mux3), 
        .funct3(funct3), 
        .funct7_5(funct7_5), 
        .Zero(zero_out), 
        .PCSrc(control_to_mux_1), 
        .ALUControl(aluControl)
    );

endmodule