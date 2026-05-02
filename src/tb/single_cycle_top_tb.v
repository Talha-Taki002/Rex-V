`timescale 1ns / 1ps

module single_cycle_top_tb;

    reg clk;
    reg arsetn;
    
    wire [31:0] write_data;
    wire [31:0] data_address;
    wire mem_write_en;

    // Instantiate Top Module
    single_cycle_top uut (
        .clk(clk),
        .arsetn(arsetn),
        .write_data(write_data),
        .data_address(data_address),
        .mem_write_en(mem_write_en)
    );

    // Clock Generation: 20ns period (50 MHz)
    always #10 clk = ~clk;

    initial begin
        clk = 0;
        arsetn = 0; 
        
        // Load the Master Stress Test
        $readmemh("master_test.hex", uut.imem.instruction_mem);

        $dumpfile("processor_wave.vcd");
        $dumpvars(0, single_cycle_top_tb);

        #45;
        arsetn = 1; 
        
        // Fallback timeout just in case of a hard crash
        #100000;
        $display("\n[ERROR] Simulation Timed Out. The CPU is stuck.");
        $finish;
    end

    // The Verification Watchdog
    always @(negedge clk) begin
        // Check if the CPU is trying to write to memory
        if (mem_write_en) begin
            // Did it write to Address 100?
            if (data_address == 32'd100) begin
                // Check if the payload is the Victory Code
                if (write_data == 32'd2026) begin
                    $display("\n===========================================================");
                    $display("  [SUCCESS!] CPU PASSED THE MASTER STRESS TEST!");
                    $display("  Victory Code '2026' successfully written to Memory[100].");
                    $display("  All 10 instructions are functioning flawlessly.");
                    $display("===========================================================\n");
                    $finish; // End simulation on success
                end else begin
                    $display("\n[FAILED] CPU reached the end, but the math was wrong.");
                    $display("Expected 2026, but CPU wrote: %0d", write_data);
                    $finish; // End simulation on failure
                end
            end
        end
        
        // If it hits the infinite loop without writing to memory, it failed early
        if (uut.instruction == 32'h00000063 && arsetn) begin
            $display("\n[FAILED] CPU trapped itself in the FAIL state.");
            $display("It failed a branch or jump evaluation and never reached the finish line.");
            $finish;
        end
    end

endmodule