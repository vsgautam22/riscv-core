module id_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,
    input  wire        flush,
    input  wire [31:0] if_id_instr,
    input  wire [31:0] if_id_pc,
    // Writeback inputs
    input  wire        wb_we,
    input  wire [4:0]  wb_rd,
    input  wire [31:0] wb_wd,
    // Register file outputs
    output wire [31:0] rd1,
    output wire [31:0] rd2,
    // ID/EX pipeline register outputs
    output reg  [31:0] id_ex_pc,
    output reg  [31:0] id_ex_rd1,
    output reg  [31:0] id_ex_rd2,
    output reg  [31:0] id_ex_imm,
    output reg  [4:0]  id_ex_rs1,
    output reg  [4:0]  id_ex_rs2,
    output reg  [4:0]  id_ex_rd,
    output reg  [3:0]  id_ex_alu_op,
    output reg         id_ex_alu_src,
    output reg         id_ex_mem_we,
    output reg  [2:0]  id_ex_mem_size,
    output reg         id_ex_mem_re,
    output reg         id_ex_reg_we,
    output reg         id_ex_mem_to_reg,
    output reg  [1:0]  id_ex_result_sel,
    output reg         id_ex_branch,
    output reg         id_ex_jump
);

    // Instruction fields
    wire [6:0] opcode  = if_id_instr[6:0];
    wire [4:0] rs1_addr = if_id_instr[19:15];
    wire [4:0] rs2_addr = if_id_instr[24:20];
    wire [4:0] rd_addr  = if_id_instr[11:7];
    wire [2:0] funct3  = if_id_instr[14:12];
    wire [6:0] funct7  = if_id_instr[31:25];

    // Immediate generation
    wire [31:0] imm_i = {{20{if_id_instr[31]}}, if_id_instr[31:20]};
    wire [31:0] imm_s = {{20{if_id_instr[31]}}, if_id_instr[31:25], if_id_instr[11:7]};
    wire [31:0] imm_b = {{19{if_id_instr[31]}}, if_id_instr[31], if_id_instr[7], if_id_instr[30:25], if_id_instr[11:8], 1'b0};
    wire [31:0] imm_u = {if_id_instr[31:12], 12'h0};
    wire [31:0] imm_j = {{11{if_id_instr[31]}}, if_id_instr[31], if_id_instr[19:12], if_id_instr[20], if_id_instr[30:21], 1'b0};

    // Opcode definitions
    localparam OP_R      = 7'b0110011;
    localparam OP_I      = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;

    // ALU op encoding
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLL  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_SLT  = 4'b1000;
    localparam ALU_SLTU = 4'b1001;
    localparam ALU_LUI  = 4'b1010;

    // Control signals (combinational)
    reg [3:0]  alu_op_c;
    reg        alu_src_c;
    reg        mem_we_c;
    reg [2:0]  mem_size_c;
    reg        mem_re_c;
    reg        reg_we_c;
    reg        mem_to_reg_c;
    reg [1:0]  result_sel_c;
    reg        branch_c;
    reg        jump_c;
    reg [31:0] imm_c;

    always @(*) begin
        alu_op_c     = ALU_ADD;
        alu_src_c    = 1'b0;
        mem_we_c     = 1'b0;
        mem_size_c   = funct3;
        mem_re_c     = 1'b0;
        reg_we_c     = 1'b0;
        mem_to_reg_c = 1'b0;
        result_sel_c = 2'b00;
        branch_c     = 1'b0;
        jump_c       = 1'b0;
        imm_c        = imm_i;

        case (opcode)
            OP_R: begin
                reg_we_c  = 1'b1;
                alu_src_c = 1'b0;
                case ({funct7[5], funct3})
                    4'b0000: alu_op_c = ALU_ADD;
                    4'b1000: alu_op_c = ALU_SUB;
                    4'b0001: alu_op_c = ALU_SLL;
                    4'b0010: alu_op_c = ALU_SLT;
                    4'b0011: alu_op_c = ALU_SLTU;
                    4'b0100: alu_op_c = ALU_XOR;
                    4'b0101: alu_op_c = ALU_SRL;
                    4'b1101: alu_op_c = ALU_SRA;
                    4'b0110: alu_op_c = ALU_OR;
                    4'b0111: alu_op_c = ALU_AND;
                    default: alu_op_c = ALU_ADD;
                endcase
            end

            OP_I: begin
                reg_we_c  = 1'b1;
                alu_src_c = 1'b1;
                imm_c     = imm_i;
                case (funct3)
                    3'b000: alu_op_c = ALU_ADD;
                    3'b010: alu_op_c = ALU_SLT;
                    3'b011: alu_op_c = ALU_SLTU;
                    3'b100: alu_op_c = ALU_XOR;
                    3'b110: alu_op_c = ALU_OR;
                    3'b111: alu_op_c = ALU_AND;
                    3'b001: alu_op_c = ALU_SLL;
                    3'b101: alu_op_c = funct7[5] ? ALU_SRA : ALU_SRL;
                    default: alu_op_c = ALU_ADD;
                endcase
            end

            OP_LOAD: begin
                reg_we_c     = 1'b1;
                alu_src_c    = 1'b1;
                mem_re_c     = 1'b1;
                mem_to_reg_c = 1'b1;
                imm_c        = imm_i;
                alu_op_c     = ALU_ADD;
            end

            OP_STORE: begin
                mem_we_c  = 1'b1;
                alu_src_c = 1'b1;
                imm_c     = imm_s;
                alu_op_c  = ALU_ADD;
            end

            OP_BRANCH: begin
                branch_c = 1'b1;
                imm_c    = imm_b;
                alu_op_c = ALU_SUB;
            end

            OP_JAL: begin
                reg_we_c     = 1'b1;
                jump_c       = 1'b1;
                result_sel_c = 2'b01;
                imm_c        = imm_j;
                alu_op_c     = ALU_ADD;
            end

            OP_JALR: begin
                reg_we_c     = 1'b1;
                jump_c       = 1'b1;
                alu_src_c    = 1'b1;
                result_sel_c = 2'b01;
                imm_c        = imm_i;
                alu_op_c     = ALU_ADD;
            end

            OP_LUI: begin
                reg_we_c     = 1'b1;
                alu_src_c    = 1'b1;
                imm_c        = imm_u;
                alu_op_c     = ALU_LUI;
            end

            OP_AUIPC: begin
                reg_we_c     = 1'b1;
                alu_src_c    = 1'b1;
                result_sel_c = 2'b10;
                imm_c        = imm_u;
                alu_op_c     = ALU_ADD;
            end

            default: begin
                reg_we_c = 1'b0;
            end
        endcase
    end

    // Register file instantiation
    regfile u_regfile (
        .clk (clk),
        .we  (wb_we),
        .rs1 (rs1_addr),
        .rs2 (rs2_addr),
        .rd  (wb_rd),
        .wd  (wb_wd),
        .rd1 (rd1),
        .rd2 (rd2)
    );

    // ID/EX pipeline register
    // FIXED - flush is synchronous, only rst_n is async
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // same reset assignments...
        end else if (flush) begin
            // same flush assignments...
        end else if (!stall) begin
            id_ex_pc         <= 32'h0;
            id_ex_rd1        <= 32'h0;
            id_ex_rd2        <= 32'h0;
            id_ex_imm        <= 32'h0;
            id_ex_rs1        <= 5'h0;
            id_ex_rs2        <= 5'h0;
            id_ex_rd         <= 5'h0;
            id_ex_alu_op     <= ALU_ADD;
            id_ex_alu_src    <= 1'b0;
            id_ex_mem_we     <= 1'b0;
            id_ex_mem_size   <= 3'h0;
            id_ex_mem_re     <= 1'b0;
            id_ex_reg_we     <= 1'b0;
            id_ex_mem_to_reg <= 1'b0;
            id_ex_result_sel <= 2'b00;
            id_ex_branch     <= 1'b0;
            id_ex_jump       <= 1'b0;
        end else if (!stall) begin
            id_ex_pc         <= if_id_pc;
            id_ex_rd1        <= rd1;
            id_ex_rd2        <= rd2;
            id_ex_imm        <= imm_c;
            id_ex_rs1        <= rs1_addr;
            id_ex_rs2        <= rs2_addr;
            id_ex_rd         <= rd_addr;
            id_ex_alu_op     <= alu_op_c;
            id_ex_alu_src    <= alu_src_c;
            id_ex_mem_we     <= mem_we_c;
            id_ex_mem_size   <= mem_size_c;
            id_ex_mem_re     <= mem_re_c;
            id_ex_reg_we     <= reg_we_c;
            id_ex_mem_to_reg <= mem_to_reg_c;
            id_ex_result_sel <= result_sel_c;
            id_ex_branch     <= branch_c;
            id_ex_jump       <= jump_c;
        end
    end

endmodule