module mem_stage (
    input  wire        clk,
    input  wire        rst_n,
    // EX/MEM inputs
    input  wire [31:0] ex_mem_pc,
    input  wire [31:0] ex_mem_alu_result,
    input  wire [31:0] ex_mem_rd2,
    input  wire [4:0]  ex_mem_rd,
    input  wire        ex_mem_mem_we,
    input  wire [2:0]  ex_mem_mem_size,
    input  wire        ex_mem_mem_re,
    input  wire        ex_mem_reg_we,
    input  wire        ex_mem_mem_to_reg,
    input  wire [1:0]  ex_mem_result_sel,
    // MEM/WB pipeline register outputs
    output reg  [31:0] mem_wb_pc,
    output reg  [31:0] mem_wb_alu_result,
    output reg  [31:0] mem_wb_read_data,
    output reg  [4:0]  mem_wb_rd,
    output reg         mem_wb_reg_we,
    output reg         mem_wb_mem_to_reg,
    output reg  [1:0]  mem_wb_result_sel
);

    // Data memory — 1KB
    reg [31:0] dmem [0:255];

    integer j;
    initial begin
        for (j = 0; j < 256; j = j + 1)
            dmem[j] = 32'h0;
    end

    wire [7:0]  addr  = ex_mem_alu_result[9:2];
    wire [31:0] wdata = ex_mem_rd2;

    // Write
    always @(posedge clk) begin
        if (ex_mem_mem_we) begin
            case (ex_mem_mem_size[1:0])
                2'b00: begin // SB
                    case (ex_mem_alu_result[1:0])
                        2'b00: dmem[addr][7:0]   <= wdata[7:0];
                        2'b01: dmem[addr][15:8]  <= wdata[7:0];
                        2'b10: dmem[addr][23:16] <= wdata[7:0];
                        2'b11: dmem[addr][31:24] <= wdata[7:0];
                    endcase
                end
                2'b01: begin // SH
                    case (ex_mem_alu_result[1])
                        1'b0: dmem[addr][15:0]  <= wdata[15:0];
                        1'b1: dmem[addr][31:16] <= wdata[15:0];
                    endcase
                end
                2'b10: dmem[addr] <= wdata; // SW
                default: dmem[addr] <= wdata;
            endcase
        end
    end

    // Read with sign extension
    reg [31:0] read_data;
    always @(*) begin
        case (ex_mem_mem_size)
            3'b000: begin // LB
                case (ex_mem_alu_result[1:0])
                    2'b00: read_data = {{24{dmem[addr][7]}},  dmem[addr][7:0]};
                    2'b01: read_data = {{24{dmem[addr][15]}}, dmem[addr][15:8]};
                    2'b10: read_data = {{24{dmem[addr][23]}}, dmem[addr][23:16]};
                    2'b11: read_data = {{24{dmem[addr][31]}}, dmem[addr][31:24]};
                    default: read_data = 32'h0;
                endcase
            end
            3'b001: begin // LH
                case (ex_mem_alu_result[1])
                    1'b0: read_data = {{16{dmem[addr][15]}}, dmem[addr][15:0]};
                    1'b1: read_data = {{16{dmem[addr][31]}}, dmem[addr][31:16]};
                    default: read_data = 32'h0;
                endcase
            end
            3'b010: read_data = dmem[addr];                                       // LW
            3'b100: begin // LBU
                case (ex_mem_alu_result[1:0])
                    2'b00: read_data = {24'h0, dmem[addr][7:0]};
                    2'b01: read_data = {24'h0, dmem[addr][15:8]};
                    2'b10: read_data = {24'h0, dmem[addr][23:16]};
                    2'b11: read_data = {24'h0, dmem[addr][31:24]};
                    default: read_data = 32'h0;
                endcase
            end
            3'b101: begin // LHU
                case (ex_mem_alu_result[1])
                    1'b0: read_data = {16'h0, dmem[addr][15:0]};
                    1'b1: read_data = {16'h0, dmem[addr][31:16]};
                    default: read_data = 32'h0;
                endcase
            end
            default: read_data = dmem[addr];
        endcase
    end

    // MEM/WB pipeline register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_wb_pc          <= 32'h0;
            mem_wb_alu_result  <= 32'h0;
            mem_wb_read_data   <= 32'h0;
            mem_wb_rd          <= 5'h0;
            mem_wb_reg_we      <= 1'b0;
            mem_wb_mem_to_reg  <= 1'b0;
            mem_wb_result_sel  <= 2'b00;
        end else begin
            mem_wb_pc          <= ex_mem_pc;
            mem_wb_alu_result  <= ex_mem_alu_result;
            mem_wb_read_data   <= read_data;
            mem_wb_rd          <= ex_mem_rd;
            mem_wb_reg_we      <= ex_mem_reg_we;
            mem_wb_mem_to_reg  <= ex_mem_mem_to_reg;
            mem_wb_result_sel  <= ex_mem_result_sel;
        end
    end

endmodule