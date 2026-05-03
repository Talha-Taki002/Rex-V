# Calculate 5! (120) without a dedicated hardware multiplier

# --- SETUP MMIO ---
addi x30, x0, 2047
addi x30, x30, 2045    # x30 = 4092 (Halt Address)

# --- INIT ---
addi x1, x0, 5         # x1 = n (Calculate 5!)
addi x2, x0, 1         # x2 = Running Result (Starts at 1)

fact_loop:
    beq x1, x0, fact_done  # If n == 0, factorial is complete
    
    # Software Multiplication: result = result * n
    add x3, x0, x2         # x3 = Temp copy of current result
    addi x4, x1, -1        # x4 = Multiplication counter (n - 1 additions)
    
mul_loop:
    beq x4, x0, mul_done   # If multiplication counter is 0, addition is done
    add x2, x2, x3         # result = result + temp
    addi x4, x4, -1        # Decrement multiplication counter
    jal x0, mul_loop       # Repeat addition
    
mul_done:
    addi x1, x1, -1        # Decrement n (n--)
    jal x0, fact_loop      # Go to next factorial step

fact_done:
    # --- VERIFICATION ---
    # Check if 5! correctly calculated to 120
    addi x5, x0, 120
    beq x2, x5, pass
    
fail:
    addi x31, x0, 2
    sw x31, 0(x30)         # Write FAIL
    jal x0, end

pass:
    addi x31, x0, 1
    sw x31, 0(x30)         # Write PASS

end:
    # Assembler auto-injects halt here