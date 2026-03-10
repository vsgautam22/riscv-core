module regfile (
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);
    reg [31:0] regs [0:31];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'h0;
    end

    // Asynchronous read with write-through forwarding for same-cycle WB conflict.
    // When WB writes rd at the same clock edge that ID reads rs1/rs2,
    // the combinational read sees stale data. Bypass solves this.
    assign rd1 = (rs1 == 5'h0)              ? 32'h0 :
                 (we && rd == rs1 && rd != 0) ? wd    :
                 regs[rs1];

    assign rd2 = (rs2 == 5'h0)              ? 32'h0 :
                 (we && rd == rs2 && rd != 0) ? wd    :
                 regs[rs2];

    // Synchronous write, x0 never written
    always @(posedge clk) begin
        if (we && rd != 5'h0)
            regs[rd] <= wd;
    end

endmodule