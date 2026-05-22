module PC_target (
    input wire [31:0] pc_in,
    input wire [31:0] imm,
    output wire [31:0] pc_out
);

    adder32 pc_adder (
        .A(pc_in),
        .B(imm),
        .cin(1'b0),
        .sum(pc_out),
        .cout()
    );

endmodule