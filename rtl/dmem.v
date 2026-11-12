module dmem (
    input  wire        clk,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire [31:0] wd,
    output wire [31:0] rd
);

    reg [31:0] mem [0:63];
    integer i;

    initial begin
        for (i = 0; i < 64; i = i + 1)
            mem[i] = 32'b0;
    end

    // write on clock edge
    always @(posedge clk) begin
        if (we)
            mem[addr[7:2]] <= wd;
    end

    // read is combinational (addr[7:2] converts byte address to word index)
    assign rd = mem[addr[7:2]];

endmodule
