module if_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,
    input  wire        flush,
    input  wire [31:0] pc_branch,
    input  wire        pc_sel,
    output reg  [31:0] pc,
    output wire [31:0] pc_plus4,
    output reg  [31:0] if_id_pc,
    output reg  [31:0] if_id_instr
);

    // Instruction memory — 1KB, initialized from file
    reg [31:0] imem [0:255];

    initial begin
        $readmemh("tb/imem.hex", imem);
    end

    assign pc_plus4 = pc + 32'h4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc           <= 32'h0;
            if_id_pc     <= 32'h0;
            if_id_instr  <= 32'h00000013; // NOP (ADDI x0,x0,0)
        end else if (flush) begin
            if_id_pc     <= 32'h0;
            if_id_instr  <= 32'h00000013;
            pc           <= pc_branch;
        end else if (!stall) begin
            pc           <= pc_sel ? pc_branch : pc_plus4;
            if_id_pc     <= pc;
            if_id_instr  <= imem[pc[9:2]];
        end
    end

endmodule