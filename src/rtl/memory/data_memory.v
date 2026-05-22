module data_memory (
    input wire clk,
    input wire mem_write_en,
    input wire [31:0] address,
    input wire [31:0] write_data,
    output wire [31:0] read_data
);

    reg [31:0] memory [0:1023]; // 1024 words of 32-bit memory, total 4KB

    assign read_data = memory[address[11:2]]; // Word-aligned access

    always @(posedge clk) begin
        if (mem_write_en) begin
            memory[address[11:2]] <= write_data; // Word-aligned access
        end
    end


endmodule