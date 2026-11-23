`timescale 1ns/1ns

////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_mips_cpu
// Module Under Test: mips_cpu (rtl/mips_cpu.v)
// Description: Comprehensive testbench for Single-Cycle 32-bit MIPS Processor.
//              - Executes test program(s) cycle-by-cycle.
//              - Monitors PC, instruction, control signals, ALU, and memory.
//              - Automatically checks register file and data memory values.
//              - Dumps simulation waveforms to tb_mips_cpu.vcd.
////////////////////////////////////////////////////////////////////////////////

module tb_mips_cpu;

    // Clock and Reset Signals
    reg clk;
    reg reset;

    // Instantiate Top-Level CPU
    mips_cpu dut (
        .clk   (clk),
        .reset (reset)
    );

    // Test tracking variables
    integer cycle;
    integer errors;
    integer pass_count;
    integer i;

    // 100MHz clock generation (10ns period)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Helper task to check a register's value
    task check_reg;
        input [4:0]    reg_idx;
        input [31:0]   expected_val;
        input [8*24:1] reg_name;
        begin
            if (dut.u_regfile.regs[reg_idx] === expected_val) begin
                $display("  [PASS REG] %-12s ($%0d) = %h (%0d)",
                         reg_name, reg_idx, dut.u_regfile.regs[reg_idx], $signed(dut.u_regfile.regs[reg_idx]));
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL REG] %-12s ($%0d) = %h (%0d) | Expected: %h (%0d)",
                         reg_name, reg_idx,
                         dut.u_regfile.regs[reg_idx], $signed(dut.u_regfile.regs[reg_idx]),
                         expected_val, $signed(expected_val));
                errors = errors + 1;
            end
        end
    endtask

    // Helper task to check a data memory word's value
    task check_mem;
        input [31:0]   word_idx;
        input [31:0]   expected_val;
        input [8*24:1] mem_name;
        begin
            if (dut.u_dmem.mem[word_idx] === expected_val) begin
                $display("  [PASS MEM] %-12s [idx %0d, byte_addr 0x%0x] = %h (%0d)",
                         mem_name, word_idx, word_idx * 4, dut.u_dmem.mem[word_idx], $signed(dut.u_dmem.mem[word_idx]));
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL MEM] %-12s [idx %0d, byte_addr 0x%0x] = %h (%0d) | Expected: %h (%0d)",
                         mem_name, word_idx, word_idx * 4,
                         dut.u_dmem.mem[word_idx], $signed(dut.u_dmem.mem[word_idx]),
                         expected_val, $signed(expected_val));
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        // Waveform generation for GTKWave
        $dumpfile("tb_mips_cpu.vcd");
        $dumpvars(0, tb_mips_cpu);

        errors     = 0;
        pass_count = 0;

        $display("================================================================================");
        $display("                   MIPS CPU VERIFICATION TESTBENCH (tb_mips_cpu)                ");
        $display("================================================================================");

        // =====================================================================
        // PART 1: Baseline Program Verification (programs/test.hex)
        // Instructions:
        //   0: addi $t0, $0, 5    (0x20080005) -> $8  = 5
        //   1: addi $t1, $0, 7    (0x20090007) -> $9  = 7
        //   2: add  $t2, $t0, $t1 (0x01095020) -> $10 = 12
        //   3: sw   $t2, 0($0)    (0xAC0A0000) -> mem[0] = 12
        //   4: lw   $t3, 0($0)    (0x8C0B0000) -> $11 = 12
        // =====================================================================
        $display("\n================================================================================");
        $display("   PART 1: RUNNING BASELINE TEST PROGRAM (programs/test.hex)                    ");
        $display("================================================================================");

        // Synchronous Reset Sequence
        reset = 1'b1;
        @(posedge clk);
        #1;
        if (dut.pc_out !== 32'd0) begin
            $display("[FAIL] CPU reset failed: PC = %h (expected 00000000)", dut.pc_out);
            errors = errors + 1;
        end else begin
            $display("[INFO] CPU Reset asserted. PC = 0x%08h", dut.pc_out);
        end

        // Deassert reset on negedge for clean synchronous setup
        @(negedge clk);
        reset = 1'b0;

        // Run baseline program for 5 instruction cycles + 1 writeback cycle
        for (cycle = 0; cycle < 5; cycle = cycle + 1) begin
            #1;
            $display("Cycle %0d: PC=0x%08h | Instr=0x%08h | opcode=0x%02h, funct=0x%02h",
                     cycle, dut.pc_out, dut.instr, dut.opcode, dut.funct);
            $display("         ALU: A=%0d, B=%0d, ctrl=%b -> Res=%0d (zero=%b) | RegWrite=%b, MemWrite=%b",
                     $signed(dut.src_a), $signed(dut.src_b), dut.alu_ctrl,
                     $signed(dut.alu_result), dut.zero, dut.reg_write, dut.mem_write);
            @(posedge clk);
        end

        // Wait 1 clock cycle for final instruction write-back to register file
        #1;
        @(posedge clk);
        #1;

        $display("\n--- [Part 1 Verification: Register & Memory Values] ---");
        check_reg(5'd8,  32'd5,  "$t0");
        check_reg(5'd9,  32'd7,  "$t1");
        check_reg(5'd10, 32'd12, "$t2 (add)");
        check_mem(32'd0, 32'd12, "dmem[0] (sw)");
        check_reg(5'd11, 32'd12, "$t3 (lw)");
        check_reg(5'd0,  32'd0,  "$0 (zero reg)");

        // =====================================================================
        // PART 2: Comprehensive Instruction Set Verification (test_full.hex)
        // Tests:
        //   - ADDI with positive and negative immediates
        //   - ADD  (pos+pos, pos+neg)
        //   - SUB  (pos result, neg result)
        //   - AND  (bitwise logic)
        //   - OR   (bitwise logic)
        //   - SLT  (signed comparison: pos<pos, pos>pos, neg<pos, pos>neg)
        //   - SW   (Store Word to multiple addresses: 0, 4, 8, 12)
        //   - LW   (Load Word from multiple addresses: 0, 4, 8, 12)
        // =====================================================================
        $display("\n================================================================================");
        $display("   PART 2: RUNNING COMPREHENSIVE TEST PROGRAM (programs/test_full.hex)          ");
        $display("================================================================================");

        // Load comprehensive machine code into instruction memory
        $readmemh("programs/test_full.hex", dut.u_imem.mem);

        // Clear data memory and register file
        for (i = 0; i < 64; i = i + 1) dut.u_dmem.mem[i] = 32'b0;
        for (i = 0; i < 32; i = i + 1) dut.u_regfile.regs[i] = 32'b0;

        // Reset CPU to restart PC from 0
        reset = 1'b1;
        @(posedge clk);
        #1;
        @(negedge clk);
        reset = 1'b0;

        // Run for 21 instruction cycles
        for (cycle = 0; cycle < 21; cycle = cycle + 1) begin
            #1;
            $display("Cycle %02d: PC=0x%02h | Instr=0x%08h | ALU Res=%0d | RegWr=%b (wa3=$%0d, wd3=%0d) | MemWr=%b",
                     cycle, dut.pc_out, dut.instr, $signed(dut.alu_result),
                     dut.reg_write, dut.write_reg, $signed(dut.result_wb), dut.mem_write);
            @(posedge clk);
        end

        // Wait 1 clock cycle for final LW writeback
        #1;
        @(posedge clk);
        #1;

        $display("\n--- [Part 2 Verification: All Register & Memory Values] ---");
        // ADDI checks
        check_reg(5'd8,  32'd20,          "$t0 (addi 20)");
        check_reg(5'd9,  32'd5,           "$t1 (addi 5)");
        check_reg(5'd10, -32'd10,         "$t2 (addi -10 signed)");

        // ADD checks
        check_reg(5'd11, 32'd25,          "$t3 (add 20+5)");
        check_reg(5'd12, 32'd10,          "$t4 (add 20+(-10))");

        // SUB checks
        check_reg(5'd13, 32'd15,          "$t5 (sub 20-5)");
        check_reg(5'd14, -32'd15,         "$t6 (sub 5-20 neg)");

        // AND & OR checks
        check_reg(5'd15, 32'd4,           "$t7 (and 20&5)");
        check_reg(5'd16, 32'd21,          "$s0 (or 20|5)");

        // SLT Signed checks
        check_reg(5'd17, 32'd1,           "$s1 (slt 5<20 true)");
        check_reg(5'd18, 32'd0,           "$s2 (slt 20<5 false)");
        check_reg(5'd19, 32'd1,           "$s3 (slt -10<20 signed true)");
        check_reg(5'd20, 32'd0,           "$s4 (slt 20<-10 signed false)");

        // Data Memory SW checks
        check_mem(32'd0, 32'd25,          "dmem[0] (sw 25)");
        check_mem(32'd1, 32'd15,          "dmem[1] (sw 15)");
        check_mem(32'd2, -32'd15,         "dmem[2] (sw -15)");
        check_mem(32'd3, 32'd1,           "dmem[3] (sw 1)");

        // LW checks
        check_reg(5'd21, 32'd25,          "$s5 (lw mem[0])");
        check_reg(5'd22, 32'd15,          "$s6 (lw mem[1])");
        check_reg(5'd23, -32'd15,         "$s7 (lw mem[2])");
        check_reg(5'd24, 32'd1,           "$t8 (lw mem[3])");

        // Zero register integrity
        check_reg(5'd0,  32'd0,           "$0 (zero reg)");

        // =====================================================================
        // PART 3: Array Sum Benchmark (programs/array_sum.hex)
        // Array: {3, 7, 2, 9, 4} -> sum = 25
        // Verifies: Loop with BEQ (taken and not taken) and J (backward jump)
        // =====================================================================
        $display("\n================================================================================");
        $display("   PART 3: RUNNING ARRAY SUM BENCHMARK (programs/array_sum.hex)                 ");
        $display("================================================================================");

        $readmemh("programs/array_sum.hex", dut.u_imem.mem);
        for (i = 0; i < 64; i = i + 1) dut.u_dmem.mem[i] = 32'b0;
        for (i = 0; i < 32; i = i + 1) dut.u_regfile.regs[i] = 32'b0;

        reset = 1'b1;
        @(posedge clk);
        #1;
        @(negedge clk);
        reset = 1'b0;

        for (cycle = 0; cycle < 45; cycle = cycle + 1) begin
            @(posedge clk);
        end
        #1;

        $display("\n--- [Part 3 Verification: Array Sum Results] ---");
        check_reg(5'd10, 32'd25, "$t2 (sum)");
        check_mem(32'd5,  32'd25, "dmem[5] (sum)");

        // =====================================================================
        // PART 4: Maximum Search Benchmark (programs/max_search.hex)
        // Array: {3, 17, 5, 42, 8, 23} -> max = 42
        // Verifies: Loop with SLT, conditional branch, forward skip, backward jump
        // =====================================================================
        $display("\n================================================================================");
        $display("   PART 4: RUNNING MAXIMUM SEARCH BENCHMARK (programs/max_search.hex)           ");
        $display("================================================================================");

        $readmemh("programs/max_search.hex", dut.u_imem.mem);
        for (i = 0; i < 64; i = i + 1) dut.u_dmem.mem[i] = 32'b0;
        for (i = 0; i < 32; i = i + 1) dut.u_regfile.regs[i] = 32'b0;

        reset = 1'b1;
        @(posedge clk);
        #1;
        @(negedge clk);
        reset = 1'b0;

        for (cycle = 0; cycle < 55; cycle = cycle + 1) begin
            @(posedge clk);
        end
        #1;

        $display("\n--- [Part 4 Verification: Maximum Search Results] ---");
        check_reg(5'd16, 32'd42, "$s0 (max)");
        check_mem(32'd6,  32'd42, "dmem[6] (max)");

        // =====================================================================
        // PART 5: Factorial Computation Benchmark (programs/factorial.hex)
        // Computes 5! = 120 via repeated addition loop
        // Verifies: Nested loops, loop exit BEQ, loop backward J
        // =====================================================================
        $display("\n================================================================================");
        $display("   PART 5: RUNNING FACTORIAL BENCHMARK (programs/factorial.hex)                 ");
        $display("================================================================================");

        $readmemh("programs/factorial.hex", dut.u_imem.mem);
        for (i = 0; i < 64; i = i + 1) dut.u_dmem.mem[i] = 32'b0;
        for (i = 0; i < 32; i = i + 1) dut.u_regfile.regs[i] = 32'b0;

        reset = 1'b1;
        @(posedge clk);
        #1;
        @(negedge clk);
        reset = 1'b0;

        for (cycle = 0; cycle < 95; cycle = cycle + 1) begin
            @(posedge clk);
        end
        #1;

        $display("\n--- [Part 5 Verification: Factorial Results] ---");
        check_reg(5'd16, 32'd120, "$s0 (5!)");
        check_mem(32'd0,  32'd120, "dmem[0] (5!)");

        // =====================================================================
        // PART 6: Dedicated Branch & Jump Micro-Tests
        // Tests explicitly: BEQ taken, BEQ not taken, forward Jump
        // Instructions:
        //   0: addi $t0, $0, 10
        //   1: addi $t1, $0, 10
        //   2: beq  $t0, $t1, 2  (TAKEN -> skips instr 3 to instr 5)
        //   3: addi $t2, $0, 99  (SKIPPED)
        //   4: addi $t2, $0, 98  (SKIPPED)
        //   5: addi $t3, $0, 50  (EXECUTED)
        //   6: addi $t4, $0, 15  (NOT EQUAL to $t0)
        //   7: beq  $t0, $t4, 2  (NOT TAKEN -> executes instr 8)
        //   8: addi $t5, $0, 60  (EXECUTED)
        //   9: j    12           (FORWARD JUMP -> jumps to instr 12)
        //  10: addi $t6, $0, 99  (SKIPPED)
        //  11: addi $t6, $0, 98  (SKIPPED)
        //  12: addi $t7, $0, 70  (EXECUTED)
        // =====================================================================
        $display("\n================================================================================");
        $display("   PART 6: DEDICATED BRANCH & JUMP MICRO-TESTS                                  ");
        $display("================================================================================");

        for (i = 0; i < 128; i = i + 1) dut.u_imem.mem[i] = 32'b0;
        dut.u_imem.mem[0]  = 32'h2008000A; // addi $t0, $0, 10
        dut.u_imem.mem[1]  = 32'h2009000A; // addi $t1, $0, 10
        dut.u_imem.mem[2]  = 32'h11090002; // beq  $t0, $t1, 2
        dut.u_imem.mem[3]  = 32'h200A0063; // addi $t2, $0, 99 (skipped)
        dut.u_imem.mem[4]  = 32'h200A0062; // addi $t2, $0, 98 (skipped)
        dut.u_imem.mem[5]  = 32'h200B0032; // addi $t3, $0, 50
        dut.u_imem.mem[6]  = 32'h200C000F; // addi $t4, $0, 15
        dut.u_imem.mem[7]  = 32'h110C0002; // beq  $t0, $t4, 2 (not taken)
        dut.u_imem.mem[8]  = 32'h200D003C; // addi $t5, $0, 60
        dut.u_imem.mem[9]  = 32'h0800000C; // j    12 (forward jump)
        dut.u_imem.mem[10] = 32'h200E0063; // addi $t6, $0, 99 (skipped)
        dut.u_imem.mem[11] = 32'h200E0062; // addi $t6, $0, 98 (skipped)
        dut.u_imem.mem[12] = 32'h200F0046; // addi $t7, $0, 70

        for (i = 0; i < 32; i = i + 1) dut.u_regfile.regs[i] = 32'b0;

        reset = 1'b1;
        @(posedge clk);
        #1;
        @(negedge clk);
        reset = 1'b0;

        for (cycle = 0; cycle < 15; cycle = cycle + 1) begin
            @(posedge clk);
        end
        #1;

        $display("\n--- [Part 6 Verification: Micro-Test Results] ---");
        check_reg(5'd8,  32'd10, "$t0 (10)");
        check_reg(5'd9,  32'd10, "$t1 (10)");
        check_reg(5'd10, 32'd0,  "$t2 (skipped by BEQ taken)");
        check_reg(5'd11, 32'd50, "$t3 (50 after BEQ taken)");
        check_reg(5'd13, 32'd60, "$t5 (60 after BEQ not taken)");
        check_reg(5'd14, 32'd0,  "$t6 (skipped by forward J)");
        check_reg(5'd15, 32'd70, "$t7 (70 after forward J)");

        // =====================================================================
        // Final Summary
        // =====================================================================
        $display("\n================================================================================");
        if (errors == 0) begin
            $display("MIPS CPU VERIFICATION RESULT: ALL %0d CHECKS PASSED! [PASS]", pass_count);
        end else begin
            $display("MIPS CPU VERIFICATION RESULT: %0d CHECKS FAILED! [FAIL]", errors);
        end
        $display("================================================================================");

        $finish;
    end

endmodule
