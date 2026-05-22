import sys
import re

# --- INSTRUCTION DEFINITIONS ---
OPCODES = {
    'R': 0x33,     # add, sub, and, or, slt
    'I_ALU': 0x13, # addi
    'I_LOAD': 0x03,# lw
    'S': 0x23,     # sw
    'B': 0x63,     # beq
    'J': 0x6F      # jal
}

FUNCT3 = {
    'add': 0x0, 'sub': 0x0, 'and': 0x7, 'or': 0x6, 'slt': 0x2,
    'addi': 0x0, 'lw': 0x2, 'sw': 0x2, 'beq': 0x0
}

FUNCT7 = {
    'add': 0x00, 'sub': 0x20, 'and': 0x00, 'or': 0x00, 'slt': 0x00
}

# --- HELPER FUNCTIONS ---

def parse_reg(reg_str):
    reg_str = reg_str.lower()
    if not reg_str.startswith('x'):
        raise ValueError(f"Invalid register '{reg_str}'. Use architectural names x0-x31 (no ABI names like t0, a0).")
    try:
        reg = int(reg_str.replace('x', ''))
        if not 0 <= reg <= 31:
            raise ValueError
        return reg
    except ValueError:
        raise ValueError(f"Invalid register number in '{reg_str}'. Must be x0 to x31.")

def check_imm_bounds(imm, bits, instr_name):
    # Calculate signed bounds
    min_val = -(1 << (bits - 1))
    max_val = (1 << (bits - 1)) - 1
    if not (min_val <= imm <= max_val):
        raise ValueError(f"Immediate {imm} out of bounds for {bits}-bit signed value in '{instr_name}'. Valid range: [{min_val}, {max_val}].")

# --- ENCODERS ---

def encode_r_type(instr, rd, rs1, rs2):
    val = (FUNCT7[instr] << 25) | (rs2 << 20) | (rs1 << 15) | (FUNCT3[instr] << 12) | (rd << 7) | OPCODES['R']
    return val & 0xFFFFFFFF

def encode_i_type(opcode, funct3, rd, rs1, imm, instr_name):
    check_imm_bounds(imm, 12, instr_name)
    imm &= 0xFFF
    val = (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
    return val & 0xFFFFFFFF

def encode_s_type(rs1, rs2, imm):
    check_imm_bounds(imm, 12, 'sw')
    imm &= 0xFFF
    imm11_5 = (imm >> 5) & 0x7F
    imm4_0 = imm & 0x1F
    val = (imm11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (FUNCT3['sw'] << 12) | (imm4_0 << 7) | OPCODES['S']
    return val & 0xFFFFFFFF

def encode_b_type(rs1, rs2, imm):
    check_imm_bounds(imm, 13, 'beq')
    if imm % 2 != 0:
        raise ValueError(f"Branch offset {imm} must be a multiple of 2.")
    imm &= 0x1FFE
    imm12 = (imm >> 12) & 1
    imm11 = (imm >> 11) & 1
    imm10_5 = (imm >> 5) & 0x3F
    imm4_1 = (imm >> 1) & 0xF
    val = (imm12 << 31) | (imm10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (FUNCT3['beq'] << 12) | (imm4_1 << 8) | (imm11 << 7) | OPCODES['B']
    return val & 0xFFFFFFFF

def encode_j_type(rd, imm):
    check_imm_bounds(imm, 21, 'jal')
    if imm % 2 != 0:
        raise ValueError(f"Jump offset {imm} must be a multiple of 2.")
    imm &= 0x1FFFFE
    imm20 = (imm >> 20) & 1
    imm19_12 = (imm >> 12) & 0xFF
    imm11 = (imm >> 11) & 1
    imm10_1 = (imm >> 1) & 0x3FF
    val = (imm20 << 31) | (imm10_1 << 21) | (imm11 << 20) | (imm19_12 << 12) | (rd << 7) | OPCODES['J']
    return val & 0xFFFFFFFF

# --- MAIN ASSEMBLER ---

def assemble(input_file, output_file):
    labels = {}
    instructions = []
    
    try:
        with open(input_file, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: Could not find input file '{input_file}'")
        sys.exit(1)

    # Pass 1: Extract labels and strip comments/whitespace
    pc = 0
    for line_num, line in enumerate(lines):
        line = line.split('#')[0].strip()
        if not line:
            continue
        
        if ':' in line:
            label, rest = line.split(':', 1)
            # Prevent duplicate labels
            if label.strip() in labels:
                print(f"Error on line {line_num + 1}: Duplicate label '{label.strip()}'")
                sys.exit(1)
                
            labels[label.strip()] = pc
            line = rest.strip()
            if not line:
                continue
                
        instructions.append((pc, line, line_num + 1))
        pc += 4

    # --- AUTO-HALT INJECTION ---
    halt_label = "_auto_halt"
    labels[halt_label] = pc
    instructions.append((pc, f"beq x0, x0, {halt_label}", "EOF (Auto-Halt)"))
    pc += 4

    machine_code = []

    # Pass 2: Instruction Translation
    for pc, line, line_num in instructions:
        try:
            # Split by commas, spaces, or parentheses
            parts = re.split(r'[,\s()]+', line)
            parts = [p for p in parts if p]
            instr = parts[0].lower()

            if instr in ['add', 'sub', 'and', 'or', 'slt']:
                if len(parts) != 4: raise ValueError(f"Expected 3 arguments for '{instr}' (e.g., {instr} rd, rs1, rs2)")
                rd, rs1, rs2 = parse_reg(parts[1]), parse_reg(parts[2]), parse_reg(parts[3])
                hex_val = encode_r_type(instr, rd, rs1, rs2)

            elif instr == 'addi':
                if len(parts) != 4: raise ValueError("Expected 3 arguments for 'addi' (e.g., addi rd, rs1, imm)")
                rd, rs1 = parse_reg(parts[1]), parse_reg(parts[2])
                try: imm = int(parts[3], 0) # Base 0 handles both hex (0x) and decimal
                except ValueError: raise ValueError(f"Invalid immediate '{parts[3]}'")
                hex_val = encode_i_type(OPCODES['I_ALU'], FUNCT3[instr], rd, rs1, imm, instr)

            elif instr == 'lw':
                if len(parts) != 4: raise ValueError("Expected format: lw rd, imm(rs1)")
                rd = parse_reg(parts[1])
                try: imm = int(parts[2], 0)
                except ValueError: raise ValueError(f"Invalid immediate '{parts[2]}'")
                rs1 = parse_reg(parts[3])
                hex_val = encode_i_type(OPCODES['I_LOAD'], FUNCT3[instr], rd, rs1, imm, instr)

            elif instr == 'sw':
                if len(parts) != 4: raise ValueError("Expected format: sw rs2, imm(rs1)")
                rs2 = parse_reg(parts[1])
                try: imm = int(parts[2], 0)
                except ValueError: raise ValueError(f"Invalid immediate '{parts[2]}'")
                rs1 = parse_reg(parts[3])
                hex_val = encode_s_type(rs1, rs2, imm)

            elif instr == 'beq':
                if len(parts) != 4: raise ValueError("Expected 3 arguments for 'beq' (e.g., beq rs1, rs2, label)")
                rs1, rs2, label = parse_reg(parts[1]), parse_reg(parts[2]), parts[3]
                if label not in labels: raise ValueError(f"Undefined label: '{label}'")
                imm = labels[label] - pc
                hex_val = encode_b_type(rs1, rs2, imm)

            elif instr == 'jal':
                if len(parts) != 3: raise ValueError("Expected 2 arguments for 'jal' (e.g., jal rd, label)")
                rd, label = parse_reg(parts[1]), parts[2]
                if label not in labels: raise ValueError(f"Undefined label: '{label}'")
                imm = labels[label] - pc
                hex_val = encode_j_type(rd, imm)

            else:
                raise ValueError(f"Unsupported instruction: '{instr}'. Supported are: add, sub, and, or, slt, addi, lw, sw, beq, jal.")

            machine_code.append(f"{hex_val:08x}")

        except Exception as e:
            print(f"Assembly Error on line {line_num}:\n  Code:  {line}\n  Error: {e}")
            sys.exit(1)

    # Write output to hex file
    try:
        with open(output_file, 'w') as f:
            f.write('\n'.join(machine_code) + '\n')
        print(f"Success! Assembled {len(machine_code)} instructions (including auto-halt) to '{output_file}'")
    except Exception as e:
        print(f"Error writing to output file '{output_file}': {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python assembler.py <input.asm> <output.hex>")
    else:
        assemble(sys.argv[1], sys.argv[2])