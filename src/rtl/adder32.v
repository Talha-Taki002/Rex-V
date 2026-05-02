module adder32 (
    input wire [31:0] A,
    input wire [31:0] B,
    input wire cin,
    output wire [31:0] sum,
    output wire cout
);

    wire [32:0] carry;

    assign carry[0] = cin;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : adder_loop
            adder adder_inst (
                .a(A[i]),
                .b(B[i]),
                .cin(carry[i]),
                .sum(sum[i]),
                .cout(carry[i + 1])
            );
        end
    endgenerate

    assign cout = carry[32];

endmodule