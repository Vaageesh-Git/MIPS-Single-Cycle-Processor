# Verification & Testbench Architecture

---

## 1. Verification Strategy & Test Coverage

The verification suite guarantees full functional correctness of the single-cycle MIPS architecture through automated, self-checking testbenches with assertion logs and VCD waveform generation.

### A. ALU Verification Matrix (`tb/tb_alu.v`)
Exhaustive verification of the 32-bit Arithmetic Logic Unit across all control codes, edge cases, zero flags, and signed arithmetic behavior:

| Test ID | Operation | Control Code (`alu_ctrl`) | Operand A | Operand B | Expected Result | Zero Flag | Verification Focus |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **T1–T4** | `ADD` | `3'b010` | Positive / Negative | Positive / Negative | $A + B$ | `0` | Signed addition correctness across signs |
| **T5** | `ADD` | `3'b010` | `+42` | `-42` | `0` | **`1`** | Zero-flag assertion on cancellation |
| **T6–T7** | `ADD` | `3'b010` | `0x7FFFFFFF` / `-1` | `+1` | `0x80000000` / `0` | `0` / **`1`** | Overflow boundary wrap-around |
| **T8–T13** | `SUB` | `3'b110` | Mixed Signs | Mixed Signs | $A - B$ | `0` | Positive and negative difference checks |
| **T14–T15** | `SUB` | `3'b110` | `100` / `-45` | `100` / `-45` | `0` | **`1`** | Identity cancellation zero-flag check |
| **T16–T19** | `AND` | `3'b000` | Hex patterns | Hex patterns | $A \ \& \ B$ | `0` / **`1`** | Bitwise logic & disjoint zero detection |
| **T20–T23** | `OR` | `3'b001` | Hex patterns | Hex patterns | $A \ \| \ B$ | `0` / **`1`** | Bitwise disjunction with active/zero masks |
| **T24–T26** | `SLT` | `3'b111` | Pos / Pos | Pos / Pos | `1` / `0` | `0` / **`1`** | Unsigned-compatible baseline comparison |
| **T27–T28** | `SLT` | `3'b111` | `-5` / `+5` | `+5` / `-5` | **`1`** / **`0`** | `0` / **`1`** | **Signed distinction** (Negative < Positive) |
| **T29–T31** | `SLT` | `3'b111` | Negative | Negative | `1` / `0` | `0` / **`1`** | Negative magnitude comparison ($-30 < -10$) |
| **T32–T33** | `SLT` | `3'b111` | `0x80000000` | `0x7FFFFFFF` | **`1`** / **`0`** | `0` / **`1`** | Extremum: Min Signed Negative vs Max Positive |
| **T34–T36** | `DEFAULT`| `3'b011..101`| Arbitrary | Arbitrary | `0` | **`1`** | Safe default fallback for undefined control lines |

---

### B. Top-Level CPU Execution Flow (`tb/tb_mips_cpu.v`)
Verification of synchronous fetch, decode, datapath steering, memory load/store, and register write-back.

#### Program Execution Table (`programs/test.hex`)
| Cycle | Time (ns) | PC | Instruction | Mnemonic | ALU Operands & Res | Control Vector `{RegWr, RegDst, AluSrc, MemWr, MemToReg}` | Architectural State Change |
| :---: | :---: | :---: | :---: | :--- | :---: | :---: | :--- |
| **Reset** | $0-10$ | `0x00` | — | Active Reset | — | `{0, 0, 0, 0, 0}` | `pc <= 0`, registers cleared |
| **C0** | $10-20$ | `0x00` | `0x20080005` | `addi $t0, $0, 5` | `0 + 5 = 5` | `{1, 0, 1, 0, 0}` | `regs[8] ($t0) <= 5` |
| **C1** | $20-30$ | `0x04` | `0x20090007` | `addi $t1, $0, 7` | `0 + 7 = 7` | `{1, 0, 1, 0, 0}` | `regs[9] ($t1) <= 7` |
| **C2** | $30-40$ | `0x08` | `0x01095020` | `add $t2, $t0, $t1` | `5 + 7 = 12` | `{1, 1, 0, 0, 0}` | `regs[10] ($t2) <= 12` |
| **C3** | $40-50$ | `0x0C` | `0xAC0A0000` | `sw $t2, 0($0)` | `0 + 0 = 0` | `{0, 0, 1, 1, 0}` | `dmem[0] <= 12` |
| **C4** | $50-60$ | `0x10` | `0x8C0B0000` | `lw $t3, 0($0)` | `0 + 0 = 0` | `{1, 0, 1, 0, 1}` | `regs[11] ($t3) <= dmem[0] (12)` |
| **C5** | $60-70$ | `0x14` | `0x00000000` | `nop` | `0 + 0 = 0` | `{0, 0, 0, 0, 0}` | Program completed, stable state |

#### Architectural Assertion Verification Summary
```text
[PASS REG] $t0          ($8) = 00000005 (5)  | Expected: 5
[PASS REG] $t1          ($9) = 00000007 (7)  | Expected: 7
[PASS REG] $t2 (add)    ($10) = 0000000c (12) | Expected: 12
[PASS MEM] dmem[0] (sw) [0]   = 0000000c (12) | Expected: 12
[PASS REG] $t3 (lw)     ($11) = 0000000c (12) | Expected: 12
[PASS REG] $0 (zero)    ($0)  = 00000000 (0)  | Hardwired Zero Verified
RESULT: ALL CHECKS PASSED (0 Errors)
```

---


