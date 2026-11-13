module control_unit (
    input  wire [5:0] opcode,
    input  wire [5:0] funct,
    output wire       reg_write,
    output wire       reg_dst,
    output wire       alu_src,
    output wire       mem_write,
    output wire       mem_to_reg,
    output wire       branch,
    output wire       jump,
    output wire [2:0] alu_ctrl
);

    wire [1:0] alu_op;

    main_decoder u_main_decoder (
        .opcode     (opcode),
        .reg_write  (reg_write),
        .reg_dst    (reg_dst),
        .alu_src    (alu_src),
        .mem_write  (mem_write),
        .mem_to_reg (mem_to_reg),
        .branch     (branch),
        .jump       (jump),
        .alu_op     (alu_op)
    );

    alu_decoder u_alu_decoder (
        .alu_op   (alu_op),
        .funct    (funct),
        .alu_ctrl (alu_ctrl)
    );

endmodule

