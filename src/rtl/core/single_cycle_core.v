module single_cycle_core (
    input wire clk,
    input wire arsetn,
    input wire [31:0] instruction,
    input wire [31:0] read_data,
    output wire [31:0] pc,
    output wire mem_write_en,
    output wire [31:0] alu_result,
    output wire [31:0] write_data
);

    wire ALU_src, reg_write_en, jump, zero, PC_src;
    wire [1:0] result_src, imm_src;
    wire [2:0] ALU_control;

    control_unit control (
        .opcode(instruction[6:0]),
        .funct3(instruction[14:12]),
        .funct7b5(instruction[30]),
        .zero(zero),
        .result_src(result_src),
        .mem_write_en(mem_write_en),
        .reg_write_en(reg_write_en),
        .PC_src(PC_src),
        .ALU_src(ALU_src),
        .jump(jump),
        .ALU_control(ALU_control),
        .imm_src(imm_src)
    );

    core_datapath datapath (
        .clk(clk),
        .arsetn(arsetn),
        .PC_src(PC_src),
        .ALU_src(ALU_src),
        .result_src(result_src),
        .reg_write_en(reg_write_en),
        .imm_src(imm_src),
        .ALU_control(ALU_control),
        .instruction(instruction),
        .read_data(read_data),
        .pc_out(pc),
        .alu_result(alu_result),
        .write_data(write_data),
        .zero(zero)
    );

    

endmodule