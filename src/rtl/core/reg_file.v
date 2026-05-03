module reg_file (
    input wire clk,
    input wire [4:0] rs1_addr,
    input wire [4:0] rs2_addr,
    input wire [4:0] rd_addr,
    input wire [31:0] rd_data,
    input wire reg_write_en,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);

    reg [31:0] reg_mem [31:0];

    assign rs1_data = (rs1_addr != 5'd0) ? reg_mem[rs1_addr] : 32'b0; // Register x0 is hardwired to 0
    assign rs2_data = (rs2_addr != 5'd0) ? reg_mem[rs2_addr] : 32'b0;


    always @(posedge clk) begin
        if (reg_write_en && rd_addr != 5'd0) begin
            reg_mem[rd_addr] <= rd_data;
        end
    end

endmodule