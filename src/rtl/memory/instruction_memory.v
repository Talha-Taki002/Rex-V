module instruction_memory (
    input wire [31:0] address,
    output wire [31:0] instruction
);

    reg [31:0] instruction_mem [0:255]; // 256 words of 32-bit instruction memory, total 1KB

    assign instruction = instruction_mem[address[9:2]]; // Word-aligned access


endmodule