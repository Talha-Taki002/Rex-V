module control_unit (
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire funct7b5,
    input wire zero,
    output wire [1:0] result_src,
    output wire mem_write_en,
    output wire reg_write_en,
    output wire PC_src,
    output wire ALU_src,
    output wire jump,
    output wire [2:0] ALU_control,
    output wire [1:0] imm_src
);

    wire [1:0] ALU_op;
    wire branch;

    main_decoder main_dec (
        .opcode(opcode),
        .result_src(result_src),
        .imm_src(imm_src),
        .ALU_op(ALU_op),
        .reg_write_en(reg_write_en),
        .mem_write_en(mem_write_en),
        .branch(branch),
        .jump(jump),
        .ALU_src(ALU_src)
    );

    ALU_decoder alu_dec (
        .ALU_op(ALU_op),
        .funct3(funct3),
        .funct7b5(funct7b5),
        .opb5(opcode[5]),
        .ALU_control(ALU_control)
    );

    assign PC_src = (branch & zero) | jump;


endmodule