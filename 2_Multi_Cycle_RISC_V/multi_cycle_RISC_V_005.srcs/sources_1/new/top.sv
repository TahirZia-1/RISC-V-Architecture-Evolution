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
    output wire [31:0] insn, 
    output wire [31:0] mem_adr,  // Address going into memory
    output wire [31:0] mem_wd,   // Data being written to memory
    output wire        mem_we,   // Memory Write Enable flag
    output wire [31:0] mem_rd    // Data coming out of memory
);

    wire [31:0] mux_1_to_inst_mem;
    wire [31:0] pc_out;
    wire [31:0] extend_out;
    wire [31:0] inst_mem_out;
    wire [31:0] read_data_1_wire;
    wire [31:0] read_data_2_wire;
    wire [31:0] ALU_result_wire;

    wire [4:0]  inst_mem_to_reg_file_1;
    wire [4:0]  inst_mem_to_reg_file_2;
    wire [4:0]  inst_mem_to_reg_file_3;
    
    
    wire [31:0] read_data_out;
    wire [31:0] old_pc_out;
    wire [31:0] reg_buff_data_out_1;
    wire [31:0] reg_buff_data_out_2;
    wire [31:0] mux_2_to_ALU;
    wire [31:0] mux_3_to_ALU;
    wire [31:0] buff_1_to_mux4;
    wire [31:0] buff_2_to_mux4;
    wire [31:0] mux_4_out;
    
    // control wires
    // wire [6:0]  Op;
    wire AdrSrc;
    wire PCWrite;
    wire MemWrite;
    wire IRWrite;
    wire Regwrite;
    wire [1:0] ImmSrc;
    wire [1:0] ALUSrcA;
    wire [1:0] ALUSrcB;
    wire [2:0] ALUControl;
    wire zero_out;
    wire [1:0] ResultSrc;
    

    mux_2x1 mux_1 (.out(mux_1_to_inst_mem), 
                   .x(pc_out), 
                   .y(mux_4_out), 
                   .s(AdrSrc)); 

    PC_32bit pc_1 (.clk(clk), 
                   .rst(rst), 
                   .PCWrite(PCWrite),  
                   .pc_in(mux_4_out), 
                   .pc_out(pc_out));
                   
    INST_MEM inst (.clk(clk), 
                   .MemWrite(MemWrite),
                   .Adr(mux_1_to_inst_mem), 
                   .WD(reg_buff_data_out_2),  
                   .RD(read_data_out)); 
                   
    Old_PC pcold (.clk(clk), .rst(rst),
                  .IRWrite(IRWrite),
                  .pc_in(pc_out),
                  .inst_mem_in(read_data_out),
                  .old_pc_out(old_pc_out),
                  .inst_mem_out(inst_mem_out));
                  
    assign inst_mem_to_reg_file_1 = inst_mem_out[19:15];
    assign inst_mem_to_reg_file_2 = inst_mem_out[24:20];
    assign inst_mem_to_reg_file_3 = inst_mem_out[11:7];
                  
    REG_FILE reg_f (.clock(clk), .reset(rst),
                    .read_reg_num1(inst_mem_to_reg_file_1), 
                    .read_reg_num2(inst_mem_to_reg_file_2), 
                    .write_reg(inst_mem_to_reg_file_3), 
                    .write_data(mux_4_out), 
                    .read_data1(read_data_1_wire), 
                    .read_data2(read_data_2_wire), 
                    .regwrite(Regwrite));
                
    buff_reg_file reg_ff (.clk(clk), .rst(rst),
                   .RD1(read_data_1_wire),
                   .RD2(read_data_2_wire),
                   .data_out_1(reg_buff_data_out_1),
                   .data_out_2(reg_buff_data_out_2));
                                    
    mux_3x1 mux_2 (
            .out(mux_2_to_ALU),
            .d0(pc_out),             
            .d1(old_pc_out),
            .d2(reg_buff_data_out_1),            
            .s(ALUSrcA)); // from control unit
                  
    imm_Gen imm (.instruction(inst_mem_out), 
                 .immediate_output(extend_out), 
                 .ImmSrc(ImmSrc)); // ImmSrc [1:0]      
                 
    mux_3x1 mux_3 (
            .out(mux_3_to_ALU), 
            .d0(read_data_2_wire),             
            .d1(extend_out),
            .d2(32'd4),            
            .s(ALUSrcB)); // from control unit  
            
    ALU alu (.in1(mux_2_to_ALU), 
             .in2(mux_3_to_ALU), 
             .result(ALU_result_wire), 
             .zero_flag(zero_out), 
             .alu_control(ALUControl)); // [2:0]
             
    buff_reg buff_1 (.clk(clk), .rst(rst),
              .data_in(read_data_out), 
              .data_out(buff_1_to_mux4));             
             
    buff_reg buff_2 (.clk(clk), .rst(rst),
              .data_in(ALU_result_wire), 
              .data_out(buff_2_to_mux4));
              
    mux_3x1 mux_4 (
            .out(mux_4_out),
            .d0(buff_2_to_mux4),             
            .d1(buff_1_to_mux4),
            .d2(ALU_result_wire),            
            .s(ResultSrc)); // from control unit
            
    assign pc   = pc_out;
    assign insn = inst_mem_out;


    assign mem_adr = mux_1_to_inst_mem;   
    assign mem_wd  = reg_buff_data_out_2; 
    assign mem_we  = MemWrite;            
    assign mem_rd  = read_data_out;     
    
    
    wire [6:0] Op;
    wire [2:0] funct3;
    wire       funct7_5;

    assign Op       = inst_mem_out[6:0];
    assign funct3   = inst_mem_out[14:12];
    assign funct7_5 = inst_mem_out[30];  
    
    control_unit control_inst (
        .clk(clk),
        .rst(rst),
        .op(Op),
        .funct3(funct3),
        .funct7_5(funct7_5),
        .Zero(zero_out),

        .PCWrite(PCWrite),
        .AdrSrc(AdrSrc),
        .MemWrite(MemWrite),
        .IRWrite(IRWrite),
        .ResultSrc(ResultSrc),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ImmSrc(ImmSrc),
        .RegWrite(Regwrite), 
        .ALUControl(ALUControl)
    );

endmodule