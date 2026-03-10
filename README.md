# RISC-V RV32I 5-Stage Pipelined Core

A fully functional RV32I pipelined processor implemented in Verilog, developed as Project 2 of a VLSI portfolio.

## Architecture

5-stage pipeline: **IF → ID → EX → MEM → WB**

| Module | Description |
|---|---|
| `if_stage.v` | Instruction fetch, PC logic, instruction memory (1KB) |
| `id_stage.v` | Decode, immediate generation, control signals, regfile read |
| `ex_stage.v` | ALU, forwarding muxes, branch/jump resolution |
| `mem_stage.v` | Data memory (1KB), byte/halfword/word load-store |
| `hazard_unit.v` | EX-EX/MEM-EX forwarding, load-use stall, branch flush |
| `regfile.v` | 32×32 register file, async read with WB write-through bypass |
| `alu.v` | ADD/SUB/AND/OR/XOR/SLL/SRL/SRA/SLT/SLTU/LUI |
| `riscv_top.v` | Top-level interconnect |

## Hazard Handling

- **EX-EX forwarding** — registered ALU result fed back to forwarding mux
- **MEM-EX forwarding** — MEM/WB result forwarded to EX stage
- **WB→ID bypass** — regfile write-through resolves same-cycle write-read conflict
- **Load-use stall** — 1-cycle bubble inserted on load-followed-by-use
- **Branch/jump flush** — IF/ID pipeline register flushed on taken branch or jump

## Simulation Results

**Simulator:** Icarus Verilog 12.0  
**Result: 14/14 tests PASSED**

| Category | Tests | Result |
|---|---|---|
| Arithmetic (ADD/SUB/XOR/OR/AND) | 7 | ✅ PASS |
| Immediate (ADDI/XORI) | 2 | ✅ PASS |
| Load/Store (SW/LW) | 2 | ✅ PASS |
| Branch (BEQ taken/not taken) | 2 | ✅ PASS |
| Jump (JAL) | 1 | ✅ PASS |

## Waveform

Pipeline signals verified in GTKWave — forwarding selects (`fwd_a`, `fwd_b`), flush pulse at branch, PC progression, and load-store data path all confirmed correct.

## Tools

- RTL: Verilog-2001
- Simulation: Icarus Verilog + GTKWave
- Development: WSL2 Ubuntu 24.04

## Project Structure
```
riscv_core/
├── rtl/          # RTL source files
├── tb/           # Testbench, hex generator, instruction memory
└── sim/          # Simulation outputs (VCD)
```

## Portfolio

Part of an FPGA/VLSI portfolio by Gautam Suresh (B.E. Electronics, VLSI Design & Technology, CIT Chennai).  
**Project 1:** [CRC Engine](https://github.com/vsgautam22/crc-engine) — RTL + formal verification (SymbiYosys) + OpenLane GDS (SKY130A)
