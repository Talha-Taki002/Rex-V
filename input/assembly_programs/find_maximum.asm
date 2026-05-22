# Find Maximum in Array
# Scans an array left to right, tracking the largest value seen so far.
#
# Array:           [7, 3, 15, 1, 9]
# Expected result: 15

# --- SETUP MMIO ---
addi x30, x0, 2047
addi x30, x30, 2045    # x30 = 4092 (Halt Address)

# --- ARRAY SEEDING ---
addi x1, x0, 100       # x1 = Array Base Address

addi x2, x0, 7
sw x2, 0(x1)           # arr[0] = 7
addi x2, x0, 3
sw x2, 4(x1)           # arr[1] = 3
addi x2, x0, 15
sw x2, 8(x1)           # arr[2] = 15
addi x2, x0, 1
sw x2, 12(x1)          # arr[3] = 1
addi x2, x0, 9
sw x2, 16(x1)          # arr[4] = 9

# --- FIND MAXIMUM ---
# Seed max with the first element, then scan the rest.
lw   x3, 0(x1)         # x3 = current_max = arr[0]
addi x4, x0, 4         # x4 = counter = 4 (4 elements left to check)
addi x5, x1, 4         # x5 = pointer starting at arr[1]

max_loop:
    beq x4, x0, max_done   # If no elements remain, we are done
    lw  x6, 0(x5)          # Load next candidate

    # slt gives us 1 if current_max < candidate (a new max was found)
    slt x7, x3, x6
    beq x7, x0, no_update  # If x7 == 0, candidate is not larger, skip

    add x3, x0, x6         # current_max = candidate

no_update:
    addi x5, x5, 4         # Advance pointer
    addi x4, x4, -1        # Decrement counter
    jal x0, max_loop       # Loop back

max_done:
    # --- VERIFICATION ---
    # Maximum of [7, 3, 15, 1, 9] should be 15
    addi x8, x0, 15
    beq x3, x8, pass

fail:
    addi x31, x0, 2
    sw x31, 0(x30)         # Write FAIL to MMIO
    jal x0, end

pass:
    addi x31, x0, 1
    sw x31, 0(x30)         # Write PASS to MMIO

end:
    # Assembler auto-injects halt here
