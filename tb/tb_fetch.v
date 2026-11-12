`timescale 1ns/1ps

module tb_fetch;

    reg         clk;
    reg         reset;
    wire [31:0] pc_out;
    wire [31:0] pc_plus4;
    wire [31:0] instr;

    reg [31:0] expected_instr [0:4];
    integer    i;
    integer    errors;

    pc u_pc (
        .clk      (clk),
        .reset    (reset),
        .next_pc  (pc_plus4),
        .pc       (pc_out),
        .pc_plus4 (pc_plus4)
    );

    imem u_imem (
        .addr  (pc_out),
        .instr (instr)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        expected_instr[0] = 32'h20080005; // addi $t0, $0, 5
        expected_instr[1] = 32'h20090007; // addi $t1, $0, 7
        expected_instr[2] = 32'h01095020; // add  $t2, $t0, $t1
        expected_instr[3] = 32'hAC0A0000; // sw   $t2, 0($0)
        expected_instr[4] = 32'h8C0B0000; // lw   $t3, 0($0)

        errors = 0;
        reset  = 1'b1;

        // Hold reset across first posedge clk
        @(posedge clk);
        #1;
        if (pc_out !== 32'd0) begin
            $display("FAIL: after reset pc=%h (expected 00000000)", pc_out);
            errors = errors + 1;
        end

        // Deassert reset on negedge for clean setup to next posedge
        @(negedge clk);
        reset = 1'b0;

        // Verify PC increments 0, 4, 8, 12, 16 and instr matches test.hex
        for (i = 0; i < 5; i = i + 1) begin
            #1;
            if (pc_out !== (i * 4) || instr !== expected_instr[i]) begin
                $display("FAIL cycle %0d: pc=%0d (exp %0d), instr=%h (exp %h)",
                         i, pc_out, i * 4, instr, expected_instr[i]);
                errors = errors + 1;
            end else begin
                $display("PASS cycle %0d: pc=%0d, instr=%h", i, pc_out, instr);
            end
            @(posedge clk);
        end

        if (errors == 0)
            $display("RESULT: PASS");
        else
            $display("RESULT: FAIL (%0d errors)", errors);

        $finish;
    end

endmodule

