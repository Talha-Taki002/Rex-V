module extender (
    input wire [31:7] imm_in,
    input wire [1:0] imm_type,
    output wire [31:0] imm_out
);

    reg [31:0] imm_ext;

    always @(*) begin
        case (imm_type)
            2'b00: imm_ext = {{20{imm_in[31]}}, imm_in[31:20]}; // I-type
            2'b01: imm_ext = {{20{imm_in[31]}}, imm_in[31:25], imm_in[11:7]}; // S-type
            2'b10: imm_ext = {{20{imm_in[31]}}, imm_in[7], imm_in[30:25], imm_in[11:8], 1'b0}; // SB-type
            2'b11: imm_ext = {{12{imm_in[31]}}, imm_in[19:12], imm_in[20], imm_in[30:21], 1'b0}; // UJ-type
            default: imm_ext = 32'bx; // Undefined case 
        endcase
    end

    assign imm_out = imm_ext;




endmodule