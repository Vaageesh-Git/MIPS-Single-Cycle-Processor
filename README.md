# 32-bit Single-Cycle MIPS Processor

A 32-bit single-cycle MIPS processor written in Verilog-2001 and simulated with Icarus Verilog. Phase I supports R-type (`ADD`, `SUB`, `AND`, `OR`, `SLT`), `ADDI`, `LW`, and `SW`, with module ports and control signals already wired so Phase II (`BEQ`, `J`) can be added cleanly.

## Folder Layout

```text
.
├── docs/       # Port specifications and architecture documentation
├── programs/   # Assembly (.asm) and machine code (.hex) test programs
├── rtl/        # Synthesizable Verilog-2001 RTL modules
└── tb/         # Simulation testbenches
```

## Running the Fetch Testbench

Run from the repository root so `rtl/imem.v` resolves `programs/test.hex`:

```bash
iverilog -o sim_fetch tb/tb_fetch.v rtl/pc.v rtl/imem.v && vvp sim_fetch
```

## Team Members & Files

| Role | Name | Assigned Files |
| :--- | :--- | :--- |
| Member A (Fetch + Top-Level) | | `docs/ports.md`, `rtl/pc.v`, `rtl/imem.v`, `rtl/mips_cpu.v`, `programs/test.hex`, `programs/test.asm`, `tb/tb_fetch.v` |
| Member B (Datapath) | | `rtl/regfile.v`, `rtl/sign_extend.v`, `rtl/mux2.v`, `rtl/dmem.v` |
| Member C (ALU + Control) | | `rtl/alu.v`, `rtl/alu_decoder.v`, `rtl/main_decoder.v`, `rtl/control_unit.v` |
| Member D (Verification) | | `tb/tb_alu.v`, `tb/tb_mips_cpu.v`, `programs/test_full.asm`, `programs/test.hex` |

