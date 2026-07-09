`timescale 1ns / 1ps

module tb_RISCV_Pipelined;

    reg clk;
    reg rst;

    RISCV_Pipelined dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    integer total_branches = 0;
    integer mispredict_count = 0;
    real    current_accuracy = 0.0;

    initial begin
        //$dumpfile("dump.vcd");
        //$dumpvars(0, tb_RISCV_Pipelined);
        
        clk = 0;
        rst = 1;
        #20;               
        rst = 0;
        
        #8000;             
        
        $display("\n==============================================================");
        $display("                  SIMULATION FINISHED                         ");
        $display("==============================================================");
        $display(" Total Branches/Jumps Resolved : %0d", total_branches);
        $display(" Total Mispredictions          : %0d", mispredict_count);
        $display(" Correct Predictions           : %0d", (total_branches - mispredict_count));
        $display(" FINAL BRANCH ACCURACY         : %0.2f%%", current_accuracy);
        $display("==============================================================\n");
        
        $finish;
    end

    
    // Fetch stage
    wire [31:0] pc_F       = dut.data_path_inst.pc_outF;
    wire [31:0] instr_F    = dut.data_path_inst.instrF;
    wire [31:0] pc_plus4_F = dut.data_path_inst.PCPlus4F;

    // Gshare Predictor State
    wire [7:0]  ghr        = dut.data_path_inst.bp.GHR;
    wire [7:0]  hash_F     = dut.data_path_inst.bp.hash_F;
    wire [1:0]  pht_state  = dut.data_path_inst.bp.PHT[hash_F];
    wire        pred_taken = dut.data_path_inst.predict_taken_F;
    wire [31:0] pred_tgt   = dut.data_path_inst.predict_target_F;

    // Decode stage
    wire [31:0] instr_D    = dut.data_path_inst.instrD;
    wire [31:0] pc_D       = dut.data_path_inst.pc_outD;
    wire [4:0]  rs1_D      = dut.data_path_inst.rs1_D;
    wire [4:0]  rs2_D      = dut.data_path_inst.rs2_D;
    wire [4:0]  rd_D       = dut.data_path_inst.rd_D;

    // Execute stage
    wire [31:0] pc_E       = dut.data_path_inst.pc_outE;
    wire [31:0] alu_out_E  = dut.data_path_inst.ALUResultE;
    wire        zero_E     = dut.data_path_inst.zeroE;
    wire [31:0] pctarget_E = dut.data_path_inst.PCTargetE;
    wire        mispredict = dut.mispredict_E; 

    // Memory stage
    wire [31:0] alu_out_M  = dut.data_path_inst.ALUResultM;
    wire [4:0]  rd_M       = dut.data_path_inst.rd_M;

    // Writeback stage
    wire [31:0] result_W   = dut.data_path_inst.ResultW;
    wire [4:0]  rd_W       = dut.data_path_inst.rd_W;
    wire        RegWriteW  = dut.control_unit_inst.RegWriteW;

    // Hazard unit signals
    wire        StallF     = dut.control_unit_inst.StallF;
    wire        StallD     = dut.control_unit_inst.StallD;
    wire        FlushE     = dut.control_unit_inst.FlushE;
    wire        FlushD     = dut.control_unit_inst.FlushD;

    always @(negedge clk) begin
        if (!rst) begin
            
            if (dut.BranchE || dut.JumpE) begin
                total_branches = total_branches + 1;
                if (mispredict) begin
                    mispredict_count = mispredict_count + 1;
                end
                current_accuracy = ((total_branches - mispredict_count) * 100.0) / total_branches;
            end

            $display("--------------------------------------------------------------");
            $display("Time: %0t ns", $time);
            $display("FETCH:    PC=0x%8h  Instr=0x%8h  | GSHARE: GHR=%b Hash=%b PHT=%b PredTaken=%b PredTgt=0x%8h", 
                      pc_F, instr_F, ghr, hash_F, pht_state, pred_taken, pred_tgt);
            $display("DECODE:   PC=0x%8h  Instr=0x%8h  rs1=%2d rs2=%2d rd=%2d",
                      pc_D, instr_D, rs1_D, rs2_D, rd_D);
            $display("EXECUTE:  PC=0x%8h  ALUout=0x%8h  Zero=%b | MISPREDICT=%b ActualTgt=0x%8h",
                      pc_E, alu_out_E, zero_E, mispredict, pctarget_E);
            $display("MEMORY:   ALUres=0x%8h  rd=%2d", alu_out_M, rd_M);
            $display("WRITEBACK:Result=0x%8h  RegWrite=%b  rd=%2d", result_W, RegWriteW, rd_W);
            $display("HAZARD:   StallF=%b StallD=%b FlushD=%b FlushE=%b", StallF, StallD, FlushD, FlushE);
            
            if (total_branches > 0) begin
                $display("STATS:    Branches Resolved: %0d | Mispredicts: %0d | ACCURACY: %0.2f%%", 
                          total_branches, mispredict_count, current_accuracy);
            end

            $display("REGS:     t0(x5)=0x%8h  t1(x6)=0x%8h  t2(x7)=0x%8h  t3(x28)=0x%8h",
                      dut.data_path_inst.reg_file_inst.reg_file[5],
                      dut.data_path_inst.reg_file_inst.reg_file[6],
                      dut.data_path_inst.reg_file_inst.reg_file[7],
                      dut.data_path_inst.reg_file_inst.reg_file[28]);
        end
    end

endmodule