module core_datapath (
    input wire clk,
    input wire arsetn,
    input wire PC_src,
    input wire ALU_src,
    input wire [1:0] result_src,
    input wire reg_write_en,
    input wire [1:0] imm_src,
    input wire [2:0] ALU_control,
    input wire [31:0] instruction,
    input wire [31:0] read_data,
    output wire [31:0] pc_out,
    output wire [31:0] alu_result,
    output wire [31:0] write_data,
    output wire zero
);

    wire [31:0] PC_jump, PC_plus4, imm_ext, reg_data1, reg_data2, ALU_res, result;

    PC_target pc_target_plus4 (
        .pc_in(pc_out),
        .imm(32'd4),
        .pc_out(PC_plus4)
    );

    PC_target pc_target_branch (
        .pc_in(pc_out),
        .imm(imm_ext),
        .pc_out(PC_jump)
    );

    PC pc (
        .clk(clk),
        .arsetn(arsetn),
        .current_pc(PC_src ? PC_jump : PC_plus4),
        .next_pc(pc_out)
    );


    reg_file regfile (
        .clk(clk),
        .rs1_addr(instruction[19:15]),
        .rs2_addr(instruction[24:20]),
        .rd_addr(instruction[11:7]),
        .reg_write_en(reg_write_en),
        .rd_data(result),
        .rs1_data(reg_data1),
        .rs2_data(reg_data2)
    );

    extender imm_extender (
        .imm_in(instruction[31:7]),
        .imm_type(imm_src),
        .imm_out(imm_ext)
    );

    ALU alu (
        .A(reg_data1),
        .B(ALU_src ? imm_ext : reg_data2),
        .ALU_control(ALU_control),
        .ALU_result(ALU_res),
        .zero(zero)
    );

    assign result = (result_src == 2'b00) ? ALU_res :
                    (result_src == 2'b01) ? read_data :
                    (result_src == 2'b10) ? PC_plus4 : 32'bx;
    
    assign alu_result = ALU_res;
    assign write_data = reg_data2;
    
endmodule