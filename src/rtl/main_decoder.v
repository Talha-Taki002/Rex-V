module main_decoder (
    input wire [6:0] opcode,
    output wire [1:0] result_src,
    output wire [1:0] imm_src,
    output wire [1:0] ALU_op,
    output wire reg_write_en,
    output wire mem_write_en,
    output wire branch,
    output wire jump,
    output wire ALU_src
);

    reg [10:0] control_signals;

    always @(*) begin
        case (opcode)
            //                                  res_imm_alu_R_M_B_J_A
            7'b0110011: control_signals = 11'b00_xx_10_1_0_0_0_0; // R-type
            7'b0010011: control_signals = 11'b00_00_10_1_0_0_0_1; // I-type (ADDI)
            7'b0000011: control_signals = 11'b01_00_00_1_0_0_0_1; // Load (I-type imm)
            7'b0100011: control_signals = 11'bxx_01_00_0_1_0_0_1; // Store (S-type imm)
            7'b1100011: control_signals = 11'bxx_10_01_0_0_1_0_0; // Branch (B-type imm)
            7'b1101111: control_signals = 11'b10_11_xx_1_0_0_1_x; // JAL (J-type imm)
            default:    control_signals = 11'bxx_xx_xx_0_0_0_0_x; // Default case (safeguard write enables)
        endcase
    end

    assign {result_src, imm_src, ALU_op, reg_write_en, mem_write_en, branch, jump, ALU_src} = control_signals;

endmodule