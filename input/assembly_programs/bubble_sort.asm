# --- SETUP MMIO ---
addi x30, x0, 2047
addi x30, x30, 2045    # x30 = 4092 (Halt Address)

# --- ARRAY SEEDING ---
addi x1, x0, 100       # x1 = Array Base Address
addi x2, x0, 5         # x2 = Array Size (5 elements)

addi x3, x0, 42        # arr[0] = 42
sw x3, 0(x1)
addi x3, x0, 17        # arr[1] = 17
sw x3, 4(x1)
addi x3, x0, 99        # arr[2] = 99
sw x3, 8(x1)
addi x3, x0, 3         # arr[3] = 3
sw x3, 12(x1)
addi x3, x0, 55        # arr[4] = 55
sw x3, 16(x1)

# --- BUBBLE SORT LOGIC ---
addi x4, x2, -1        # x4 = Outer loop counter (size - 1)

outer_loop:
    beq x4, x0, sort_done  # If outer counter == 0, we are finished
    add x5, x0, x0         # x5 = Inner loop counter (reset to 0)
    add x6, x0, x1         # x6 = Current memory pointer (reset to base)

inner_loop:
    beq x5, x4, inner_done # If inner counter == outer counter, loop is done
    
    lw x7, 0(x6)           # Load arr[i]
    lw x8, 4(x6)           # Load arr[i+1]
    
    # Compare: if arr[i+1] < arr[i], we need to swap!
    slt x9, x8, x7
    beq x9, x0, no_swap    # If x9 is 0 (arr[i] <= arr[i+1]), skip swap
    
    # Swap elements in memory
    sw x8, 0(x6)
    sw x7, 4(x6)

no_swap:
    addi x6, x6, 4         # Advance memory pointer by 4 bytes
    addi x5, x5, 1         # Increment inner counter
    jal x0, inner_loop     # Repeat inner loop

inner_done:
    addi x4, x4, -1        # Decrement outer counter
    jal x0, outer_loop     # Repeat outer loop

sort_done:
    # --- VERIFICATION ---
    # The lowest number (3) should now be at the base address
    lw x10, 0(x1)
    addi x11, x0, 3
    beq x10, x11, pass
    
fail:
    addi x31, x0, 2
    sw x31, 0(x30)         # Write FAIL to MMIO
    jal x0, end            # Jump to end (auto-halt)

pass:
    addi x31, x0, 1
    sw x31, 0(x30)         # Write PASS to MMIO

end:
    # Assembler auto-injects halt here