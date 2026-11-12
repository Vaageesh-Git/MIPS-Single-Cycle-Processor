module imem #(
    parameter INIT_FILE = "programs/test.hex"
) (
    input  wire [31:0] addr,
    output wire [31:0] instr
);

    reg [31:0] mem [0:63];
    integer i;

    initial begin
        for (i = 0; i < 64; i = i + 1)
            mem[i] = 32'b0;
        $readmemh(INIT_FILE, mem);
    end

    assign instr = mem[addr[31:2]];

endmodule

