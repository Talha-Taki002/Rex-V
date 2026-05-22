# Writing Assembly for the Rex-V Single-Cycle Core

This guide explains everything you need to write, assemble, and verify programs for Rex-V — from the instruction set down to the exact structure that lets the testbench report a clean PASS or FAIL.

---

## The Golden Rule: No Pseudo-Instructions

Standard RISC-V assemblers let you cheat by using shortcuts called pseudo-instructions (like `li`, `mv`, or `j`). **This assembler does not.**

This CPU only understands its 10 hardwired instructions. You have to write exactly what the hardware executes.

**How to survive without pseudo-instructions:**
*   Want to move a value? (`mv x1, x2`) → Use **`add x1, x0, x2`**
*   Want to load an immediate? (`li x1, 5`) → Use **`addi x1, x0, 5`**
*   Want to jump unconditionally? (`j label`) → Use **`jal x0, label`**
*   Want to check if greater/equal? (`bge`) → Use **`slt`** combined with **`beq`**
*   Want to check if not equal? → Use **`sub`** to get the difference, then **`beq`** against zero

---

## The 10 Supported Instructions

Rex-V supports exactly these 10 instructions. Arguments must be separated by commas or spaces.

### Arithmetic & Logic
*   **`add rd, rs1, rs2`** — `rd = rs1 + rs2`
*   **`sub rd, rs1, rs2`** — `rd = rs1 - rs2`
*   **`and rd, rs1, rs2`** — `rd = rs1 & rs2` (bitwise AND)
*   **`or  rd, rs1, rs2`** — `rd = rs1 | rs2` (bitwise OR)
*   **`slt rd, rs1, rs2`** — `rd = 1` if `rs1 < rs2` (signed), else `0`
*   **`addi rd, rs1, imm`** — `rd = rs1 + imm` (immediate range: −2048 to +2047)

### Memory
*   **`lw  rd, imm(rs1)`** — Load 32 bits from `Mem[rs1 + imm]` into `rd`
*   **`sw  rs2, imm(rs1)`** — Store 32 bits from `rs2` into `Mem[rs1 + imm]`

### Control Flow
*   **`beq rs1, rs2, label`** — Jump to `label` if `rs1 == rs2`
*   **`jal rd, label`** — Jump to `label`, save `PC+4` in `rd` (use `x0` as `rd` to discard the return address)

---

## Registers

You must use the raw architectural register names: **`x0` through `x31`**.
Do not use ABI names (like `t0`, `a0`, `sp`, `ra`). The assembler will reject them.

*   `x0` is hardwired to zero. Writing to it does nothing — reads always return `0`.
*   By convention in these programs, `x30` holds the MMIO halt address and `x31` is used as a scratch register for writing the pass/fail status code. Using them for other things in the middle of your program will break the verification step.

---

## Syntax & Comments

*   **Labels:** End with a colon (e.g., `loop:`). Can be on their own line or the same line as an instruction.
*   **Comments:** Use `#`. Everything after `#` on that line is ignored.
*   **Immediates:** Decimal (`15`, `-4`) or hexadecimal (`0x0F`, `-0x4`).

---

## The Program Structure (Required for Testbench Verification)

Rex-V programs follow a fixed four-part skeleton. The testbench depends on this structure to report a meaningful result. **Every program you write should follow this pattern exactly.**

```
┌─────────────────────────────┐
│  1. MMIO SETUP              │  Always first. Loads address 4092 into x30.
├─────────────────────────────┤
│  2. INIT / SEEDING          │  Set up registers, seed data into memory.
├─────────────────────────────┤
│  3. ALGORITHM               │  The actual computation.
├─────────────────────────────┤
│  4. VERIFICATION            │  Check the result. Branch to pass or fall to fail.
│     fail: → sw to x30       │
│     pass: → sw to x30       │
│     end:  (auto-halt here)  │
└─────────────────────────────┘
```

### Part 1 — MMIO Setup (always copy this verbatim)

The testbench monitors memory address **4092** for your program's verdict. Any `sw` to that address is intercepted — it never actually goes into data memory, it goes straight to the testbench's status logic.

```assembly
addi x30, x0, 2047
addi x30, x30, 2045    # x30 = 4092 (the MMIO Halt Address)
```

> **Why two instructions?** The `addi` immediate field is 12 bits, so the maximum value you can load in one shot is **2047**. Since 4092 > 2047, you need two additions: 2047 + 2045 = 4092. This is also a good example of a common RISC constraint you will run into all the time.

### Parts 2 & 3 — Init and Algorithm

Do your work here. This is where your program lives.

### Part 4 — Verification + Pass/Fail Reporting

After your algorithm finishes, check whether the result is correct and report to the testbench. The structure must be exactly:

```assembly
    # ... final branch that jumps to pass if correct ...
    beq x_result, x_expected, pass

fail:
    addi x31, x0, <error_code>  # Any value other than 1 means FAIL
    sw x31, 0(x30)              # Write error code to MMIO address 4092
    jal x0, end                 # Skip the pass block

pass:
    addi x31, x0, 1             # 1 always means PASS
    sw x31, 0(x30)              # Write PASS to MMIO address 4092

end:
    # The assembler automatically injects: beq x0, x0, _auto_halt
    # You do not need to write anything here. The CPU will halt safely.
```

**Error code conventions:**
| Code written to 4092 | Testbench interpretation |
|---|---|
| `1` | ✅ PASS — test succeeded |
| `2` | ❌ FAIL — general wrong result |
| `3` | ❌ FAIL — item not found (for search programs) |
| `4+` | ❌ FAIL — use higher codes for multi-step verification |

You can use multiple error codes in one program to pinpoint *which* check failed. For example, write `3` if step one fails and `4` if step two fails — the testbench will print whichever code it saw.

### What the testbench prints

```
[INIT] Loading input/machine_codes/bubble_sort.hex into Instruction Memory...

==================================================
  [SUCCESS] REX-V Core passed the software test!
  Execution completed cleanly in 147 cycles.
==================================================
```

```
==================================================
  [FAILED] Software reported error code: 2
  Check the waveform at cycle 83.
==================================================
```

```
==================================================
  [WARNING] Program hit the auto-halt trap without
  writing a PASS/FAIL status to MMIO Address 4092.
==================================================
```

The WARNING means your program ran to completion but never executed a `sw` to address 4092. Either the verification block was skipped entirely, or you forgot to include it.

---

## The "Auto-Halt" Feature

In a bare-metal processor, once your program ends the PC keeps incrementing into empty memory, executing zeros as instructions forever. To prevent this, you do not need to write an infinite loop at the end of your file. **The assembler automatically appends `beq x0, x0, _auto_halt` as the very last instruction.** The testbench detects this specific instruction and calls `$finish`.

This is why every program ends with an empty `end:` label — it just marks the spot where the auto-halt will land.

---

## How to Assemble

```bash
python scripts/assembler.py <input.asm> <output.hex>
```

Example:

```bash
python scripts/assembler.py input/assembly_programs/bubble_sort.asm input/machine_codes/bubble_sort.hex
```

If you made a typo, used an unsupported instruction, or pushed an immediate out of range, the assembler will tell you exactly which line failed and why.

---

## Full Example — Sum of 1 to 5

A complete, working program that uses loops, memory, and proper verification:

```assembly
# Adds the numbers 1 through 5 and verifies the result is 15.

# --- SETUP MMIO ---
addi x30, x0, 2047
addi x30, x30, 2045    # x30 = 4092 (Halt Address)

# --- INIT ---
addi x10, x0, 5        # x10 = upper limit (5)
addi x11, x0, 0        # x11 = running sum (0)
addi x12, x0, 1        # x12 = current counter (1)

# --- ALGORITHM ---
loop_start:
    slt x13, x10, x12      # x13 = 1 if (limit < counter), i.e. counter > 5
    addi x14, x0, 1
    beq x13, x14, done     # If x13 == 1, we exceeded the limit
    add x11, x11, x12      # sum = sum + counter
    addi x12, x12, 1       # counter++
    jal x0, loop_start

done:
    # --- VERIFICATION ---
    addi x15, x0, 15       # Expected result: 15
    beq x11, x15, pass

fail:
    addi x31, x0, 2
    sw x31, 0(x30)         # Write FAIL
    jal x0, end

pass:
    addi x31, x0, 1
    sw x31, 0(x30)         # Write PASS

end:
    # Assembler auto-injects halt here
```
