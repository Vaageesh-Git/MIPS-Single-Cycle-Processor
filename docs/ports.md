# MIPS Single-Cycle Processor — Port & Interface Specification

> **Convention:** Every Verilog file name **must** match its module name (e.g. `rtl/pc.v` defines `module pc`, `rtl/regfile.v` defines `module regfile`). Target standard is **Verilog-2001** (Icarus Verilog / Vivado compatible).

---

## 1. Module Ports

### `pc` (`rtl/pc.v`) — Member A
Synchronous reset to `0` on `posedge clk`; loads `next_pc` on `posedge clk`; `pc_plus4 = pc + 32'd4`.

| Direction | Port | Width | Description |
| :--- | :--- | :--- | :--- |
| `input` | `clk` | `1` | System clock |
| `input` | `reset` | `1` | Synchronous active-high reset (`pc <= 32'b0`) |
| `input` | `next_pc` | `31:0` | Next program counter value |
| `output` | `pc` | `31:0` | Current program counter |
| `output` | `pc_plus4` | `31:0` | `pc + 4` (combinational) |

### `imem` (`rtl/imem.v`) — Member A
Read-only 64-word instruction memory (`reg [31:0] mem [0:63]`). Combinational read indexed by `addr[31:2]`. Parameter: `INIT_FILE = "programs/test.hex"`.

| Direction | Port | Width | Description |
| :--- | :--- | :--- | :--- |
| `input` | `addr` | `31:0` | Byte address (`pc`) |
| `output` | `instr` | `31:0` | Fetched 32-bit instruction |

### `regfile` (`rtl/regfile.v`)
32 × 32-bit register file. Writes on `posedge clk` when `we3 == 1` (except `$0`, which is hardwired to `0`). Reads are combinational.

| Direction | Port | Width | Description |
| :--- | :--- | :--- | :--- |
| `input` | `clk` | `1` | System clock |
| `input` | `we3` | `1` | Write enable (`reg_write`) |
| `input` | `ra1` | `4:0` | Read address 1 (`rs`) |
| `input` | `ra2` | `4:0` | Read address 2 (`rt`) |
| `input` | `wa3` | `4:0` | Write address (`rt` or `rd`) |
| `input` | `wd3` | `31:0` | Write data |
| `output` | `rd1` | `31:0` | Read data 1 |
| `output` | `rd2` | `31:0` | Read data 2 |

### `sign_extend` (`rtl/sign_extend.v`)
Sign-extends 16-bit immediate to 32 bits.

| Direction | Port | Width | Description |
| :--- | :--- | :--- | :--- |
| `input` | `in` | `15:0` | 16-bit immediate |
| `output` | `out` | `31:0` | 32-bit sign-extended value |

### `mux2` (`rtl/mux2.v`)
Parameterized 2-to-1 multiplexer (`parameter W = 32`). Selects `d1` when `sel == 1`, else `d0`.

| Direction | Port | Width | Description |
| :--- | :--- | :--- | :--- |
| `input` | `d0` | `W-1:0` | Input selected when `sel == 0` |
| `input` | `d1` | `W-1:0` | Input selected when `sel == 1` |
| `input` | `sel` | `1` | Select signal |
| `output` | `y` | `W-1:0` | Selected output |

### `alu` (`rtl/alu.v`)
Combinational 32-bit ALU.

| Direction | Port | Width | Description |
| :--- | :--- | :--- | :--- |
| `input` | `a` | `31:0` | Operand A |
| `input` | `b` | `31:0` | Operand B |
| `input` | `alu_ctrl` | `2:0` | ALU operation select |
| `output` | `result` | `31:0` | ALU result |
| `output` | `zero` | `1` | High (`1`) when `result == 32'b0` |

### `alu_decoder` (`rtl/alu_decoder.v`)
> **Status:** PROPOSED — confirm with Member C

| Direction | Port | Width | Description |
| :--- | :--- | :--- | :--- |
| `input` | `alu_op` | `1:0` | ALUOp from `main_decoder` |
| `input` | `funct` | `5:0` | `instr[5:0]` |
| `output` | `alu_ctrl` | `2:0` | Control code to `alu` |

### `main_decoder` (`rtl/main_decoder.v`)
> **Status:** PROPOSED — confirm with Member C

| Direction | Port | Width | Description |
| :--- | :--- | :--- | :--- |
| `input` | `opcode` | `5:0` | `instr[31:26]` |
| `output` | `reg_write` | `1` | Register file write enable |
| `output` | `reg_dst` | `1` | Write reg select (`0=rt`, `1=rd`) |
| `output` | `alu_src` | `1` | ALU B select (`0=rd2`, `1=sign_imm`) |
| `output` | `mem_write` | `1` | Data memory write enable |
| `output` | `mem_to_reg` | `1` | Write-back select (`0=alu_result`, `1=dmem rd`) |
| `output` | `branch` | `1` | Branch control (used in Phase II) |
| `output` | `jump` | `1` | Jump control (used in Phase II) |
| `output` | `alu_op` | `1:0` | ALUOp to `alu_decoder` |

### `control_unit` (`rtl/control_unit.v`)
Top-level control wrapper connecting `main_decoder` and `alu_decoder`.
> **Status:** PROPOSED — confirm with Member C

| Direction | Port | Width | Description |
| :--- | :--- | :--- | :--- |
| `input` | `opcode` | `5:0` | `instr[31:26]` |
| `input` | `funct` | `5:0` | `instr[5:0]` |
| `output` | `reg_write` | `1` | Register file write enable |
| `output` | `reg_dst` | `1` | Write reg select (`0=rt`, `1=rd`) |
| `output` | `alu_src` | `1` | ALU B select (`0=rd2`, `1=sign_imm`) |
| `output` | `mem_write` | `1` | Data memory write enable |
| `output` | `mem_to_reg` | `1` | Write-back select (`0=alu_result`, `1=dmem rd`) |
| `output` | `branch` | `1` | Branch control (Phase II) |
| `output` | `jump` | `1` | Jump control (Phase II) |
| `output` | `alu_ctrl` | `2:0` | Control code to `alu` |

### `dmem` (`rtl/dmem.v`)
Data memory. Writes on `posedge clk` when `we == 1`; combinational read (`addr` is byte address, indexed by word).

| Direction | Port | Width | Description |
| :--- | :--- | :--- | :--- |
| `input` | `clk` | `1` | System clock |
| `input` | `we` | `1` | Write enable (`mem_write`) |
| `input` | `addr` | `31:0` | Byte address (`alu_result`) |
| `input` | `wd` | `31:0` | Write data (`rd2`) |
| `output` | `rd` | `31:0` | Read data |

### `mips_cpu` (`rtl/mips_cpu.v`) — Member A
Top-level single-cycle CPU. *(Add debug outputs only if needed later, and document them here first.)*

| Direction | Port | Width | Description |
| :--- | :--- | :--- | :--- |
| `input` | `clk` | `1` | System clock |
| `input` | `reset` | `1` | Synchronous active-high reset |

---

## 2. Instruction Field Layout (32-bit MIPS)

- **R-Type:** `[31:26] opcode` | `[25:21] rs` | `[20:16] rt` | `[15:11] rd` | `[10:6] shamt` | `[5:0] funct`
- **I-Type:** `[31:26] opcode` | `[25:21] rs` | `[20:16] rt` | `[15:0] imm`
- **J-Type:** `[31:26] opcode` | `[25:0] addr` *(Phase II)*

---

## 3. ALU Control Encoding
> **Status:** PROPOSED — confirm with Member C

| `alu_ctrl[2:0]` | Operation | Function |
| :--- | :--- | :--- |
| `3'b000` | `AND` | `a & b` |
| `3'b001` | `OR` | `a \| b` |
| `3'b010` | `ADD` | `a + b` |
| `3'b110` | `SUB` | `a - b` |
| `3'b111` | `SLT` | `($signed(a) < $signed(b)) ? 32'd1 : 32'd0` |

---

## 4. Supported Instructions (Opcode & Funct Table)

### Phase I (Current)
| Instruction | Type | `opcode` (6-bit) | `funct` (6-bit) | `alu_op` | `alu_ctrl` |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ADD` | R | `6'b000000` (`0x00`) | `6'b100000` (`0x20`) | `2'b10` | `3'b010` |
| `SUB` | R | `6'b000000` (`0x00`) | `6'b100010` (`0x22`) | `2'b10` | `3'b110` |
| `AND` | R | `6'b000000` (`0x00`) | `6'b100100` (`0x24`) | `2'b10` | `3'b000` |
| `OR` | R | `6'b000000` (`0x00`) | `6'b100101` (`0x25`) | `2'b10` | `3'b001` |
| `SLT` | R | `6'b000000` (`0x00`) | `6'b101010` (`0x2A`) | `2'b10` | `3'b111` |
| `LW` | I | `6'b100011` (`0x23`) | `—` | `2'b00` | `3'b010` |
| `SW` | I | `6'b101011` (`0x2B`) | `—` | `2'b00` | `3'b010` |
| `ADDI` | I | `6'b001000` (`0x08`) | `—` | `2'b00` | `3'b010` |

### Phase II (Reserved Ports/Signals Ready)
| Instruction | Type | `opcode` (6-bit) | `funct` (6-bit) | `alu_op` | `alu_ctrl` |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `BEQ` | I | `6'b000100` (`0x04`) | `—` | `2'b01` | `3'b110` |
| `J` | J | `6'b000010` (`0x02`) | `—` | `—` | `—` |

