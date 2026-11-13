# Member C Notes: Control Unit & ALU Architecture

---

## 1. Truth Tables

### Main Decoder Truth Table

| Instruction | Opcode (`[31:26]`) | `reg_write` | `reg_dst` | `alu_src` | `mem_write` | `mem_to_reg` | `branch` | `jump` | `alu_op[1:0]` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **R-Type** | `6'b000000` | 1 | 1 | 0 | 0 | 0 | 0 | 0 | `2'b10` |
| **LW** | `6'b100011` | 1 | 0 | 1 | 0 | 1 | 0 | 0 | `2'b00` |
| **SW** | `6'b101011` | 0 | 0* | 1 | 1 | 0* | 0 | 0 | `2'b00` |
| **ADDI** | `6'b001000` | 1 | 0 | 1 | 0 | 0 | 0 | 0 | `2'b00` |
| *BEQ (Phase II)* | `6'b000100` | 0 | 0 | 0 | 0 | 0 | 1 | 0 | `2'b01` |
| *J (Phase II)* | `6'b000010` | 0 | 0 | 0 | 0 | 0 | 0 | 1 | `2'b00` |
| **Default (NOP)**| *Others* | 0 | 0 | 0 | 0 | 0 | 0 | 0 | `2'b00` |

*\*Note: For `SW`, don't-care signals (`reg_dst`, `mem_to_reg`) are tied to `0` instead of `X` to guarantee deterministic and clean simulation waveforms.*

---

### ALU Decoder Truth Table

| `alu_op[1:0]` | `funct[5:0]` | Target Operation | `alu_ctrl[2:0]` | ALU Function |
| :---: | :---: | :--- | :---: | :--- |
| `2'b00` | `6'bxxxxxx` | Memory / Immediate Address Calc (`LW`, `SW`, `ADDI`) | `3'b010` | `ADD` |
| `2'b01` | `6'bxxxxxx` | Branch Condition (`BEQ` - Phase II) | `3'b110` | `SUB` |
| `2'b10` | `6'b100000` | `add` | `3'b010` | `ADD` |
| `2'b10` | `6'b100010` | `sub` | `3'b110` | `SUB` |
| `2'b10` | `6'b100100` | `and` | `3'b000` | `AND` |
| `2'b10` | `6'b100101` | `or` | `3'b001` | `OR` |
| `2'b10` | `6'b101010` | `slt` | `3'b111` | `SLT` (signed) |
| *Default* | *Others* | Unrecognized function | `3'b010` | `ADD` (Safe default) |

---

## 2. Proposed Solution Write-up (IEEE Report Section)

> The control subsystem orchestrates instruction execution by translating machine-level instructions into coordinated datapath control vectors. A hierarchical design divides instruction decoding into two dedicated modules: the main decoder and the ALU decoder. The main decoder evaluates the 6-bit opcode to establish fundamental datapath steering signals, multiplexer selections, memory strobes, and a 2-bit intermediate operation code (`alu_op`). For R-type instructions, the secondary ALU decoder interprets the 6-bit function field (`funct`) to derive the 3-bit ALU operation control (`alu_ctrl`). The execution engine centers on a combinational 32-bit arithmetic logic unit capable of computing bitwise conjunction, bitwise disjunction, signed addition, subtraction, and signed set-less-than comparisons, alongside zero-flag generation. This decoupled architecture simplifies datapath timing, eliminates combinational latches, and ensures seamless extensibility for subsequent branching and jump mechanisms.

---

## 3. Video Presentation Talking Points (5 Key Highlights)

1. **Two-Level Modular Decoding:** Dividing the control unit into a `main_decoder` and `alu_decoder` simplifies combinational logic, cleanly isolating primary opcode decoding from R-type `funct` field resolution.
2. **Phase II Ready Interfaces:** All control lines—including `branch` and `jump`—are already declared, routed, and held at inactive defaults, ensuring zero architectural disruption when adding control flow instructions in Phase II.
3. **Clean Simulation Waveforms:** Don't-care conditions during instructions like Store Word (`SW`) are explicitly mapped to `0` rather than `X`, avoiding uninitialized state propagation and keeping simulation traces readable.
4. **Signed Arithmetic & SLT Accuracy:** The ALU implements Set-Less-Than using explicit signed casting (`$signed(a) < $signed(b)`), guaranteeing correct mathematical evaluation when comparing mixed negative and positive values.
5. **Robust Combinational Design:** Every decoder and ALU path contains full case coverage and explicit default assignments, eliminating synthesis latches and maintaining strict Verilog-2001 compatibility for both Icarus Verilog and FPGA synthesis tools.

