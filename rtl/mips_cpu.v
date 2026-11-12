module mips_cpu (
    input wire clk,
    input wire reset
);

    // ---------------------------------------------------------
    // Internal Wires
    // ---------------------------------------------------------
    // Fetch
    wire [31:0] pc_out;
    wire [31:0] pc_plus4;
    wire [31:0] next_pc;
    wire [31:0] instr;

    // Instruction Decode
    wire [5:0]  opcode;
    wire [4:0]  rs;
    wire [4:0]  rt;
    wire [4:0]  rd;
    wire [5:0]  funct;
    wire [15:0] imm;

    // Control Signals
    wire        reg_write;
    wire        reg_dst;
    wire        alu_src;
    wire        mem_write;
    wire        mem_to_reg;
    wire        branch;     // Phase II
    wire        jump;       // Phase II
    wire [2:0]  alu_ctrl;

    // Datapath
    wire [4:0]  write_reg;
    wire [31:0] src_a;
    wire [31:0] write_data;
    wire [31:0] sign_imm;
    wire [31:0] src_b;
    wire [31:0] alu_result;
    wire        zero;       // Phase II
    wire [31:0] read_data;
    wire [31:0] result_wb;

    // ---------------------------------------------------------
    // Instruction Field Decode
    // ---------------------------------------------------------
    assign opcode = instr[31:26];
    assign rs     = instr[25:21];
    assign rt     = instr[20:16];
    assign rd     = instr[15:11];
    assign funct  = instr[5:0];
    assign imm    = instr[15:0];

    // ---------------------------------------------------------
    // Fetch Stage
    // ---------------------------------------------------------
    // PHASE II: branch/jump mux goes here (will use branch, jump, zero, sign_imm, instr[25:0])
    assign next_pc = pc_plus4;

    pc u_pc (
        .clk      (clk),
        .reset    (reset),
        .next_pc  (next_pc),
        .pc       (pc_out),
        .pc_plus4 (pc_plus4)
    );

    imem u_imem (
        .addr  (pc_out),
        .instr (instr)
    );

    // ---------------------------------------------------------
    // Control Unit
    // ---------------------------------------------------------
    control_unit u_control_unit (
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
    // Register File & Write-Register Mux
    // ---------------------------------------------------------
    mux2 #(.W(5)) u_mux_writereg (
        .d0  (rt),
        .d1  (rd),
        .sel (reg_dst),
        .y   (write_reg)
    );

    regfile u_regfile (
        .clk (clk),
        .we3 (reg_write),
        .ra1 (rs),
        .ra2 (rt),
        .wa3 (write_reg),
        .wd3 (result_wb),
        .rd1 (src_a),
        .rd2 (write_data)
    );

    // ---------------------------------------------------------
    // Sign Extend & ALU
    // ---------------------------------------------------------
    sign_extend u_sign_extend (
        .in  (imm),
        .out (sign_imm)
    );

    mux2 #(.W(32)) u_mux_alusrc (
        .d0  (write_data),
        .d1  (sign_imm),
        .sel (alu_src),
        .y   (src_b)
    );

    alu u_alu (
        .a        (src_a),
        .b        (src_b),
        .alu_ctrl (alu_ctrl),
        .result   (alu_result),
        .zero     (zero)
    );

    // ---------------------------------------------------------
    // Data Memory & Write-Back Mux
    // ---------------------------------------------------------
    dmem u_dmem (
        .clk  (clk),
        .we   (mem_write),
        .addr (alu_result),
        .wd   (write_data),
        .rd   (read_data)
    );

    mux2 #(.W(32)) u_mux_memtoreg (
        .d0  (alu_result),
        .d1  (read_data),
        .sel (mem_to_reg),
        .y   (result_wb)
    );

endmodule

