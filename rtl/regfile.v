module regfile (
    input  wire        clk,
    input  wire        we3,
    input  wire [4:0]  ra1,
    input  wire [4:0]  ra2,
    input  wire [4:0]  wa3,
    input  wire [31:0] wd3,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);

    reg [31:0] regs [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end

    // write on clock edge, never write to $0
    always @(posedge clk) begin
        if (we3 && wa3 != 5'd0)
            regs[wa3] <= wd3;
    end

    // read is combinational, $0 always reads 0
    assign rd1 = (ra1 == 5'd0) ? 32'b0 : regs[ra1];
    assign rd2 = (ra2 == 5'd0) ? 32'b0 : regs[ra2];

endmodule
