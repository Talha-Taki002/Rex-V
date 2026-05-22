module ALU (
    input wire [31:0] A,
    input wire [31:0] B,
    input wire [2:0] ALU_control,
    output wire zero,
    output wire [31:0] ALU_result
);

    wire [31:0] sum;
    wire cout;
    reg [31:0] ALU_res;

    adder32 adder_inst (
        .A(A),
        .B(ALU_control[0] ? ~B : B),
        .cin(ALU_control[0]),
        .sum(sum),
        .cout(cout)
    );

    wire same_sign = ~(A[31] ^ B[31]);
    wire slt_bit = (~same_sign & A[31]) | (same_sign & sum[31]);

    always @(*) begin
        case (ALU_control)
            3'b000: ALU_res = sum; 
            3'b001: ALU_res = sum;
            3'b010: ALU_res = A & B;
            3'b011: ALU_res = A | B;
            3'b101: ALU_res = {31'b0, slt_bit};
            default: ALU_res = 32'b0;
        endcase
    end

    assign ALU_result = ALU_res;
    assign zero = &(~ALU_result);



endmodule