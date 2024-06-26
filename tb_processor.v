`timescale 1ns / 1ps

module testbench;

    reg clk;
    reg rst;
    reg signed [31:0] GPR_out [0:31];  // Define GPR_out as a reg array

    // Instantiate the RISC-V processor module
    RISCV_Processor dut (
        .clk(clk),
        .rst(rst),
        .GPR(GPR_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        clk = 0;
        rst = 1;
        #10 rst = 0;
    end

    // Memory loading
    initial begin
        $readmemb("program.mem", dut.program_mem);
        // Initialize data memory if needed
        // $readmemb("data.mem", dut.data_mem);
    end

    // Monitor to display destination register after each instruction
    int i = 0;
    always @(posedge clk) begin
        if (rst == 0 && dut.read_flag == 1'b1) begin
            // Display PC, instruction, and GPR content
            i++;
        end
    end

    // Simulation end
    initial begin
        // Simulate for a reasonable time
        #1000;

        // End simulation
        $finish;
    end

endmodule