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

    always #10 clk = ~clk;

    // MMIO Address for Status Reporting
    localparam [31:0] ADDR_HALT = 32'd4092; 

    // Internal testbench state
    reg test_passed = 0;
    reg test_failed = 0;
    reg [31:0] fail_code = 0;
    integer cycle_count = 0;

    reg [1023:0] test_file;
    reg [1023:0] vcd_path;

    // dump file for waveform analysis

    initial begin
        // Check if a path was passed from the command line
        if ($value$plusargs("vcd_path=%s", vcd_path)) begin
            $dumpfile(vcd_path);
        end else begin
            // Fallback if no argument is provided
            $dumpfile("processor_wave_dump.vcd"); 
        end
        
        $dumpvars(0, single_cycle_top_tb);
    end

    initial begin
        clk = 0;
        arsetn = 0; 
        
        // Grab the hex file from the command line, default to program.hex
        if (!$value$plusargs("test_file=%s", test_file)) begin
            test_file = "program.hex"; 
        end
        
        $display("\n[INIT] Loading %s into Instruction Memory...", test_file);
        $readmemh(test_file, uut.imem.instruction_mem);

        #45;
        arsetn = 1; 
        
        #100000; // Expanded timeout for heavier algorithms
        $display("\n[FATAL ERROR] Simulation Timed Out.");
        $finish;
    end

    // Cycle Counter
    always @(posedge clk) begin
        if (arsetn) cycle_count = cycle_count + 1;
    end

    // The Hardware Monitor
    always @(negedge clk) begin
        // 1. Listen for MMIO Status Updates
        if (mem_write_en && data_address == ADDR_HALT) begin
            if (write_data == 32'd1) begin
                test_passed = 1;
            end else begin
                test_failed = 1;
                fail_code = write_data;
            end
        end
        
        // 2. Detect Assembler's Auto-Halt Trap (beq x0, x0, 0)
        if (uut.instruction == 32'h00000063 && arsetn) begin
            $display("\n==================================================");
            if (test_passed && !test_failed) begin
                $display("  [SUCCESS] REX-V Core passed the software test!");
                $display("  Execution completed cleanly in %0d cycles.", cycle_count);
            end else if (test_failed) begin
                $display("  [FAILED] Software reported error code: %0d", fail_code);
                $display("  Check the waveform at cycle %0d.", cycle_count);
            end else begin
                $display("  [WARNING] Program hit the auto-halt trap without");
                $display("  writing a PASS/FAIL status to MMIO Address 4092.");
            end
            $display("==================================================\n");
            $finish;
        end
    end

endmodule