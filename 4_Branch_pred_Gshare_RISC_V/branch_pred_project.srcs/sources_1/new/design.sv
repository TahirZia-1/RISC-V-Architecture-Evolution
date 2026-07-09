`timescale 1ns/1ps

// ==============================================================================
// 1. GSHARE BRANCH PREDICTOR
// ==============================================================================
module gshare_predictor #(
    parameter GHR_BITS = 8
)(
    input  logic clk,
    input  logic rst,

    // Fetch Stage (Prediction)
    input  logic [31:0] pc_F,
    output logic [GHR_BITS-1:0] hash_F,
    output logic        predict_taken_F,
    output logic [31:0] predict_target_F,

    // Execute Stage (Training / Update)
    input  logic        BranchE,
    input  logic        JumpE,
    input  logic [31:0] pc_E,
    input  logic [GHR_BITS-1:0] hash_E,
    input  logic        actual_taken_E,
    input  logic [31:0] actual_target_E
);

    // 256-entry Pattern History Table (2-bit saturating counters)
    logic [1:0]  PHT [0:(1<<GHR_BITS)-1];
    
    // 256-entry Branch Target Buffer
    logic [31:0] BTB [0:(1<<GHR_BITS)-1];
    logic [31:0] BTB_tag [0:(1<<GHR_BITS)-1];
    logic        valid_BTB [0:(1<<GHR_BITS)-1];
    
    // Global History Register
    logic [GHR_BITS-1:0] GHR;

    // The Gshare Hash: XOR the PC with the Global History
    assign hash_F = pc_F[GHR_BITS+1:2] ^ GHR;

    logic hit;
    assign hit = valid_BTB[hash_F] && (BTB_tag[hash_F] == pc_F);

    assign predict_target_F = hit ? BTB[hash_F] : 32'b0;
    assign predict_taken_F  = hit && (PHT[hash_F] >= 2'b10);

    always_ff @(posedge clk) begin
        if (rst) begin
            GHR <= 0;
            for (int i=0; i<(1<<GHR_BITS); i++) begin
                PHT[i] <= 2'b01; 
                valid_BTB[i] <= 1'b0;
                BTB[i] <= 32'b0;
                BTB_tag[i] <= 32'b0;
            end
        end else if (BranchE || JumpE) begin
            if (BranchE) GHR <= {GHR[GHR_BITS-2:0], actual_taken_E};

            if (actual_taken_E) begin
                if (PHT[hash_E] != 2'b11) PHT[hash_E] <= PHT[hash_E] + 1; // Saturate at 11
            end else begin
                if (PHT[hash_E] != 2'b00) PHT[hash_E] <= PHT[hash_E] - 1; // Saturate at 00
            end

            // 3. Update Branch Target Buffer
            if (actual_taken_E) begin
                BTB[hash_E] <= actual_target_E;
                BTB_tag[hash_E] <= pc_E;
                valid_BTB[hash_E] <= 1'b1;
            end
        end
    end
endmodule


module pc(
    input logic clk,
    input logic rst,
    input logic en,
    input logic [31:0] pc_in,
    output logic [31:0] pc_out
    );
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 32'h00000000; 
        end else if(!en) begin
            pc_out <= pc_in;       
        end
    end
endmodule

module instr_mem(
    input logic [31:0] pc,
    output logic [31:0] instr
);
    logic [7:0] memory [0:127];
    integer addr;

    task automatic load_inst(input int a, input logic [31:0] inst);
        begin
            memory[a]   = inst[7:0];
            memory[a+1] = inst[15:8];
            memory[a+2] = inst[23:16];
            memory[a+3] = inst[31:24];
        end
    endtask

    initial begin
        addr = 0;
        
        // 1. Initialize registers to have some activity
        load_inst(addr, 32'h00300313); addr = addr + 4; // 0x00: li t1(x6), 3
        load_inst(addr, 32'h00400393); addr = addr + 4; // 0x04: li t2(x7), 4

        // --- THE BACKWARDS LOOP ---
        
        // LOOP_START: (Address 0x08)
        load_inst(addr, 32'h007302b3); addr = addr + 4; // 0x08: add t0(x5),  t1(x6), t2(x7)
        load_inst(addr, 32'h00730e33); addr = addr + 4; // 0x0C: add t3(x28), t1(x6), t2(x7)
        
        // BRANCH BACK: (Address 0x10)
        // beq x0, x0, -8  -> (Jump back to 0x08). Since 0 == 0, this is ALWAYS taken.
        load_inst(addr, 32'hFE000CE3); addr = addr + 4; // 0x10: beq x0, x0, -8

        // Instructions below the branch (Wrong path!)
        // The predictor should learn to skip these completely.
        load_inst(addr, 32'h00000000); addr = addr + 4; // 0x14: nop (Wrong Path)
        load_inst(addr, 32'h00000000); addr = addr + 4; // 0x18: nop (Wrong Path)
    end

    assign instr = { memory[pc+3], memory[pc+2], memory[pc+1], memory[pc]};
endmodule

module imm_gen(
    input logic [31:0] instr,
    output logic [31:0] imm_out);
    
    localparam S_TYPE = 7'b0100011; //sw
    localparam L_TYPE = 7'b0000011; //lw 
    localparam I_TYPE = 7'b0010011; //immediate
    localparam B_TYPE = 7'b1100011; //beq
    localparam J_TYPE = 7'b1101111; //jal

    logic [6:0] opcode;
    assign opcode = instr[6:0];

    always_comb begin
        case(opcode)
            L_TYPE: imm_out = {{20{instr[31]}}, instr[31:20]};
            I_TYPE: imm_out = {{20{instr[31]}}, instr[31:20]};
            S_TYPE:imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            B_TYPE: imm_out = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            J_TYPE: imm_out = {{12{instr[31]}},  instr[19:12], instr[20], instr[30:21], 1'b0};
            default: imm_out = 32'b0;
        endcase
    end
endmodule

module reg_file(
    input logic clk, rst,
    input logic [4:0] rs1, rs2, rd,          
    input logic [31:0] write_data, 
    input logic reg_write,
    output logic [31:0] read_data1, read_data2
);
    logic [31:0] reg_file [31:0];

    assign read_data1 = (rs1 == 5'b0)   ? 32'b0 :
                        (reg_write && rs1 == rd) ? write_data :  // forward write?read
                        reg_file[rs1];
    
    assign read_data2 = (rs2 == 5'b0)   ? 32'b0 :
                        (reg_write && rs2 == rd) ? write_data :  // forward write?read  
                        reg_file[rs2];
    
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                reg_file[i] <= 0; 
            end 
        end
        else if (reg_write && (rd != 5'b0)) begin
            reg_file[rd] <= write_data;
        end 
    end
endmodule

module alu(
    input logic [31:0] in1, in2,
    input logic [2:0] alu_control,
    output logic [31:0] result,
    output logic zero_flag
);
    always_comb begin
        result = 32'b0;
        case(alu_control)
            3'b000: result = in1 + in2;
            3'b001: result = in1 - in2;
            3'b011: result = in1 | in2;
            3'b010: result = in1 & in2;
            3'b101: result = ($signed(in1) < $signed(in2)) ? 32'b1 : 32'b0;
            default: result = 32'b0;
        endcase
        zero_flag = (result == 32'b0) ? 1'b1 : 1'b0;
    end
endmodule

module data_mem(
    input logic clk, mem_read, mem_write,
    input logic [31:0] address, data_in,
    output logic [31:0] data_out
);
    logic [7:0] memory [1023:0];

    always_ff @(posedge clk) begin
        if (mem_write) begin
            memory[address]   <= data_in[7:0];
            memory[address+1] <= data_in[15:8];
            memory[address+2] <= data_in[23:16];
            memory[address+3] <= data_in[31:24];
        end
    end
    assign data_out = mem_read ? {memory[address+3], memory[address+2], memory[address+1], memory[address]} : 32'b0;
endmodule

module adder4(
    input logic [31:0]a,
    input logic [31:0]b,
    output logic [31:0]sum
);
    assign sum = a + b;
endmodule

module mux2x1(
    input logic [31:0] a, b,
    input logic control,
    output logic [31:0] out
);
    assign out = control ? b : a;
endmodule

module mux3x1(
    input logic [31:0] a, b, c,
    input logic [1:0]  control,
    output logic [31:0] out
);
    always_comb begin
        case (control)
            2'b00: out = a;
            2'b01: out = b;
            2'b10: out = c;
            default: out = 32'b0;
        endcase
    end
endmodule

module main_decoder(
    input logic  [6:0] Op,
    output logic       Branch,
    output logic       Jump,
    output logic       RegWrite,
    output logic       ALUSrc,
    output logic [1:0] ALUOp,
    output logic       MemWrite,
    output logic       MemRead,
    output logic [1:0] ResultSrc
);
    always_comb begin
        case(Op)
            7'b0010011: begin // I-type
                RegWrite  = 1'b1;   ALUSrc    = 1'b1;
                MemWrite  = 1'b0;   ResultSrc = 2'b00;
                Branch    = 1'b0;   ALUOp     = 2'b10;  
                Jump      = 1'b0;   MemRead   = 1'b0; 
            end
            7'b0000011: begin // L-type: lw
                RegWrite  = 1'b1;   ALUSrc    = 1'b1;
                MemWrite  = 1'b0;   ResultSrc = 2'b01;
                Branch    = 1'b0;   ALUOp     = 2'b00;  
                Jump      = 1'b0;   MemRead   = 1'b1; 
            end
            7'b0100011: begin // S-type: sw
                RegWrite  = 1'b0;   ALUSrc    = 1'b1;
                MemWrite  = 1'b1;   ResultSrc = 2'bxx;
                Branch    = 1'b0;   ALUOp     = 2'b00;  
                Jump      = 1'b0;   MemRead   = 1'b0; 
            end
            7'b0110011: begin // R-type
                RegWrite  = 1'b1;   ALUSrc    = 1'b0;
                MemWrite  = 1'b0;   ResultSrc = 2'b00;
                Branch    = 1'b0;   ALUOp     = 2'b10;  
                Jump      = 1'b0;   MemRead   = 1'b0; 
            end
            7'b1100011: begin // B-type: beq
                RegWrite  = 1'b0;   ALUSrc    = 1'b0;
                MemWrite  = 1'b0;   ResultSrc = 2'bxx;
                Branch    = 1'b1;   ALUOp     = 2'b01;  
                Jump      = 1'b0;   MemRead   = 1'b0; 
            end
            7'b1101111: begin // J-type: jal
                RegWrite  = 1'b1;   ALUSrc    = 1'bx;
                MemWrite  = 1'b0;   ResultSrc = 2'b10;
                Branch    = 1'b0;   ALUOp     = 2'bxx;  
                Jump      = 1'b1;   MemRead   = 1'b0; 
            end
            default: begin
                RegWrite  = 1'b0;   ALUSrc    = 1'b0;
                MemWrite  = 1'b0;   ResultSrc = 2'b00;
                Branch    = 1'b0;   ALUOp     = 2'b00;  
                Jump      = 1'b0;   MemRead   = 1'b0; 
            end
        endcase
    end
endmodule

module alu_decoder (
    input  logic [1:0] alu_op,
    input  logic [2:0] funct3,
    input  logic       op5,
    input  logic       funct7_5,
    output logic [2:0] alu_control
);
    always_comb begin
        case (alu_op)
            2'b00: alu_control = 3'b000; 
            2'b01: alu_control = 3'b001; 
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        if (op5 && funct7_5) alu_control = 3'b001;
                        else                 alu_control = 3'b000; 
                    end
                    3'b010:  alu_control = 3'b101; 
                    3'b110:  alu_control = 3'b011; 
                    3'b111:  alu_control = 3'b010;
                    default: alu_control = 3'b000; 
                endcase
            end
            default: alu_control = 3'b000;
        endcase
    end
endmodule

module hazard_unit(
    // data hazard : forwarding
    input logic [4:0]rs1_E,
    input logic [4:0]rs2_E,
    input logic [4:0]rd_M,
    input logic [4:0]rd_W,
    input logic      RegWriteM,
    input logic      RegWriteW,
    output logic[1:0]ForwardAE,
    output logic[1:0]ForwardBE,
    
    // data hazard : lw stalling and flushing
    input logic [4:0]rs1_D,
    input logic [4:0]rs2_D,
    input logic [4:0]rd_E,
    input logic      ResultSrcE,
    output logic     StallF,
    output logic     StallD,
    output logic     FlushE,
    
    // control hazard: MISPREDICTION FLUSHING (Changed from PCSrcE)
    input logic      mispredict_E,
    output logic     FlushD
);
    logic lwStall;
    
    always_comb begin
        if((rs1_E == rd_M) && RegWriteM && rs1_E !=5'b0) begin
            ForwardAE = 2'b10;
        end else if ((rs1_E == rd_W) && RegWriteW && rs1_E !=0) begin
            ForwardAE = 2'b01;
        end else begin
            ForwardAE = 2'b00;
        end  
    end
    
    always_comb begin
        if((rs2_E == rd_M) && RegWriteM && rs2_E !=5'b0) begin
            ForwardBE = 2'b10;
        end else if ((rs2_E == rd_W) && RegWriteW && rs2_E !=0) begin
            ForwardBE = 2'b01;
        end else begin
            ForwardBE = 2'b00;
        end  
    end

    assign lwStall = (rs1_D == rd_E || rs2_D == rd_E) && ResultSrcE && (rd_E != 5'b0);
    
    always_comb begin 
        if(lwStall) begin 
            StallF = 1'b1;
            StallD = 1'b1; 
        end else begin
            StallF = 1'b0;
            StallD = 1'b0; 
        end  
        
        FlushD = mispredict_E; 
        FlushE = lwStall || mispredict_E;
    end
endmodule

module control_unit(
    input  logic        clk,
    input  logic        rst,
    
    input  logic        zeroE,
    input  logic [6:0]  opcodeD,
    input  logic [2:0]  funct3D,
    input  logic        funct7_5D,
     
    input logic [4:0]   rs1_D,
    input logic [4:0]   rs2_D,
    input logic [4:0]   rs1_E,
    input logic [4:0]   rs2_E,
    input logic [4:0]   rd_E,
    input logic [4:0]   rd_M,
    input logic [4:0]   rd_W,
    input logic         mispredict_E, // Received from datapath

    output logic        BranchE,      // Passed to datapath for Gshare
    output logic        JumpE,        // Passed to datapath for Gshare
    output logic        PCSrcE,
    output logic        RegWriteW,
    output logic        ALUSrcE,
    output logic [2:0]  ALUcontrolE,
    output logic        MemWriteM,
    output logic        MemReadM,
    output logic [1:0]  ResultSrcW,
    
    output logic[1:0] ForwardAE,
    output logic[1:0] ForwardBE,
    output logic      StallF,
    output logic      StallD,
    output logic      FlushE,
    output logic      FlushD
);
    
    logic [1:0]ALUop;
    
    logic BranchD, JumpD, RegWriteD, ALUSrcD, MemWriteD, MemReadD;
    logic [2:0] ALUcontrolD;
    logic [1:0] ResultSrcD;

    logic RegWriteE, MemWriteE, MemReadE;
    logic [1:0] ResultSrcE;
    
    logic RegWriteM;
    logic [1:0] ResultSrcM;

     main_decoder main_decoder_inst (
         .Op(opcodeD),
         .Branch(BranchD),
         .Jump(JumpD),
         .RegWrite(RegWriteD),
         .ALUSrc(ALUSrcD),
         .ALUOp(ALUop),
         .MemWrite(MemWriteD),
         .MemRead(MemReadD),
         .ResultSrc(ResultSrcD)
     );
     
     alu_decoder alu_decoder_inst (
         .alu_op(ALUop),
         .funct3(funct3D),
         .op5(opcodeD[5]),
         .funct7_5(funct7_5D),
         .alu_control(ALUcontrolD)
     );

    hazard_unit hazard_unit_inst(
         .rs1_E(rs1_E),
         .rs2_E(rs2_E),
         .rd_M(rd_M),
         .rd_W(rd_W),
         .RegWriteM(RegWriteM),
         .RegWriteW(RegWriteW),
         .ForwardAE(ForwardAE),
         .ForwardBE(ForwardBE),
         .rs1_D(rs1_D),
         .rs2_D(rs2_D),
         .rd_E(rd_E),
         .ResultSrcE(ResultSrcE == 2'b01),
         .StallF(StallF),
         .StallD(StallD),
         .FlushE(FlushE),
         .mispredict_E(mispredict_E), // Link misprediction to flush logic
         .FlushD(FlushD)
    );

    always_ff @(posedge clk) begin
        if (rst || FlushE) begin
            BranchE     <= 1'b0;
            JumpE       <= 1'b0;
            RegWriteE   <= 1'b0;
            ALUSrcE     <= 1'b0;
            MemWriteE   <= 1'b0;
            MemReadE    <= 1'b0;
            ALUcontrolE <= 3'b0;
            ResultSrcE  <= 2'b0;
        end else begin
            BranchE     <= BranchD;
            JumpE       <= JumpD;
            RegWriteE   <= RegWriteD;
            ALUSrcE     <= ALUSrcD;
            MemWriteE   <= MemWriteD;
            MemReadE    <= MemReadD;
            ALUcontrolE <= ALUcontrolD;
            ResultSrcE  <= ResultSrcD; 
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            RegWriteM   <= 1'b0;
            MemWriteM   <= 1'b0;
            MemReadM    <= 1'b0;
            ResultSrcM  <= 2'b0;
            
            RegWriteW   <= 1'b0;
            ResultSrcW  <= 2'b0;
        end else begin 
            RegWriteM   <= RegWriteE;
            MemWriteM   <= MemWriteE;
            MemReadM    <= MemReadE;
            ResultSrcM  <= ResultSrcE;
            
            RegWriteW   <= RegWriteM;
            ResultSrcW  <= ResultSrcM;
        end
    end
 
    assign PCSrcE = JumpE | (BranchE & zeroE);
   
endmodule

module data_path (
    input logic       clk, 
    input logic       rst, 
    
    input logic       PCSrcE,
    input logic       BranchE,
    input logic       JumpE,
    input logic       RegWriteW,
    input logic       ALUSrcE,
    input logic [2:0] ALUcontrolE,
    input logic       MemWriteM,
    input logic       MemReadM,
    input logic [1:0] ResultSrcW,
    
    input logic[1:0]  ForwardAE,
    input logic[1:0]  ForwardBE,
    input logic       StallF,
    input logic       StallD,
    input logic       FlushE,
    input logic       FlushD,

    output logic      mispredict_E,
    output logic      zeroE,
    output logic [6:0]opcodeD,
    output logic [2:0]funct3D,
    output logic      funct7_5D,
    
    output logic [4:0]rs1_D,
    output logic [4:0]rs2_D,
    output logic [4:0]rs1_E,
    output logic [4:0]rs2_E,
    output logic [4:0]rd_E,
    output logic [4:0]rd_M,
    output logic [4:0]rd_W
);

    logic [31:0] pc_inF;
    logic [31:0] pc_outF;
    logic [31:0] instrF;
    logic [31:0] PCPlus4F;

    logic [31:0] instrD;
    logic [31:0] pc_outD;
    logic [31:0] PCPlus4D;

    logic [31:0] SrcA_D;
    logic [31:0] WriteDataD;
    logic [31:0] ImmediateD;
    logic [4:0] rd_D;
    
    logic [31:0] SrcA_Pre_E;   
    logic [31:0] SrcA_E;
    logic [31:0] WriteData_Pre_E;
    logic [31:0] WriteDataE;
    logic [31:0] pc_outE;
    logic [31:0] ImmediateE;
    logic [31:0] PCPlus4E;
    
    logic [31:0] PCTargetE;
    logic [31:0] SrcB_E;
    logic [31:0] ALUResultE;
    
    logic [31:0] ALUResultM;
    logic [31:0] WriteDataM;
    logic [31:0] PCPlus4M;
    logic [31:0] ReadDataM;

    logic [31:0] ALUResultW;
    logic [31:0] ReadDataW;
    logic [31:0] PCPlus4W;
    logic [31:0] ResultW;
    
    logic [7:0]  hash_F, hash_D, hash_E;
    logic        predict_taken_F, predict_taken_D, predict_taken_E;
    logic [31:0] predict_target_F, predict_target_D, predict_target_E;
    logic        actual_taken_E;

    gshare_predictor #(.GHR_BITS(8)) bp (
        .clk(clk),
        .rst(rst),
        .pc_F(pc_outF),
        .hash_F(hash_F),
        .predict_taken_F(predict_taken_F),
        .predict_target_F(predict_target_F),
        .BranchE(BranchE),
        .JumpE(JumpE),
        .pc_E(pc_outE),
        .hash_E(hash_E),
        .actual_taken_E(actual_taken_E),
        .actual_target_E(PCTargetE)
    );

    assign actual_taken_E = PCSrcE; // From control unit (JumpE | (BranchE & zeroE))
    
    assign mispredict_E = (BranchE || JumpE) ?
                          ((actual_taken_E != predict_taken_E) || (actual_taken_E && (PCTargetE != predict_target_E))) :
                          (predict_taken_E);

    always_comb begin
        if (mispredict_E) begin
            pc_inF = actual_taken_E ? PCTargetE : PCPlus4E;
        end else if (predict_taken_F) begin
            pc_inF = predict_target_F;
        end else begin
            pc_inF = PCPlus4F;
        end
    end

    pc pc_inst (.clk(clk),.rst(rst), .en(StallF),.pc_in(pc_inF),.pc_out(pc_outF));
    instr_mem instr_mem_inst (.pc(pc_outF),.instr(instrF));
    adder4 PC_Adder4 ( .a(pc_outF),.b(32'd4), .sum(PCPlus4F));

    assign rd_D = instrD[11:7];
    assign rs1_D = instrD[19:15];
    assign rs2_D = instrD[24:20];

    reg_file reg_file_inst (.clk(clk), .rst(rst), .rs1(rs1_D),
        .rs2(rs2_D), .rd(rd_W),.write_data(ResultW),
        .reg_write(RegWriteW),.read_data1(SrcA_D),.read_data2(WriteDataD) );
    imm_gen imm_gen_inst(.instr(instrD), .imm_out(ImmediateD));
    
    assign opcodeD = instrD[6:0];
    assign funct3D = instrD[14:12];
    assign funct7_5D = instrD[30];
 
    mux3x1 ALU_SrcA_Mux (.a(SrcA_Pre_E), .b(ResultW), .c(ALUResultM),
        .control(ForwardAE),.out(SrcA_E));
    mux3x1 ALU_SrcB_Pre_Mux (.a(WriteData_Pre_E), .b(ResultW), .c(ALUResultM),
        .control(ForwardBE),.out(WriteDataE)); 
    mux2x1 ALU_SrcB_Mux (.a(WriteDataE),.b(ImmediateE), .control(ALUSrcE),.out(SrcB_E));
    
    alu alu_inst (.in1(SrcA_E),.in2(SrcB_E), .alu_control(ALUcontrolE), 
        .result(ALUResultE),.zero_flag(zeroE));
    adder4 PC_Adder_Target (.a(pc_outE),.b(ImmediateE),.sum(PCTargetE));

    data_mem data_mem_ist (.clk(clk),.mem_read(MemReadM),.mem_write(MemWriteM), 
        .address(ALUResultM), .data_in(WriteDataM), .data_out(ReadDataM));

    mux3x1 Writeback_Mux (.a(ALUResultW), .b(ReadDataW), .c(PCPlus4W),
        .control(ResultSrcW),.out(ResultW));
    
    // Register Fetch to Decode
    always_ff @(posedge clk) begin
        if (rst || FlushD) begin
            instrD     <= 32'b0;
            pc_outD    <= 32'b0;
            PCPlus4D   <= 32'b0;
            // Clear predictions on flush
            predict_taken_D  <= 1'b0;
            predict_target_D <= 32'b0;
            hash_D           <= 8'b0;
        end else if(!StallD) begin
            instrD     <= instrF;
            pc_outD    <= pc_outF;
            PCPlus4D   <= PCPlus4F;
            // Pass predictions down the pipeline
            predict_taken_D  <= predict_taken_F;
            predict_target_D <= predict_target_F;
            hash_D           <= hash_F;
        end
    end
    
    // Register Decode to Execute  
    always_ff @(posedge clk) begin
        if (rst || FlushE) begin
            SrcA_Pre_E      <= 32'b0;
            WriteData_Pre_E <= 32'b0;
            pc_outE    <= 32'b0;
            rd_E       <= 5'b0;
            rs1_E      <= 5'b0;
            rs2_E      <= 5'b0;
            ImmediateE <= 32'b0;
            PCPlus4E   <= 32'b0;
            // Clear predictions on flush
            predict_taken_E  <= 1'b0;
            predict_target_E <= 32'b0;
            hash_E           <= 8'b0;
        end else begin     
            SrcA_Pre_E      <= SrcA_D;
            WriteData_Pre_E <= WriteDataD;
            pc_outE    <= pc_outD;
            rd_E       <= rd_D;
            rs1_E      <= rs1_D;
            rs2_E      <= rs2_D;
            ImmediateE <= ImmediateD;
            PCPlus4E   <= PCPlus4D;
            // Pass predictions down the pipeline
            predict_taken_E  <= predict_taken_D;
            predict_target_E <= predict_target_D;
            hash_E           <= hash_D;
        end
    end
        
    always_ff @(posedge clk) begin
        if (rst) begin
            ALUResultM <= 32'b0;
            WriteDataM <= 32'b0;
            rd_M    <= 5'b0;
            PCPlus4M   <= 32'b0;
            
            ALUResultW <= 32'b0;
            ReadDataW  <= 32'b0;
            rd_W    <= 5'b0;
            PCPlus4W   <= 32'b0;
        end else begin
            ALUResultM <= ALUResultE;
            WriteDataM <= WriteDataE;
            rd_M    <= rd_E;
            PCPlus4M   <= PCPlus4E;
            
            ALUResultW <= ALUResultM;
            ReadDataW  <= ReadDataM;
            rd_W    <= rd_M;
            PCPlus4W   <= PCPlus4M;
        end
    end
endmodule

module RISCV_Pipelined(
    input logic clk,
    input logic rst
);

    logic       PCSrcE;
    logic       BranchE;
    logic       JumpE;
    logic       RegWriteW;
    logic       ALUSrcE;
    logic [2:0] ALUcontrolE;
    logic       MemWriteM;
    logic       MemReadM;
    logic [1:0] ResultSrcW;

    logic zeroE;
    logic [6:0]opcodeD;
    logic [2:0]funct3D;
    logic funct7_5D;

    logic [4:0]   rs1_D;
    logic [4:0]   rs2_D;
    logic [4:0]   rs1_E;
    logic [4:0]   rs2_E;
    logic [4:0]   rd_E;
    logic [4:0]   rd_M;
    logic [4:0]   rd_W;

    logic[1:0]ForwardAE;
    logic[1:0]ForwardBE;
    logic     StallF;
    logic     StallD;
    logic     FlushE;
    logic     FlushD;
    logic     mispredict_E;
    
    control_unit control_unit_inst( .clk(clk), .rst(rst), .zeroE(zeroE), .opcodeD(opcodeD), .funct3D(funct3D),
        .rs1_D(rs1_D), .rs2_D(rs2_D), .rs1_E(rs1_E), .rs2_E(rs2_E), .rd_E(rd_E), .rd_M(rd_M), .rd_W(rd_W), 
        .funct7_5D(funct7_5D), .PCSrcE(PCSrcE), .BranchE(BranchE), .JumpE(JumpE), .mispredict_E(mispredict_E), 
        .RegWriteW(RegWriteW), .ALUSrcE(ALUSrcE), .ALUcontrolE(ALUcontrolE), 
        .MemWriteM(MemWriteM), .MemReadM(MemReadM), .ResultSrcW(ResultSrcW), .ForwardAE(ForwardAE), 
        .ForwardBE(ForwardBE), .StallF(StallF), .StallD(StallD), .FlushE(FlushE), .FlushD(FlushD));

    data_path data_path_inst ( .clk(clk), .rst(rst), .PCSrcE(PCSrcE), .BranchE(BranchE), .JumpE(JumpE), 
        .RegWriteW(RegWriteW), .ALUSrcE(ALUSrcE), .mispredict_E(mispredict_E),
        .ALUcontrolE(ALUcontrolE), .MemWriteM(MemWriteM), .MemReadM(MemReadM), .ResultSrcW(ResultSrcW), 
         .ForwardAE(ForwardAE), .ForwardBE(ForwardBE), .StallF(StallF), .StallD(StallD), .FlushE(FlushE),
         .FlushD(FlushD), .zeroE(zeroE), .opcodeD(opcodeD), .funct3D(funct3D), .funct7_5D(funct7_5D), 
         .rs1_D(rs1_D), .rs2_D(rs2_D), .rs1_E(rs1_E), .rs2_E(rs2_E), .rd_E(rd_E), .rd_M(rd_M), .rd_W(rd_W));

endmodule