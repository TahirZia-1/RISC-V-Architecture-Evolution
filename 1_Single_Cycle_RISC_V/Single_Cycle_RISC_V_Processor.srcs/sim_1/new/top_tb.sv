`timescale 1ns / 1ps

module tb_top;

    reg clk;
    reg rst;
    
    wire [31:0] pc;
    wire [31:0] insn;

    top uut (.clk(clk), .rst(rst), .pc(pc), .insn(insn));

    // Clock Generation (10ns period)
    always begin
        #5 clk = ~clk;
    end

    initial begin
        // 1. Initialize
        clk = 0;
        rst = 1; 

        // 2. Pre-load Data Memory
        uut.data_m.memory[0] = 8'h2A; // LSB (Decimal 42)
        uut.data_m.memory[1] = 8'h00;
        uut.data_m.memory[2] = 8'h00;
        uut.data_m.memory[3] = 8'h00; // MSB

        // 3. The Upgraded X-Ray Monitor
        // Peeking inside the register file (reg_f) and data memory (data_m)
        $monitor("Time: %0t | PC: %3d | INSN: %h | ALU_Out: %3d | RegW: %b | x1: %h | x2: %h | x3: %h | Mem[0]: %h", 
                  $time, 
                  pc, 
                  insn, 
                  uut.ALU_result_wire, 
                  uut.reg_write_to_reg_file, 
                  uut.reg_f.reg_memory[1],  // Peek at register x1
                  uut.reg_f.reg_memory[2],
                  uut.reg_f.reg_memory[3],// Peek at register x2
                  // Stitch together the 4 bytes at Address 0 into a single 32-bit word
                  {uut.data_m.memory[3], uut.data_m.memory[2], uut.data_m.memory[1], uut.data_m.memory[0]}
        );

        // 4. Drop Reset safely BEFORE the clock edge (Fixes race conditions!)
        #12;
        rst = 0; 

        // 5. Run simulation (Increased to 200ns to allow a few instructions to finish)
        #200;

        $finish;
    end

endmodule