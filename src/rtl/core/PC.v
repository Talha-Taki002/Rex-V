module PC (
    input wire clk,
    input wire arsetn,
    input wire [31:0] current_pc,
    output reg [31:0] next_pc
);

    always @(posedge clk or negedge arsetn) begin
        if (!arsetn) begin
            next_pc <= 32'h00000000;
        end 
        else begin
            next_pc <= current_pc;
        end
    end

endmodule