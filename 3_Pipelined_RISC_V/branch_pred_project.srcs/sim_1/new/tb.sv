// Code your testbench here
// or browse Examples

`timescale 1ns / 1ps

module tb_RISCV_Pipelined;

    reg clk;
    reg rst;

    // Instantiate the pipelined processor
    RISCV_Pipelined dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation: 100 MHz (period = 10 ns)
    always #5 clk = ~clk;

    // Reset sequence
    initial begin
        //$dumpfile("dump.vcd");
        //$dumpvars(0, tb_RISCV_Pipelined);
        
        clk = 0;
        rst = 1;
        #20;               // Hold reset for 2 cycles
        rst = 0;
        #500;              // Run for 50 cycles (adjust as needed)
        $finish;
    end

    //--------------------------------------------------------------
    // Pipeline trace printing (on negedge to capture stable values)
    //--------------------------------------------------------------
    // Internal hierarchical paths (based on the structure of RISCV_Pipelined)
    // Fetch stage
    wire [31:0] pc_F      = dut.data_path_inst.pc_outF;
    wire [31:0] instr_F   = dut.data_path_inst.instrF;
    wire [31:0] pc_plus4_F = dut.data_path_inst.PCPlus4F;

    // Decode stage
    wire [31:0] instr_D   = dut.data_path_inst.instrD;
    wire [31:0] pc_D      = dut.data_path_inst.pc_outD;
    wire [31:0] imm_D     = dut.data_path_inst.ImmediateD;
    wire [4:0]  rs1_D     = dut.data_path_inst.rs1_D;
    wire [4:0]  rs2_D     = dut.data_path_inst.rs2_D;
    wire [4:0]  rd_D      = dut.data_path_inst.rd_D;
    wire [31:0] srca_D    = dut.data_path_inst.SrcA_D;
    wire [31:0] writedata_D = dut.data_path_inst.WriteDataD;

    // Execute stage
    wire [31:0] pc_E      = dut.data_path_inst.pc_outE;
    wire [31:0] srca_E    = dut.data_path_inst.SrcA_E;
    wire [31:0] writedata_E = dut.data_path_inst.WriteDataE;
    wire [31:0] srcb_E    = dut.data_path_inst.SrcB_E;
    wire [31:0] alu_out_E = dut.data_path_inst.ALUResultE;
    wire        zero_E    = dut.data_path_inst.zeroE;
    wire [31:0] pctarget_E = dut.data_path_inst.PCTargetE;
    wire [4:0]  rs1_E     = dut.data_path_inst.rs1_E;
    wire [4:0]  rs2_E     = dut.data_path_inst.rs2_E;
    wire [4:0]  rd_E      = dut.data_path_inst.rd_E;

    // Memory stage
    wire [31:0] alu_out_M = dut.data_path_inst.ALUResultM;
    wire [31:0] writedata_M = dut.data_path_inst.WriteDataM;
    wire [31:0] readdata_M = dut.data_path_inst.ReadDataM;
    wire [4:0]  rd_M      = dut.data_path_inst.rd_M;

    // Writeback stage
    wire [31:0] result_W  = dut.data_path_inst.ResultW;
    wire [4:0]  rd_W      = dut.data_path_inst.rd_W;

    // Control signals (from control_unit)
    wire        PCSrcE     = dut.control_unit_inst.PCSrcE;
    wire        RegWriteW  = dut.control_unit_inst.RegWriteW;
    wire        ALUSrcE    = dut.control_unit_inst.ALUSrcE;
    wire [2:0]  ALUcontrolE = dut.control_unit_inst.ALUcontrolE;
    wire        MemWriteM  = dut.control_unit_inst.MemWriteM;
    wire        MemReadM   = dut.control_unit_inst.MemReadM;
    wire [1:0]  ResultSrcW = dut.control_unit_inst.ResultSrcW;

    // Hazard unit signals
    wire [1:0]  ForwardAE = dut.control_unit_inst.ForwardAE;
    wire [1:0]  ForwardBE = dut.control_unit_inst.ForwardBE;
    wire        StallF    = dut.control_unit_inst.StallF;
    wire        StallD    = dut.control_unit_inst.StallD;
    wire        FlushE    = dut.control_unit_inst.FlushE;
    wire        FlushD    = dut.control_unit_inst.FlushD;

    // Pipeline registers content summary
    always @(negedge clk) begin
        if (!rst) begin
            $display("--------------------------------------------------------------");
            $display("Time: %0t ns", $time);
            $display("FETCH:      PC=0x%8h  Instr=0x%8h  PC+4=0x%8h", pc_F, instr_F, pc_plus4_F);
            $display("DECODE:     PC=0x%8h  Instr=0x%8h  Imm=0x%8h  rs1=%2d rs2=%2d rd=%2d  SrcA=0x%8h  WriteData=0x%8h",
                     pc_D, instr_D, imm_D, rs1_D, rs2_D, rd_D, srca_D, writedata_D);
            $display("EXECUTE:    PC=0x%8h  SrcA=0x%8h  SrcB=0x%8h  ALUout=0x%8h  Zero=%b  ALUctrl=%3b  PCSrc=%b  ALUSrc=%b",
                     pc_E, srca_E, srcb_E, alu_out_E, zero_E, ALUcontrolE, PCSrcE, ALUSrcE);
            $display("MEMORY:     ALUres=0x%8h  WriteData=0x%8h  MemR=%b  MemW=%b  ReadData=0x%8h  rd=%2d",
                     alu_out_M, writedata_M, MemReadM, MemWriteM, readdata_M, rd_M);
            $display("WRITEBACK:  Result=0x%8h  RegWrite=%b  rd=%2d  ResultSrc=%b", result_W, RegWriteW, rd_W, ResultSrcW);
            $display("HAZARD:     ForwardAE=%b ForwardBE=%b  StallF=%b StallD=%b  FlushD=%b FlushE=%b",
                     ForwardAE, ForwardBE, StallF, StallD, FlushD, FlushE);
            $display("REGISTERS:  t0(x5)=0x%8h  t1(x6)=0x%8h  t2(x7)=0x%8h  t3(x28)=0x%8h",
                     dut.data_path_inst.reg_file_inst.reg_file[5],
                     dut.data_path_inst.reg_file_inst.reg_file[6],
                     dut.data_path_inst.reg_file_inst.reg_file[7],
                     dut.data_path_inst.reg_file_inst.reg_file[28]);
            $display("--------------------------------------------------------------");
        end
    end

endmodule