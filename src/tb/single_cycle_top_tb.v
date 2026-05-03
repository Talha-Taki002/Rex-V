`timescale 1ns / 1ps

module single_cycle_top_tb;

    reg clk;
    reg arsetn;
    
    wire [31:0] write_data;
    wire [31:0] data_address;
    wire mem_write_en;

    // Instantiate your processor
    single_cycle_top uut (
        .clk(clk),
        .arsetn(arsetn),
        .write_data(write_data),
        .data_address(data_address),
        .mem_write_en(mem_write_en)
    );

    // 50 MHz Clock
    always #10 clk = ~clk;

    // MMIO Magic Addresses
    localparam [31:0] ADDR_HALT = 32'h00000FFC; // 4092

    integer cycle_count;

    initial begin
        clk = 0;
        arsetn = 0; 
        cycle_count = 0;
        
        $readmemh("/home/talha-taki/RISC-V/Rex-V/input/programs/stress_test.hex", uut.imem.instruction_mem);

        // Optional: Dump waves for debugging
        $dumpfile("single_cycle_top_wave.vcd");
        $dumpvars(0, single_cycle_top_tb);

        #45;
        arsetn = 1; 
        
        // Failsafe timeout
        #100000;
        $display("\n[FATAL ERROR] CPU got stuck in an infinite loop early. Timeout reached.");
        $finish;
    end

    // Track Execution Cycles
    always @(posedge clk) begin
        if (arsetn) cycle_count = cycle_count + 1;
    end

    // The Master MMIO Interceptor
    always @(negedge clk) begin
        // If the CPU executes a Store Word...
        if (mem_write_en) begin
            
            // ...and it writes to the Magic Halt Address...
            if (data_address == ADDR_HALT) begin
                $display("\n===========================================================");
                if (write_data == 32'd1) begin
                    $display("    [SUCCESS] REX-V PASSED THE EXTREME STRESS TEST!");
                    $display("    All arithmetic, memory, and control branches are flawless.");
                    $display("    Execution completed in %0d clock cycles.", cycle_count);
                end else if (write_data == 32'd2) begin
                    $display("    [FAILED] CPU math or memory integrity broke during Phase 2/3.");
                    $display("    Check registers x9 and x15 in your waveform.");
                end else begin
                    $display("    [FAILED] CPU wrote an unknown error code: %0d", write_data);
                end
                $display("===========================================================\n");
                $finish;
            end
        end
    end

endmodule