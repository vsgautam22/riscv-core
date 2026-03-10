import struct

def encode_i(opcode, rd, funct3, rs1, imm):
    imm = imm & 0xFFF
    return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_r(opcode, rd, funct3, rs1, rs2, funct7):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_s(opcode, funct3, rs1, rs2, imm):
    imm = imm & 0xFFF
    imm_11_5 = (imm >> 5) & 0x7F
    imm_4_0  = imm & 0x1F
    return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | opcode

def encode_b(opcode, funct3, rs1, rs2, imm):
    imm = imm & 0x1FFE
    b12   = (imm >> 12) & 1
    b11   = (imm >> 11) & 1
    b10_5 = (imm >> 5)  & 0x3F
    b4_1  = (imm >> 1)  & 0xF
    return (b12 << 31) | (b10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (b4_1 << 8) | (b11 << 7) | opcode

def encode_u(opcode, rd, imm):
    return ((imm & 0xFFFFF) << 12) | (rd << 7) | opcode

def encode_j(opcode, rd, imm):
    imm = imm & 0x1FFFFE
    b20    = (imm >> 20) & 1
    b10_1  = (imm >> 1)  & 0x3FF
    b11    = (imm >> 11) & 1
    b19_12 = (imm >> 12) & 0xFF
    return (b20 << 31) | (b10_1 << 21) | (b11 << 20) | (b19_12 << 12) | (rd << 7) | opcode

NOP    = encode_i(0x13, 0, 0, 0, 0)   # addi x0, x0, 0
EBREAK = 0x00100073

instrs = [
    # Basic arithmetic
    encode_i(0x13, 1, 0, 0,  5),    # 00: addi x1, x0, 5     -> x1=5
    encode_i(0x13, 2, 0, 0,  3),    # 04: addi x2, x0, 3     -> x2=3
    encode_r(0x33, 3, 0, 1, 2, 0),  # 08: add  x3, x1, x2    -> x3=8
    encode_r(0x33, 4, 0, 1, 2, 0x20), # 0C: sub x4, x1, x2   -> x4=2
    encode_r(0x33, 5, 4, 1, 2, 0),  # 10: xor  x5, x1, x2    -> x5=6
    encode_r(0x33, 6, 6, 1, 2, 0),  # 14: or   x6, x1, x2    -> x6=7
    encode_r(0x33, 7, 7, 1, 2, 0),  # 18: and  x7, x1, x2    -> x7=1

    # Immediate arithmetic
    encode_i(0x13, 8, 0, 1, 10),    # 1C: addi x8, x1, 10    -> x8=15
    encode_i(0x13, 9, 4, 0, 0xFF),  # 20: xori x9, x0, 0xFF  -> x9=255

    # Store and load
    encode_i(0x13, 10, 0, 0, 0),    # 24: addi x10, x0, 0    -> x10=0 (base addr)
    encode_s(0x23, 2, 10, 3, 0),    # 28: sw   x3, 0(x10)    -> mem[0]=8
    encode_i(0x03, 11, 2, 10, 0),   # 2C: lw   x11, 0(x10)   -> x11=8

    # Branch not taken
    encode_b(0x63, 0, 1, 2, 8),     # 30: beq  x1, x2, +8    -> not taken (5!=3)

    # Branch taken — jump over next instruction
    encode_i(0x13, 12, 0, 0, 1),    # 34: addi x12, x0, 1    -> x12=1
    encode_b(0x63, 0, 12, 12, 8),   # 38: beq  x12, x12, +8  -> taken, skip next
    encode_i(0x13, 13, 0, 0, 0xFF), # 3C: addi x13, x0, 0xFF -> SKIPPED
    encode_i(0x13, 13, 0, 0, 0xAA), # 40: addi x13, x0, 0xAA -> x13=0xAA

    # JAL
    encode_j(0x6F, 14, 8),          # 44: jal  x14, +8       -> x14=0x48, PC=0x4C
    encode_i(0x13, 15, 0, 0, 0xBB), # 48: addi x15, x0, 0xBB -> SKIPPED
    NOP,                             # 4C: NOP (jump lands here)

    EBREAK,                          # 50: ebreak
]

# Pad to 256 words
while len(instrs) < 256:
    instrs.append(NOP)

with open("imem.hex", "w") as f:
    for instr in instrs:
        f.write(f"{instr:08x}\n")

print(f"Generated imem.hex with {len(instrs)} instructions")
print("\nKey expected register values after execution:")
print("  x1  = 5")
print("  x2  = 3")
print("  x3  = 8   (5+3)")
print("  x4  = 2   (5-3)")
print("  x5  = 6   (5^3)")
print("  x6  = 7   (5|3)")
print("  x7  = 1   (5&3)")
print("  x8  = 15  (5+10)")
print("  x11 = 8   (loaded from mem)")
print("  x12 = 1")
print("  x13 = 0xAA (branch taken, 0xFF skipped)")
print("  x15 = 0   (JAL skipped 0xBB write)")