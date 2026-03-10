module ex_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] id_ex_pc,
    input  wire [31:0] id_ex_rd1,
    input  wire [31:0] id_ex_rd2,
    input  wire [31:0] id_ex_imm,
    input  wire [4:0]  id_ex_rs1,
    input  wire [4:0]  id_ex_rs2,
    input  wire [4:0]  id_ex_rd,
    input  wire [3:0]  id_ex_alu_op,
    input  wire        id_ex_alu_src,
    input  wire        id_ex_mem_we,
    input  wire [2:0]  id_ex_mem_size,
    input  wire        id_ex_mem_re,
    input  wire        id_ex_reg_we,
    input  wire        id_ex_mem_to_reg,
    input  wire [1:0]  id_ex_result_sel,
    input  wire        id_ex_branch,
    input  wire        id_ex_jump,
    input  wire [1:0]  fwd_a,
    input  wire [1:0]  fwd_b,
    input  wire [31:0] ex_mem_alu_result,
    input  wire [31:0] wb_result,
    output wire [31:0] pc_branch,
    output wire        pc_sel,
    output reg  [31:0] ex_mem_pc,
    output reg  [31:0] ex_mem_alu_result_reg,
    output reg  [31:0] ex_mem_rd2,
    output reg  [4:0]  ex_mem_rd,
    output reg  [3:0]  ex_mem_alu_op,
    output reg         ex_mem_mem_we,
    output reg  [2:0]  ex_mem_mem_size,
    output reg         ex_mem_mem_re,
    output reg         ex_mem_reg_we,
    output reg         ex_mem_mem_to_reg,
    output reg  [1:0]  ex_mem_result_sel
);
    reg [31:0] alu_a, alu_b_pre;
    always @(*) begin
        case (fwd_a)
            2'b00: alu_a   = id_ex_rd1;
            2'b01: alu_a   = wb_result;
            2'b10: alu_a   = ex_mem_alu_result;
            default: alu_a = id_ex_rd1;
        endcase
        case (fwd_b)
            2'b00: alu_b_pre   = id_ex_rd2;
            2'b01: alu_b_pre   = wb_result;
            2'b10: alu_b_pre   = ex_mem_alu_result;
            default: alu_b_pre = id_ex_rd2;
        endcase
    end
    wire [31:0] alu_b = id_ex_alu_src ? id_ex_imm : alu_b_pre;
    wire [31:0] alu_result;
    wire        alu_zero;
    alu u_alu (.a(alu_a), .b(alu_b), .alu_op(id_ex_alu_op), .result(alu_result), .zero(alu_zero));
    reg branch_taken;
    always @(*) begin
        case (id_ex_mem_size)
            3'b000: branch_taken = (alu_a == alu_b_pre);
            3'b001: branch_taken = (alu_a != alu_b_pre);
            3'b100: branch_taken = ($signed(alu_a) < $signed(alu_b_pre));
            3'b101: branch_taken = ($signed(alu_a) >= $signed(alu_b_pre));
            3'b110: branch_taken = (alu_a < alu_b_pre);
            3'b111: branch_taken = (alu_a >= alu_b_pre);
            default: branch_taken = 1'b0;
        endcase
    end
    assign pc_branch = (id_ex_jump && !id_ex_branch) ?
                       (id_ex_alu_src ? (alu_a + id_ex_imm) & ~32'h1 : id_ex_pc + id_ex_imm) :
                       id_ex_pc + id_ex_imm;
    assign pc_sel = (id_ex_branch && branch_taken) || id_ex_jump;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_mem_pc <= 0; ex_mem_alu_result_reg <= 0; ex_mem_rd2 <= 0;
            ex_mem_rd <= 0; ex_mem_alu_op <= 0; ex_mem_mem_we <= 0;
            ex_mem_mem_size <= 0; ex_mem_mem_re <= 0; ex_mem_reg_we <= 0;
            ex_mem_mem_to_reg <= 0; ex_mem_result_sel <= 0;
        end else begin
            ex_mem_pc             <= id_ex_pc;
            ex_mem_alu_result_reg <= alu_result;
            ex_mem_rd2            <= alu_b_pre;
            ex_mem_rd             <= id_ex_rd;
            ex_mem_alu_op         <= id_ex_alu_op;
            ex_mem_mem_we         <= id_ex_mem_we;
            ex_mem_mem_size       <= id_ex_mem_size;
            ex_mem_mem_re         <= id_ex_mem_re;
            ex_mem_reg_we         <= id_ex_reg_we;
            ex_mem_mem_to_reg     <= id_ex_mem_to_reg;
            ex_mem_result_sel     <= id_ex_result_sel;
        end
    end
endmodule