# Writing Assembly for the Rex-V Single-Cycle Core


## The Golden Rule: No Pseudo-Instructions

Standard RISC-V assemblers let you cheat by using shortcuts called pseudo-instructions (like `li`, `mv`, or `j`). **My assembler does not.** 

This CPU only understands its 10 hardwired instructions. You have to write exactly what the hardware executes. 

**How to survive without pseudo-instructions:**
*   Want to move a value? (`mv x1, x2`) ➔ Use **`add x1, x0, x2`**
*   Want to load an immediate? (`li x1, 5`) ➔ Use **`addi x1, x0, 5`**
*   Want to jump unconditionally? (`j label`) ➔ Use **`jal x0, label`**
*   Want to check if greater/equal? (`bge`) ➔ Use **`slt`** combined with **`beq`**

---

## The 10 Supported Instructions

Rex-V supports exactly these 10 instructions. Arguments must be separated by commas or spaces.

### Arithmetic & Logic
*   **`add rd, rs1, rs2`** (Add: `rd = rs1 + rs2`)
*   **`sub rd, rs1, rs2`** (Subtract: `rd = rs1 - rs2`)
*   **`and rd, rs1, rs2`** (Bitwise AND: `rd = rs1 & rs2`)
*   **`or rd, rs1, rs2`**  (Bitwise OR: `rd = rs1 | rs2`)
*   **`slt rd, rs1, rs2`** (Set Less Than: `rd = 1` if `rs1 < rs2`, else `0`)
*   **`addi rd, rs1, imm`** (Add Immediate: `rd = rs1 + imm`)

### Memory
*   **`lw rd, imm(rs1)`** (Load Word: Load 32 bits from memory at address `rs1 + imm` into `rd`)
*   **`sw rs2, imm(rs1)`** (Store Word: Store 32 bits from `rs2` into memory at address `rs1 + imm`)

### Control Flow
*   **`beq rs1, rs2, label`** (Branch if Equal: Jump to `label` if `rs1 == rs2`)
*   **`jal rd, label`** (Jump and Link: Jump to `label` and save the return address in `rd`)

---

## Registers

You must use the raw architectural register names: **`x0` through `x31`**.
Do not use ABI names (like `t0`, `a0`, `sp`, `ra`). The assembler will reject them to enforce strict hardware-level awareness.

*Note: `x0` is hardwired to zero. Writing to it does nothing, but it is incredibly useful for things like unconditional jumps or moving values!*

---

## Syntax & Comments

*   **Labels:** End them with a colon (e.g., `loop:`). They can be on their own line or the same line as an instruction.
*   **Comments:** Use the `#` symbol. Everything after the `#` on that line is ignored.
*   **Immediates:** You can use standard decimal (`15`, `-4`) or hexadecimal (`0x0F`, `-0x4`).

---

## Example Program

Here is a perfectly formatted program that adds the numbers 1 through 5.

```assembly
# Initialization
addi x10, x0, 5      # x10 = target limit (5)
addi x11, x0, 0      # x11 = running sum (0)
addi x12, x0, 1      # x12 = current counter (1)

loop_start:
# If counter > target limit, we are done
slt x13, x10, x12    # x13 = 1 if (target < counter)
addi x14, x0, 1      # Load a 1 to check against
beq x13, x14, done   # If x13 == 1, jump to 'done'

# Add counter to sum, then increment counter
add x11, x11, x12    # sum = sum + counter
addi x12, x12, 1     # counter = counter + 1

# Jump back to the start of the loop
jal x0, loop_start

done:
# Store the final result (15) into memory at address 100
addi x15, x0, 100    # Set base address
sw x11, 0(x15)       # Mem[100] = sum
```

---

## How to Assemble

Save your assembly code in a file (e.g., `program.asm`) and run the assembler from your terminal:

```bash
python assembler.py program.asm machine_code.hex
```

If you made a typo, used an unsupported instruction, or pushed an immediate out of bounds, the assembler will tell you exactly which line failed.

### The "Auto-Halt" Feature
In bare-metal processors, if your program just "ends," the CPU will keep reading junk data from memory and executing it. 

To prevent this, you don't need to manually write an infinite loop at the end of your file. **The assembler automatically injects a safe `beq x0, x0, _auto_halt` instruction at the very end of your program.** Once your code finishes, the CPU will safely trap itself there forever.