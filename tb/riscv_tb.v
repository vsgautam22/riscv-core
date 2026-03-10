`timescale 1ns/1ps

module riscv_tb;

    reg clk;
    reg rst_n;

    integer failed = 0;
    integer passed = 0;

    riscv_top uut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    always #5 clk = ~clk;

    // Register file access for checking
    `define RF uut.u_id.u_regfile.regs

    task check_reg;
        input [4:0]  reg_num;
        input [31:0] expected;
        input [63:0] name;
        begin
            if (`RF[reg_num] === expected) begin
                $display("PASS [%s] x%0d = 0x%08X", name, reg_num, expected);
                passed = passed + 1;
            end else begin
                $display("FAIL [%s] x%0d expected=0x%08X got=0x%08X",
                         name, reg_num, expected, `RF[reg_num]);
                failed = failed + 1;
            end
        end
    endtask

    task check_mem;
        input [7:0]  addr;
        input [31:0] expected;
        input [63:0] name;
        begin
            if (uut.u_mem.dmem[addr] === expected) begin
                $display("PASS [%s] mem[%0d] = 0x%08X", name, addr, expected);
                passed = passed + 1;
            end else begin
                $display("FAIL [%s] mem[%0d] expected=0x%08X got=0x%08X",
                         name, addr, expected, uut.u_mem.dmem[addr]);
                failed = failed + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("sim/riscv_core.vcd");
        $dumpvars(0, riscv_tb);

        clk   = 0;
        rst_n = 0;

        repeat(4) @(posedge clk);
        rst_n = 1;

        // Run enough cycles for all instructions to complete pipeline
        repeat(100) @(posedge clk);

        $display("\n========================================");
        $display("     RISC-V RV32I CORE TESTBENCH        ");
        $display("========================================");

        $display("\n--- Arithmetic ---");
        check_reg(1,  32'h00000005, "addi_x1     ");
        check_reg(2,  32'h00000003, "addi_x2     ");
        check_reg(3,  32'h00000008, "add_x3      ");
        check_reg(4,  32'h00000002, "sub_x4      ");
        check_reg(5,  32'h00000006, "xor_x5      ");
        check_reg(6,  32'h00000007, "or_x6       ");
        check_reg(7,  32'h00000001, "and_x7      ");

        $display("\n--- Immediate ---");
        check_reg(8,  32'h0000000F, "addi_x8     ");
        check_reg(9,  32'h000000FF, "xori_x9     ");

        $display("\n--- Load/Store ---");
        check_mem(0,  32'h00000008, "sw_mem0     ");
        check_reg(11, 32'h00000008, "lw_x11      ");

        $display("\n--- Branch ---");
        check_reg(12, 32'h00000001, "addi_x12    ");
        check_reg(13, 32'h000000AA, "branch_taken");

        $display("\n--- Jump ---");
        check_reg(15, 32'h00000000, "jal_skip    ");

        $display("\n========================================");
        $display("  RESULTS: %0d PASSED, %0d FAILED", passed, failed);
        $display("========================================");
        if (failed == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED - CHECK WAVEFORMS");

        $finish;
    end

    // Timeout watchdog
    initial begin
        #50000;
        $display("TIMEOUT");
        $finish;
    end

endmodule