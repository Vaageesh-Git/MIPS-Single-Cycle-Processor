module main_decoder (
    input  wire [5:0] opcode,
    output wire       reg_write,
    output wire       reg_dst,
    output wire       alu_src,
    output wire       mem_write,
    output wire       mem_to_reg,
    output wire       branch,
    output wire       jump,
    output wire [1:0] alu_op
);

    reg [8:0] controls;

    // Control word packing:
    // {reg_write, reg_dst, alu_src, mem_write, mem_to_reg, branch, jump, alu_op[1:0]}
    always @(*) begin
        case (opcode)
            6'b000000: controls = 9'b1_1_0_0_0_0_0_10; // R-type
            6'b100011: controls = 9'b1_0_1_0_1_0_0_00; // LW
            6'b101011: controls = 9'b0_0_1_1_0_0_0_00; // SW (reg_dst and mem_to_reg set to 0 instead of X for clean waveforms)
            6'b001000: controls = 9'b1_0_1_0_0_0_0_00; // ADDI
            // PHASE II: BEQ 6'b000100: controls = 9'b0_0_0_0_0_1_0_01; // branch=1, alu_op=01, no writes
            // PHASE II: J   6'b000010: controls = 9'b0_0_0_0_0_0_1_00; // jump=1, everything else 0
            default:   controls = 9'b0_0_0_0_0_0_0_00; // Safe NOP default (no writes)
        endcase
    end

    assign {reg_write, reg_dst, alu_src, mem_write, mem_to_reg, branch, jump, alu_op} = controls;

endmodule

