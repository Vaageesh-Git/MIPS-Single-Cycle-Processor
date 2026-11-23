`timescale 1ns/1ps

////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_datapath
// Target: Isolated Datapath verification (regfile + dmem)
// Member B: Verification of register file and data memory storage/retrieval
//           simulating loop program patterns (Array Store and Load).
////////////////////////////////////////////////////////////////////////////////

module tb_datapath;

    reg         clk;
    // regfile ports
    reg         we3;
    reg  [4:0]  ra1, ra2, wa3;
    reg  [31:0] wd3;
    wire [31:0] rd1, rd2;

    // dmem ports
    reg         mem_we;
    reg  [31:0] mem_addr;
    reg  [31:0] mem_wd;
    wire [31:0] mem_rd;

    // DUT instances
    regfile u_regfile (
        .clk (clk),
        .we3 (we3),
        .ra1 (ra1),
        .ra2 (ra2),
        .wa3 (wa3),
        .wd3 (wd3),
        .rd1 (rd1),
        .rd2 (rd2)
    );

    dmem u_dmem (
        .clk  (clk),
        .we   (mem_we),
        .addr (mem_addr),
        .wd   (mem_wd),
        .rd   (mem_rd)
    );

    // Test tracking
    integer errors;
    integer pass_count;
    integer i;

    // 6-element test array
    reg [31:0] test_array [0:5];

    // Clock generation (10ns period)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        errors     = 0;
        pass_count = 0;

        test_array[0] = 32'd3;
        test_array[1] = 32'd7;
        test_array[2] = 32'd2;
        test_array[3] = 32'd9;
        test_array[4] = 32'd4;
        test_array[5] = 32'd11;

        we3      = 1'b0;
        ra1      = 5'd0;
        ra2      = 5'd0;
        wa3      = 5'd0;
        wd3      = 32'd0;
        mem_we   = 1'b0;
        mem_addr = 32'd0;
        mem_wd   = 32'd0;

        $display("================================================================================");
        $display("             ISOLATED DATAPATH TESTBENCH (tb_datapath: regfile + dmem)          ");
        $display("================================================================================");

        // -------------------------------------------------------------
        // Step 1: Pre-populate regfile $t0..$t5 ($8..$13) with array data
        // -------------------------------------------------------------
        $display("\n[Step 1] Loading 6 array elements into regfile registers $8..$13 ($t0..$t5)...");
        for (i = 0; i < 6; i = i + 1) begin
            @(negedge clk);
            we3 = 1'b1;
            wa3 = 5'd8 + i;
            wd3 = test_array[i];
            @(posedge clk);
            #1;
            we3 = 1'b0;
        end

        // Verify regfile values combinational read
        for (i = 0; i < 6; i = i + 1) begin
            ra1 = 5'd8 + i;
            #1;
            if (rd1 === test_array[i]) begin
                $display("  PASS: regfile[$%0d] = %0d", 8 + i, rd1);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: regfile[$%0d] = %0d (expected %0d)", 8 + i, rd1, test_array[i]);
                errors = errors + 1;
            end
        end

        // -------------------------------------------------------------
        // Step 2: Store array elements from regfile into dmem words 0..5
        // -------------------------------------------------------------
        $display("\n[Step 2] Storing array elements from regfile into dmem memory addresses...");
        for (i = 0; i < 6; i = i + 1) begin
            @(negedge clk);
            ra1      = 5'd8 + i;
            #1;
            mem_we   = 1'b1;
            mem_addr = i * 4;       // Byte address: 0, 4, 8, 12, 16, 20
            mem_wd   = rd1;
            @(posedge clk);
            #1;
            mem_we   = 1'b0;
        end

        // -------------------------------------------------------------
        // Step 3: Load back from dmem into a different register bank ($s0..$s5, $16..$21)
        // -------------------------------------------------------------
        $display("\n[Step 3] Loading back from dmem into registers $16..$21 ($s0..$s5)...");
        for (i = 0; i < 6; i = i + 1) begin
            mem_addr = i * 4;
            #1;
            // Write loaded value into regfile
            @(negedge clk);
            we3 = 1'b1;
            wa3 = 5'd16 + i;
            wd3 = mem_rd;
            @(posedge clk);
            #1;
            we3 = 1'b0;
        end

        // Verify loaded registers
        for (i = 0; i < 6; i = i + 1) begin
            ra1 = 5'd16 + i;
            #1;
            if (rd1 === test_array[i]) begin
                $display("  PASS: Loaded dmem[0x%02x] -> regfile[$%0d] = %0d", i * 4, 16 + i, rd1);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: Loaded dmem[0x%02x] -> regfile[$%0d] = %0d (expected %0d)",
                         i * 4, 16 + i, rd1, test_array[i]);
                errors = errors + 1;
            end
        end

        // -------------------------------------------------------------
        // Step 4: Verify $0 immutability in regfile
        // -------------------------------------------------------------
        $display("\n[Step 4] Checking $0 hardwired zero immutability...");
        @(negedge clk);
        we3 = 1'b1;
        wa3 = 5'd0;
        wd3 = 32'hDEADBEEF;
        @(posedge clk);
        #1;
        we3 = 1'b0;
        ra1 = 5'd0;
        #1;
        if (rd1 === 32'b0) begin
            $display("  PASS: regfile[$0] remains 0 after write attempt");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: regfile[$0] was overwritten! val = %h", rd1);
            errors = errors + 1;
        end

        $display("================================================================================");
        if (errors == 0) begin
            $display("DATAPATH TEST RESULT: ALL %0d CHECKS PASSED! [PASS]", pass_count);
        end else begin
            $display("DATAPATH TEST RESULT: FAILED WITH %0d ERRORS!", errors);
        end
        $display("================================================================================");

        $finish;
    end

endmodule
