`timescale 1ns/1ps

module tb_control_c;

    // ---------------------------------------------------------
    // Signals for Control Unit
    // ---------------------------------------------------------
    reg  [5:0] opcode;
    reg  [5:0] funct;
    wire       reg_write;
    wire       reg_dst;
    wire       alu_src;
    wire       mem_write;
    wire       mem_to_reg;
    wire       branch;
    wire       jump;
    wire [2:0] alu_ctrl;

    control_unit dut_cu (
        .opcode     (opcode),
        .funct      (funct),
        .reg_write  (reg_write),
        .reg_dst    (reg_dst),
        .alu_src    (alu_src),
        .mem_write  (mem_write),
        .mem_to_reg (mem_to_reg),
        .branch     (branch),
        .jump       (jump),
        .alu_ctrl   (alu_ctrl)
    );

    // ---------------------------------------------------------
    // Signals for ALU
    // ---------------------------------------------------------
    reg  [31:0] alu_a;
    reg  [31:0] alu_b;
    reg  [2:0]  alu_in_ctrl;
    wire [31:0] alu_result;
    wire        alu_zero;

    alu dut_alu (
        .a        (alu_a),
        .b        (alu_b),
        .alu_ctrl (alu_in_ctrl),
        .result   (alu_result),
        .zero     (alu_zero)
    );

    integer errors;
    integer pass_count;

    // Helper task to check control unit outputs
    task check_cu;
        input [5:0]       test_op;
        input [5:0]       test_funct;
        input             exp_reg_write;
        input             exp_reg_dst;
        input             exp_alu_src;
        input             exp_mem_write;
        input             exp_mem_to_reg;
        input             exp_branch;
        input             exp_jump;
        input [2:0]       exp_alu_ctrl;
        input [8*16:1]    name;
        begin
            opcode = test_op;
            funct  = test_funct;
            #1;
            if (reg_write  === exp_reg_write  &&
                reg_dst    === exp_reg_dst    &&
                alu_src    === exp_alu_src    &&
                mem_write  === exp_mem_write  &&
                mem_to_reg === exp_mem_to_reg &&
                branch     === exp_branch     &&
                jump       === exp_jump       &&
                alu_ctrl   === exp_alu_ctrl) begin
                $display("PASS CU: %0s (op=%b, funct=%b)", name, test_op, test_funct);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL CU: %0s -> got {rw=%b,rd=%b,as=%b,mw=%b,mr=%b,br=%b,j=%b,ctrl=%b}, exp {%b,%b,%b,%b,%b,%b,%b,%b}",
                         name, reg_write, reg_dst, alu_src, mem_write, mem_to_reg, branch, jump, alu_ctrl,
                         exp_reg_write, exp_reg_dst, exp_alu_src, exp_mem_write, exp_mem_to_reg, exp_branch, exp_jump, exp_alu_ctrl);
                errors = errors + 1;
            end
        end
    endtask

    // Helper task to check ALU outputs
    task check_alu;
        input [31:0]   a;
        input [31:0]   b;
        input [2:0]    ctrl;
        input [31:0]   exp_res;
        input          exp_zero;
        input [8*24:1] name;
        begin
            alu_a       = a;
            alu_b       = b;
            alu_in_ctrl = ctrl;
            #1;
            if (alu_result === exp_res && alu_zero === exp_zero) begin
                $display("PASS ALU: %0s (res=%h, zero=%b)", name, alu_result, alu_zero);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL ALU: %0s -> got res=%h zero=%b, exp res=%h zero=%b",
                         name, alu_result, alu_zero, exp_res, exp_zero);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors     = 0;
        pass_count = 0;

        $display("========================================");
        $display("   TESTING CONTROL UNIT (PHASE I)       ");
        $display("========================================");

        // check_cu(op, funct, reg_write, reg_dst, alu_src, mem_write, mem_to_reg, branch, jump, alu_ctrl, name)
        // R-Type tests (op=000000): rw=1, rd=1, as=0, mw=0, mr=0, br=0, j=0
        check_cu(6'b000000, 6'b100000, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 3'b010, "R-Type ADD");
        check_cu(6'b000000, 6'b100010, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 3'b110, "R-Type SUB");
        check_cu(6'b000000, 6'b100100, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 3'b000, "R-Type AND");
        check_cu(6'b000000, 6'b100101, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 3'b001, "R-Type OR");
        check_cu(6'b000000, 6'b101010, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 3'b111, "R-Type SLT");

        // Memory & Immediate Instructions
        // LW   (100011): rw=1, rd=0, as=1, mw=0, mr=1, br=0, j=0, ctrl=010 (ADD)
        check_cu(6'b100011, 6'b000000, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 3'b010, "LW");
        // SW   (101011): rw=0, rd=0, as=1, mw=1, mr=0, br=0, j=0, ctrl=010 (ADD)
        check_cu(6'b101011, 6'b000000, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 3'b010, "SW");
        // ADDI (001000): rw=1, rd=0, as=1, mw=0, mr=0, br=0, j=0, ctrl=010 (ADD)
        check_cu(6'b001000, 6'b000000, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 3'b010, "ADDI");

        // Safe Default (Unknown opcode -> all 0)
        check_cu(6'b111111, 6'b000000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 3'b010, "Safe Default NOP");

        $display("\n========================================");
        $display("   TESTING ALU OPERATIONS (PHASE I)     ");
        $display("========================================");

        // check_alu(a, b, ctrl, exp_res, exp_zero, name)
        // 1. AND (000)
        check_alu(32'hF0F0_AAAA, 32'hFFFF_0000, 3'b000, 32'hF0F0_0000, 1'b0, "AND basic");
        check_alu(32'hF0F0_0000, 32'h0F0F_FFFF, 3'b000, 32'h0000_0000, 1'b1, "AND zero result");

        // 2. OR (001)
        check_alu(32'hF0F0_0000, 32'h0F0F_1234, 3'b001, 32'hFFFF_1234, 1'b0, "OR basic");
        check_alu(32'h0000_0000, 32'h0000_0000, 3'b001, 32'h0000_0000, 1'b1, "OR zero result");

        // 3. ADD (010)
        check_alu(32'd25, 32'd15, 3'b010, 32'd40, 1'b0, "ADD positive");
        check_alu(-32'd10, 32'd10, 3'b010, 32'd0, 1'b1, "ADD zero result");
        check_alu(-32'd15, -32'd25, 3'b010, -32'd40, 1'b0, "ADD negative operands");

        // 4. SUB (110)
        check_alu(32'd50, 32'd20, 3'b110, 32'd30, 1'b0, "SUB positive");
        check_alu(32'd42, 32'd42, 3'b110, 32'd0, 1'b1, "SUB zero result");
        check_alu(32'd10, 32'd25, 3'b110, -32'd15, 1'b0, "SUB negative result");

        // 5. SLT Signed (111)
        // a < b (both positive) -> 1
        check_alu(32'd10, 32'd20, 3'b111, 32'd1, 1'b0, "SLT pos < pos");
        // a > b (both positive) -> 0
        check_alu(32'd30, 32'd20, 3'b111, 32'd0, 1'b1, "SLT pos > pos");
        // a negative, b positive -> MUST BE 1
        check_alu(-32'd5, 32'd5, 3'b111, 32'd1, 1'b0, "SLT neg < pos (signed!)");
        // a positive, b negative -> MUST BE 0
        check_alu(32'd5, -32'd5, 3'b111, 32'd0, 1'b1, "SLT pos > neg (signed!)");
        // equal values -> 0
        check_alu(32'd50, 32'd50, 3'b111, 32'd0, 1'b1, "SLT equal positive");
        check_alu(-32'd20, -32'd20, 3'b111, 32'd0, 1'b1, "SLT equal negative");
        // a < b (both negative): -30 < -10 -> 1
        check_alu(-32'd30, -32'd10, 3'b111, 32'd1, 1'b0, "SLT neg < neg");

        // 6. Safe Default
        check_alu(32'hFFFF_FFFF, 32'hFFFF_FFFF, 3'b101, 32'd0, 1'b1, "ALU invalid ctrl");

        $display("\n========================================");
        if (errors == 0) begin
            $display("RESULT: ALL %0d CHECKS PASSED!", pass_count);
        end else begin
            $display("RESULT: FAILED WITH %0d ERRORS!", errors);
        end
        $display("========================================");

        $finish;
    end

endmodule

