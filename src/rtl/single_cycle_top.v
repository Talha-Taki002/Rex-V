module single_cycle_top (
    input wire clk,
    input wire arsetn,
    output wire [31:0] write_data,
    output wire [31:0] data_address,
    output wire mem_write_en
);

    wire [31:0] pc, instruction, read_data;

    single_cycle_core core (
        .clk(clk),
        .arsetn(arsetn),
        .instruction(instruction),
        .read_data(read_data),
        .pc(pc),
        .mem_write_en(mem_write_en),
        .alu_result(data_address),
        .write_data(write_data)
    );

    instruction_memory imem (
        .address(pc),
        .instruction(instruction)
    );

    data_memory dmem (
        .clk(clk),
        .mem_write_en(mem_write_en),
        .address(data_address),
        .write_data(write_data),
        .read_data(read_data)
    );

endmodule