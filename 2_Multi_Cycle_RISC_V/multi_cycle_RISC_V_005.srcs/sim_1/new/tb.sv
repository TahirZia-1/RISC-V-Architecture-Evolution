
//`timescale 1ns / 1ps

//module tb_top;

//    reg clk;
//    reg rst;
    
//    wire [31:0] pc;
//    wire [31:0] insn;
//    wire [31:0] mem_adr;
//    wire [31:0] mem_wd;
//    wire        mem_we;
//    wire [31:0] mem_rd;

//    top uut (
//        .clk(clk), 
//        .rst(rst), 
//        .pc(pc), 
//        .insn(insn),
//        .mem_adr(mem_adr),
//        .mem_wd(mem_wd),
//        .mem_we(mem_we),
//        .mem_rd(mem_rd)
//    );

//    always begin
//        #5 clk = ~clk;
//    end

//    initial begin
      
//      	//$dumpfile("dump.vcd"); $dumpvars;
//        clk = 0;
//        rst = 1; 


//      $monitor("Time: %0t | PC: %h | INSN: %h | Adr: %2d | WD: %h | RD: %h | x1: %h | x2: %h | x3: %h | Memory[4]: %h | Memory[100]: %h", 
//                  $time, pc, insn, mem_adr, mem_wd, mem_rd,
//                 uut.reg_f.reg_memory[1],
//                 uut.reg_f.reg_memory[2],   
//                 uut.reg_f.reg_memory[3],
//                 {uut.inst.Memory[7], uut.inst.Memory[6], uut.inst.Memory[5], uut.inst.Memory[4]},
//                 {uut.inst.Memory[103], uut.inst.Memory[102], uut.inst.Memory[101], uut.inst.Memory[100]});  

//        #12;
//        rst = 0; 

//        // Increased from 100ns to 1000ns to give the FSM enough time to loop!
//        #1000;

//        $finish;
//    end

//endmodule

`timescale 1ns / 1ps

module tb_top;

    reg clk;
    reg rst;
    
    wire [31:0] pc;
    wire [31:0] insn;
    wire [31:0] mem_adr;
    wire [31:0] mem_wd;
    wire        mem_we;
    wire [31:0] mem_rd;


    wire [31:0] debug_x1       = uut.reg_f.reg_memory[1];
    wire [31:0] debug_x2       = uut.reg_f.reg_memory[2];
    wire [31:0] debug_x3       = uut.reg_f.reg_memory[3];
    wire [31:0] debug_x4       = uut.reg_f.reg_memory[4];
    wire [31:0] debug_mem100   = {uut.inst.Memory[103], uut.inst.Memory[102], uut.inst.Memory[101], uut.inst.Memory[100]};
    wire [31:0] debug_old_pc   = uut.pcold.old_pc_out;

    top uut (
        .clk(clk), 
        .rst(rst), 
        .pc(pc), 
        .insn(insn),
        .mem_adr(mem_adr),
        .mem_wd(mem_wd),
        .mem_we(mem_we),
        .mem_rd(mem_rd)
    );


    always begin
        #5 clk = ~clk;
    end


    reg [63:0] state_str;
    always @(*) begin
        case(uut.control_inst.fsm_inst.state)
            4'd0:  state_str = "FETCH";
            4'd1:  state_str = "DECODE";
            4'd2:  state_str = "MEMADR";
            4'd3:  state_str = "MEMREAD";
            4'd4:  state_str = "MEMWB";
            4'd5:  state_str = "MEMWRITE";
            4'd6:  state_str = "EXECUTER";
            4'd7:  state_str = "ALUWB";
            4'd8:  state_str = "EXECUTEI";
            4'd9:  state_str = "JAL";
            4'd10: state_str = "BEQ";
            default: state_str = "UNKNOWN";
        endcase
    end


    always @(uut.control_inst.fsm_inst.state) begin
        if (uut.control_inst.fsm_inst.state == 4'd0 && $time > 0) begin
            $display("\n==========================================================================================================================");
            $display(">>> STARTING NEW INSTRUCTION FETCH");
            $display("==========================================================================================================================");
        end
    end


    initial begin
        // Set clean Nanosecond formatting
        $timeformat(-9, 0, " ns", 5);
        
        clk = 0;
        rst = 1; 

        $monitor("Time: %0t | STATE: %8s | PC: %h | INSN: %h | Adr: %3d | WD: %h | RD: %h | x1: %h | x2: %h | x3: %h | x4: %h | Mem[100]: %h | Old_PC: %h", 
                  $time, 
                  state_str, 
                  pc, 
                  insn, 
                  mem_adr, 
                  mem_wd, 
                  mem_rd,
                  uut.reg_f.reg_memory[1],
                  uut.reg_f.reg_memory[2],   
                  uut.reg_f.reg_memory[3],
                  uut.reg_f.reg_memory[4],
                  {uut.inst.Memory[103], uut.inst.Memory[102], uut.inst.Memory[101], uut.inst.Memory[100]},
                  uut.pcold.old_pc_out);  

        #12; 
        rst = 0; 

        // Give the multicycle processor plenty of time to loop
        #350;
        $finish;
    end

endmodule