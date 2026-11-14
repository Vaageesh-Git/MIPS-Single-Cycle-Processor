`timescale 1ns/1ns

////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_alu
// Module Under Test: alu (rtl/alu.v)
// Description: Exhaustive self-checking testbench for 32-bit MIPS ALU.
//              Tests every supported operation (AND, OR, ADD, SUB, SLT, Default)
//              with positive numbers, negative numbers, edge cases, and zero flags.
////////////////////////////////////////////////////////////////////////////////

module tb_alu;

    // DUT Inputs
    reg  [31:0] a;
    reg  [31:0] b;
    reg  [2:0]  alu_ctrl;

    // DUT Outputs
    wire [31:0] result;
    wire        zero;

    // Instantiate the Device Under Test (DUT)
    alu dut (
        .a        (a),
        .b        (b),
        .alu_ctrl (alu_ctrl),
        .result   (result),
        .zero     (zero)
    );

    // Test statistics
    integer test_count;
    integer pass_count;
    integer fail_count;

    // Helper task to apply stimulus and check results
    task check_alu;
        input [31:0]   in_a;
        input [31:0]   in_b;
        input [2:0]    ctrl;
        input [31:0]   exp_res;
        input          exp_zero;
        input [8*32:1] test_name;
        begin
            test_count = test_count + 1;
            a          = in_a;
            b          = in_b;
            alu_ctrl   = ctrl;
            #10; // Wait 10ns for combinational propagation

            if (result === exp_res && zero === exp_zero) begin
                $display("[PASS] Test %2d: %-28s | a=%h (%0d), b=%h (%0d), ctrl=%b -> res=%h (%0d), zero=%b",
                         test_count, test_name, a, $signed(a), b, $signed(b), ctrl, result, $signed(result), zero);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %2d: %-28s | a=%h (%0d), b=%h (%0d), ctrl=%b",
                         test_count, test_name, a, $signed(a), b, $signed(b), ctrl);
                $display("       Expected: res=%h (%0d), zero=%b | Got: res=%h (%0d), zero=%b",
                         exp_res, $signed(exp_res), exp_zero, result, $signed(result), zero);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        // Waveform generation for GTKWave
        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu);

        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        $display("================================================================================");
        $display("                      STARTING MIPS ALU VERIFICATION (tb_alu)                   ");
        $display("================================================================================");

        // ---------------------------------------------------------------------
        // 1. ADD Operation (alu_ctrl = 3'b010)
        // ---------------------------------------------------------------------
        $display("\n--- [1] Testing ADD Operation (ctrl = 3'b010) ---");
        // Positive + Positive
        check_alu(32'd15, 32'd25, 3'b010, 32'd40, 1'b0, "ADD pos + pos");
        // Positive + Negative
        check_alu(32'd50, -32'd20, 3'b010, 32'd30, 1'b0, "ADD pos + neg");
        // Negative + Positive
        check_alu(-32'd50, 32'd20, 3'b010, -32'd30, 1'b0, "ADD neg + pos");
        // Negative + Negative
        check_alu(-32'd15, -32'd25, 3'b010, -32'd40, 1'b0, "ADD neg + neg");
        // Canceling to Zero (Zero Flag Check)
        check_alu(32'd42, -32'd42, 3'b010, 32'd0, 1'b1, "ADD cancel to zero (flag)");
        // Large Numbers / Boundary Wrap-around
        check_alu(32'h7FFF_FFFF, 32'd1, 3'b010, 32'h8000_0000, 1'b0, "ADD boundary 0x7FFFFFFF+1");
        check_alu(32'hFFFF_FFFF, 32'd1, 3'b010, 32'd0, 1'b1, "ADD overflow wrap to zero");

        // ---------------------------------------------------------------------
        // 2. SUB Operation (alu_ctrl = 3'b110)
        // ---------------------------------------------------------------------
        $display("\n--- [2] Testing SUB Operation (ctrl = 3'b110) ---");
        // Positive - Positive (Positive result)
        check_alu(32'd50, 32'd20, 3'b110, 32'd30, 1'b0, "SUB pos - pos (pos res)");
        // Positive - Positive (Negative result)
        check_alu(32'd20, 32'd50, 3'b110, -32'd30, 1'b0, "SUB pos - pos (neg res)");
        // Positive - Negative (Positive result)
        check_alu(32'd25, -32'd15, 3'b110, 32'd40, 1'b0, "SUB pos - neg");
        // Negative - Positive (Negative result)
        check_alu(-32'd25, 32'd15, 3'b110, -32'd40, 1'b0, "SUB neg - pos");
        // Negative - Negative (Positive result)
        check_alu(-32'd10, -32'd30, 3'b110, 32'd20, 1'b0, "SUB neg - neg (pos res)");
        // Negative - Negative (Negative result)
        check_alu(-32'd30, -32'd10, 3'b110, -32'd20, 1'b0, "SUB neg - neg (neg res)");
        // Equal Positive (Zero Flag Check)
        check_alu(32'd100, 32'd100, 3'b110, 32'd0, 1'b1, "SUB equal pos (zero flag)");
        // Equal Negative (Zero Flag Check)
        check_alu(-32'd45, -32'd45, 3'b110, 32'd0, 1'b1, "SUB equal neg (zero flag)");

        // ---------------------------------------------------------------------
        // 3. AND Operation (alu_ctrl = 3'b000)
        // ---------------------------------------------------------------------
        $display("\n--- [3] Testing AND Operation (ctrl = 3'b000) ---");
        // Positive bitwise pattern
        check_alu(32'h0F0F_AAAA, 32'h00FF_FF00, 3'b000, 32'h000F_AA00, 1'b0, "AND bitwise pattern");
        // Positive & Negative (-1 = 0xFFFFFFFF)
        check_alu(32'd255, -32'd1, 3'b000, 32'd255, 1'b0, "AND pos & neg (-1)");
        // Negative & Negative
        check_alu(-32'd2, -32'd4, 3'b000, -32'd4, 1'b0, "AND neg & neg");
        // Disjoint masks resulting in Zero
        check_alu(32'hAAAA_AAAA, 32'h5555_5555, 3'b000, 32'd0, 1'b1, "AND disjoint (zero flag)");

        // ---------------------------------------------------------------------
        // 4. OR Operation (alu_ctrl = 3'b001)
        // ---------------------------------------------------------------------
        $display("\n--- [4] Testing OR Operation (ctrl = 3'b001) ---");
        // Positive bitwise pattern
        check_alu(32'h0000_F0F0, 32'h0000_0F0F, 3'b001, 32'h0000_FFFF, 1'b0, "OR bitwise pattern");
        // Positive | Negative
        check_alu(32'd0, -32'd1, 3'b001, -32'd1, 1'b0, "OR 0 | -1");
        // Negative | Negative
        check_alu(-32'd8, -32'd4, 3'b001, -32'd4, 1'b0, "OR neg | neg");
        // Zero | Zero (Zero Flag Check)
        check_alu(32'd0, 32'd0, 3'b001, 32'd0, 1'b1, "OR zero | zero (flag)");

        // ---------------------------------------------------------------------
        // 5. SLT Operation - Signed Comparison (alu_ctrl = 3'b111)
        // ---------------------------------------------------------------------
        $display("\n--- [5] Testing SLT Operation (ctrl = 3'b111) ---");
        // Positive < Positive (True)
        check_alu(32'd10, 32'd20, 3'b111, 32'd1, 1'b0, "SLT pos < pos (true)");
        // Positive < Positive (False)
        check_alu(32'd30, 32'd20, 3'b111, 32'd0, 1'b1, "SLT pos > pos (false)");
        // Positive == Positive (False)
        check_alu(32'd25, 32'd25, 3'b111, 32'd0, 1'b1, "SLT pos == pos (false)");
        // Negative < Positive (Must be 1 in signed arithmetic!)
        check_alu(-32'd5, 32'd5, 3'b111, 32'd1, 1'b0, "SLT neg < pos (signed true)");
        // Positive < Negative (Must be 0 in signed arithmetic!)
        check_alu(32'd5, -32'd5, 3'b111, 32'd0, 1'b1, "SLT pos > neg (signed false)");
        // Negative < Negative (True: -30 < -10)
        check_alu(-32'd30, -32'd10, 3'b111, 32'd1, 1'b0, "SLT neg < neg (true)");
        // Negative < Negative (False: -10 < -30 is false)
        check_alu(-32'd10, -32'd30, 3'b111, 32'd0, 1'b1, "SLT neg > neg (false)");
        // Negative == Negative (False)
        check_alu(-32'd20, -32'd20, 3'b111, 32'd0, 1'b1, "SLT neg == neg (false)");
        // Extreme 32-bit signed values: Min Negative < Max Positive
        check_alu(32'h8000_0000, 32'h7FFF_FFFF, 3'b111, 32'd1, 1'b0, "SLT min_neg < max_pos");
        check_alu(32'h7FFF_FFFF, 32'h8000_0000, 3'b111, 32'd0, 1'b1, "SLT max_pos > min_neg");

        // ---------------------------------------------------------------------
        // 6. Default / Unused Control Codes
        // ---------------------------------------------------------------------
        $display("\n--- [6] Testing Default/Unused Control Codes ---");
        check_alu(32'hFFFF_FFFF, 32'hFFFF_FFFF, 3'b011, 32'd0, 1'b1, "Default ctrl 3'b011");
        check_alu(32'h1234_5678, 32'h8765_4321, 3'b100, 32'd0, 1'b1, "Default ctrl 3'b100");
        check_alu(32'hDEAD_BEEF, 32'hCAFE_BABE, 3'b101, 32'd0, 1'b1, "Default ctrl 3'b101");

        // ---------------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------------
        $display("\n================================================================================");
        if (fail_count == 0) begin
            $display("ALU TEST RESULT: ALL %0d CHECKS PASSED SUCCESSFULLY! [PASS]", pass_count);
        end else begin
            $display("ALU TEST RESULT: %0d / %0d CHECKS FAILED! [FAIL]", fail_count, test_count);
        end
        $display("================================================================================");

        $finish;
    end

endmodule
