# Linear Search
# Scans an array for a target value and verifies it is at the expected index.
# Uses sub to check equality: if (arr[i] - target == 0), they are equal.
#
# Array:           [10, 25, 7, 42, 18]
# Target:          42
# Expected index:  3
#
# Error codes:
#   2 = target was found but at the wrong index (logic error)
#   3 = target was not found in the array at all

# --- SETUP MMIO ---
addi x30, x0, 2047
addi x30, x30, 2045    # x30 = 4092 (Halt Address)

# --- ARRAY SEEDING ---
addi x1, x0, 100       # x1 = Array Base Address

addi x2, x0, 10
sw x2, 0(x1)           # arr[0] = 10
addi x2, x0, 25
sw x2, 4(x1)           # arr[1] = 25
addi x2, x0, 7
sw x2, 8(x1)           # arr[2] = 7
addi x2, x0, 42
sw x2, 12(x1)          # arr[3] = 42
addi x2, x0, 18
sw x2, 16(x1)          # arr[4] = 18

# --- LINEAR SEARCH ---
addi x3, x0, 42        # x3 = target value
addi x4, x0, 5         # x4 = array size (used as bounds check)
addi x5, x0, 0         # x5 = current index (starts at 0)
add  x6, x0, x1        # x6 = memory pointer (starts at base)

search_loop:
    beq x5, x4, not_found  # If index reached array size, target does not exist
    lw  x7, 0(x6)          # Load arr[index]
    sub x8, x7, x3         # x8 = arr[index] - target
    beq x8, x0, found      # If difference is 0, they are equal -> found
    addi x5, x5, 1         # index++
    addi x6, x6, 4         # Advance pointer by one word
    jal x0, search_loop    # Loop back

not_found:
    addi x31, x0, 3
    sw x31, 0(x30)         # Write error code 3 (not found) to MMIO
    jal x0, end

found:
    # --- VERIFICATION ---
    # 42 should be at index 3
    addi x9, x0, 3
    beq x5, x9, pass

fail:
    addi x31, x0, 2
    sw x31, 0(x30)         # Write error code 2 (wrong index) to MMIO
    jal x0, end

pass:
    addi x31, x0, 1
    sw x31, 0(x30)         # Write PASS to MMIO

end:
    # Assembler auto-injects halt here
