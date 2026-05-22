# Sum of Array
# Computes the sum of 5 integers stored in memory.
#
# Array:           [10, 20, 30, 40, 50]
# Expected result: 150

# --- SETUP MMIO ---
addi x30, x0, 2047
addi x30, x30, 2045    # x30 = 4092 (Halt Address)

# --- ARRAY SEEDING ---
addi x1, x0, 100       # x1 = Array Base Address (byte address 100)

addi x2, x0, 10
sw x2, 0(x1)           # arr[0] = 10
addi x2, x0, 20
sw x2, 4(x1)           # arr[1] = 20
addi x2, x0, 30
sw x2, 8(x1)           # arr[2] = 30
addi x2, x0, 40
sw x2, 12(x1)          # arr[3] = 40
addi x2, x0, 50
sw x2, 16(x1)          # arr[4] = 50

# --- SUM LOOP ---
addi x3, x0, 0         # x3 = running sum = 0
addi x4, x0, 5         # x4 = loop counter = 5 (elements remaining)
add  x5, x0, x1        # x5 = memory pointer = base address

sum_loop:
    beq x4, x0, sum_done   # If counter == 0, all elements processed
    lw  x6, 0(x5)          # Load current element into x6
    add x3, x3, x6         # sum = sum + element
    addi x5, x5, 4         # Advance pointer by one word (4 bytes)
    addi x4, x4, -1        # Decrement counter
    jal x0, sum_loop       # Loop back

sum_done:
    # --- VERIFICATION ---
    # 10 + 20 + 30 + 40 + 50 = 150
    addi x7, x0, 150
    beq x3, x7, pass

fail:
    addi x31, x0, 2
    sw x31, 0(x30)         # Write FAIL to MMIO
    jal x0, end

pass:
    addi x31, x0, 1
    sw x31, 0(x30)         # Write PASS to MMIO

end:
    # Assembler auto-injects halt here
