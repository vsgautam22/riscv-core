module hazard_unit (
    // Register addresses
    input  wire [4:0]  id_ex_rs1,
    input  wire [4:0]  id_ex_rs2,
    input  wire [4:0]  ex_mem_rd,
    input  wire [4:0]  mem_wb_rd,
    input  wire [4:0]  if_id_rs1,
    input  wire [4:0]  if_id_rs2,
    input  wire [4:0]  id_ex_rd,
    // Control signals
    input  wire        ex_mem_reg_we,
    input  wire        mem_wb_reg_we,
    input  wire        id_ex_mem_re,
    input  wire        pc_sel,
    // Forwarding outputs
    output reg  [1:0]  fwd_a,
    output reg  [1:0]  fwd_b,
    // Stall/flush outputs
    output wire        stall,
    output wire        flush
);

    // EX-EX forwarding (highest priority)
    // MEM-EX forwarding
    always @(*) begin
        // Forward A
        if (ex_mem_reg_we && ex_mem_rd != 5'h0 && ex_mem_rd == id_ex_rs1)
            fwd_a = 2'b10; // from EX/MEM
        else if (mem_wb_reg_we && mem_wb_rd != 5'h0 && mem_wb_rd == id_ex_rs1)
            fwd_a = 2'b01; // from MEM/WB
        else
            fwd_a = 2'b00; // no forwarding

        // Forward B
        if (ex_mem_reg_we && ex_mem_rd != 5'h0 && ex_mem_rd == id_ex_rs2)
            fwd_b = 2'b10; // from EX/MEM
        else if (mem_wb_reg_we && mem_wb_rd != 5'h0 && mem_wb_rd == id_ex_rs2)
            fwd_b = 2'b01; // from MEM/WB
        else
            fwd_b = 2'b00; // no forwarding
    end

    // Load-use hazard detection — stall 1 cycle
    assign stall = id_ex_mem_re &&
                   ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2));

    // Flush on branch/jump taken
    assign flush = pc_sel;

endmodule