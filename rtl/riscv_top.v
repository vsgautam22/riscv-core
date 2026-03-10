module riscv_top (
    input wire clk,
    input wire rst_n
);

    // IF stage wires
    wire [31:0] pc;
    wire [31:0] pc_plus4;
    wire [31:0] if_id_pc;
    wire [31:0] if_id_instr;

    // ID stage wires
    wire [31:0] rd1, rd2;
    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_rd1, id_ex_rd2, id_ex_imm;
    wire [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;
    wire [3:0]  id_ex_alu_op;
    wire        id_ex_alu_src;
    wire        id_ex_mem_we;
    wire [2:0]  id_ex_mem_size;
    wire        id_ex_mem_re;
    wire        id_ex_reg_we;
    wire        id_ex_mem_to_reg;
    wire [1:0]  id_ex_result_sel;
    wire        id_ex_branch;
    wire        id_ex_jump;

    // EX stage wires
    wire [31:0] pc_branch;
    wire        pc_sel;
    wire [31:0] ex_mem_pc;
    wire [31:0] ex_mem_alu_result;  // driven by ex_stage's clocked reg; fed back as EX-EX forward
    wire [31:0] ex_mem_rd2;
    wire [4:0]  ex_mem_rd;
    wire [3:0]  ex_mem_alu_op;
    wire        ex_mem_mem_we;
    wire [2:0]  ex_mem_mem_size;
    wire        ex_mem_mem_re;
    wire        ex_mem_reg_we;
    wire        ex_mem_mem_to_reg;
    wire [1:0]  ex_mem_result_sel;

    // MEM stage wires
    wire [31:0] mem_wb_pc;
    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_read_data;
    wire [4:0]  mem_wb_rd;
    wire        mem_wb_reg_we;
    wire        mem_wb_mem_to_reg;
    wire [1:0]  mem_wb_result_sel;

    // WB wires
    wire [31:0] wb_result;
    wire        wb_we;
    wire [4:0]  wb_rd;

    // Hazard unit wires
    wire [1:0]  fwd_a, fwd_b;
    wire        stall, flush;

    // Instruction fields for hazard detection
    wire [4:0] if_id_rs1 = if_id_instr[19:15];
    wire [4:0] if_id_rs2 = if_id_instr[24:20];

    // WB stage — combinational
    assign wb_we     = mem_wb_reg_we;
    assign wb_rd     = mem_wb_rd;
    assign wb_result = mem_wb_mem_to_reg ? mem_wb_read_data :
                       (mem_wb_result_sel == 2'b01) ? mem_wb_pc + 32'h4 :
                       (mem_wb_result_sel == 2'b10) ? mem_wb_pc + mem_wb_alu_result :
                       mem_wb_alu_result;

    if_stage u_if (
        .clk         (clk),
        .rst_n       (rst_n),
        .stall       (stall),
        .flush       (flush),
        .pc_branch   (pc_branch),
        .pc_sel      (pc_sel),
        .pc          (pc),
        .pc_plus4    (pc_plus4),
        .if_id_pc    (if_id_pc),
        .if_id_instr (if_id_instr)
    );

    id_stage u_id (
        .clk              (clk),
        .rst_n            (rst_n),
        .stall            (stall),
        .flush            (flush),
        .if_id_instr      (if_id_instr),
        .if_id_pc         (if_id_pc),
        .wb_we            (wb_we),
        .wb_rd            (wb_rd),
        .wb_wd            (wb_result),
        .rd1              (rd1),
        .rd2              (rd2),
        .id_ex_pc         (id_ex_pc),
        .id_ex_rd1        (id_ex_rd1),
        .id_ex_rd2        (id_ex_rd2),
        .id_ex_imm        (id_ex_imm),
        .id_ex_rs1        (id_ex_rs1),
        .id_ex_rs2        (id_ex_rs2),
        .id_ex_rd         (id_ex_rd),
        .id_ex_alu_op     (id_ex_alu_op),
        .id_ex_alu_src    (id_ex_alu_src),
        .id_ex_mem_we     (id_ex_mem_we),
        .id_ex_mem_size   (id_ex_mem_size),
        .id_ex_mem_re     (id_ex_mem_re),
        .id_ex_reg_we     (id_ex_reg_we),
        .id_ex_mem_to_reg (id_ex_mem_to_reg),
        .id_ex_result_sel (id_ex_result_sel),
        .id_ex_branch     (id_ex_branch),
        .id_ex_jump       (id_ex_jump)
    );

    ex_stage u_ex (
        .clk                  (clk),
        .rst_n                (rst_n),
        .id_ex_pc             (id_ex_pc),
        .id_ex_rd1            (id_ex_rd1),
        .id_ex_rd2            (id_ex_rd2),
        .id_ex_imm            (id_ex_imm),
        .id_ex_rs1            (id_ex_rs1),
        .id_ex_rs2            (id_ex_rs2),
        .id_ex_rd             (id_ex_rd),
        .id_ex_alu_op         (id_ex_alu_op),
        .id_ex_alu_src        (id_ex_alu_src),
        .id_ex_mem_we         (id_ex_mem_we),
        .id_ex_mem_size       (id_ex_mem_size),
        .id_ex_mem_re         (id_ex_mem_re),
        .id_ex_reg_we         (id_ex_reg_we),
        .id_ex_mem_to_reg     (id_ex_mem_to_reg),
        .id_ex_result_sel     (id_ex_result_sel),
        .id_ex_branch         (id_ex_branch),
        .id_ex_jump           (id_ex_jump),
        .fwd_a                (fwd_a),
        .fwd_b                (fwd_b),
        .ex_mem_alu_result    (ex_mem_alu_result),  // EX-EX forward: reads registered value
        .wb_result            (wb_result),
        .pc_branch            (pc_branch),
        .pc_sel               (pc_sel),
        .ex_mem_pc            (ex_mem_pc),
        .ex_mem_alu_result_reg(ex_mem_alu_result),  // clocked reg output drives this wire
        .ex_mem_rd2           (ex_mem_rd2),
        .ex_mem_rd            (ex_mem_rd),
        .ex_mem_alu_op        (ex_mem_alu_op),
        .ex_mem_mem_we        (ex_mem_mem_we),
        .ex_mem_mem_size      (ex_mem_mem_size),
        .ex_mem_mem_re        (ex_mem_mem_re),
        .ex_mem_reg_we        (ex_mem_reg_we),
        .ex_mem_mem_to_reg    (ex_mem_mem_to_reg),
        .ex_mem_result_sel    (ex_mem_result_sel)
    );

    mem_stage u_mem (
        .clk               (clk),
        .rst_n             (rst_n),
        .ex_mem_pc         (ex_mem_pc),
        .ex_mem_alu_result (ex_mem_alu_result),
        .ex_mem_rd2        (ex_mem_rd2),
        .ex_mem_rd         (ex_mem_rd),
        .ex_mem_mem_we     (ex_mem_mem_we),
        .ex_mem_mem_size   (ex_mem_mem_size),
        .ex_mem_mem_re     (ex_mem_mem_re),
        .ex_mem_reg_we     (ex_mem_reg_we),
        .ex_mem_mem_to_reg (ex_mem_mem_to_reg),
        .ex_mem_result_sel (ex_mem_result_sel),
        .mem_wb_pc         (mem_wb_pc),
        .mem_wb_alu_result (mem_wb_alu_result),
        .mem_wb_read_data  (mem_wb_read_data),
        .mem_wb_rd         (mem_wb_rd),
        .mem_wb_reg_we     (mem_wb_reg_we),
        .mem_wb_mem_to_reg (mem_wb_mem_to_reg),
        .mem_wb_result_sel (mem_wb_result_sel)
    );

    hazard_unit u_haz (
        .id_ex_rs1     (id_ex_rs1),
        .id_ex_rs2     (id_ex_rs2),
        .ex_mem_rd     (ex_mem_rd),
        .mem_wb_rd     (mem_wb_rd),
        .if_id_rs1     (if_id_rs1),
        .if_id_rs2     (if_id_rs2),
        .id_ex_rd      (id_ex_rd),
        .ex_mem_reg_we (ex_mem_reg_we),
        .mem_wb_reg_we (mem_wb_reg_we),
        .id_ex_mem_re  (id_ex_mem_re),
        .pc_sel        (pc_sel),
        .fwd_a         (fwd_a),
        .fwd_b         (fwd_b),
        .stall         (stall),
        .flush         (flush)
    );

endmodule