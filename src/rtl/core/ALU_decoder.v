module ALU_decoder (
    input wire [1:0] ALU_op,
    input wire [2:0] funct3,
    input wire funct7b5,
    input wire opb5,
    output wire [2:0] ALU_control
);

    reg [2:0] control;

    always @(*) begin
        case (ALU_op)
            2'b00: control = 3'b000; // Load/Store (ADD)
            2'b01: control = 3'b001; // Branch (SUB)
            2'b10: begin // R-type or I-type
                case (funct3)
                    3'b000: begin
                        case (opb5)
                            1'b0: control = 3'b000; // ADDI
                            1'b1: control = funct7b5 ? 3'b001 : 3'b000;     
                            default: control = 3'bxxx; // Invalid opb5
                        endcase
                    end
                    3'b010: control = 3'b101; // SLT
                    3'b110: control = 3'b011; // OR
                    3'b111: control = 3'b010; // AND
                    default: control = 3'bxxx; // Invalid funct3
                endcase
            end
            default: control = 3'bxxx; // Invalid ALU_op
        endcase
    end

    assign ALU_control = control;


endmodule