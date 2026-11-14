# ==============================================================================
# Comprehensive MIPS Test Program (test_full.asm)
#
# Tests all Phase I instructions:
#   - ADDI (positive & negative immediate sign extension)
#   - ADD  (positive + positive, positive + negative)
#   - SUB  (positive result, negative result)
#   - AND  (bitwise logic)
#   - OR   (bitwise logic)
#   - SLT  (signed comparison: pos < pos, pos > pos, neg < pos, pos > neg)
#   - SW   (Store Word across multiple word addresses: 0, 4, 8, 12)
#   - LW   (Load Word from multiple word addresses: 0, 4, 8, 12)
# ==============================================================================

# 1. ADDI operations
addi $t0, $0, 20      # 0x20080014 : $t0 ($8)  = 20
addi $t1, $0, 5       # 0x20090005 : $t1 ($9)  = 5
addi $t2, $0, -10     # 0x200AFFF6 : $t2 ($10) = -10 (sign-extended 0xFFFFFFF6)

# 2. R-Type ADD operations
add  $t3, $t0, $t1    # 0x01095820 : $t3 ($11) = 20 + 5 = 25
add  $t4, $t0, $t2    # 0x010A6020 : $t4 ($12) = 20 + (-10) = 10

# 3. R-Type SUB operations
sub  $t5, $t0, $t1    # 0x01096822 : $t5 ($13) = 20 - 5 = 15
sub  $t6, $t1, $t0    # 0x01287022 : $t6 ($14) = 5 - 20 = -15 (0xFFFFFFF1)

# 4. R-Type AND operation
and  $t7, $t0, $t1    # 0x01097824 : $t7 ($15) = 20 & 5 (0x14 & 0x05) = 4

# 5. R-Type OR operation
or   $s0, $t0, $t1    # 0x01098025 : $s0 ($16) = 20 | 5 (0x14 | 0x05) = 21

# 6. R-Type SLT (Set Less Than - Signed) operations
slt  $s1, $t1, $t0    # 0x0128882A : $s1 ($17) = (5 < 20) = 1
slt  $s2, $t0, $t1    # 0x0109902A : $s2 ($18) = (20 < 5) = 0
slt  $s3, $t2, $t0    # 0x0148982A : $s3 ($19) = (-10 < 20) = 1 (signed!)
slt  $s4, $t0, $t2    # 0x010AA02A : $s4 ($20) = (20 < -10) = 0 (signed!)

# 7. Memory Operations: Store Word (SW)
sw   $t3, 0($0)       # 0xAC0B0000 : mem[0] = $t3 (25)
sw   $t5, 4($0)       # 0xAC0D0004 : mem[1] = $t5 (15)
sw   $t6, 8($0)       # 0xAC0E0008 : mem[2] = $t6 (-15)
sw   $s1, 12($0)      # 0xAC11000C : mem[3] = $s1 (1)

# 8. Memory Operations: Load Word (LW)
lw   $s5, 0($0)       # 0x8C150000 : $s5 ($21) = mem[0] (25)
lw   $s6, 4($0)       # 0x8C160004 : $s6 ($22) = mem[1] (15)
lw   $s7, 8($0)       # 0x8C170008 : $s7 ($23) = mem[2] (-15)
lw   $t8, 12($0)      # 0x8C18000C : $t8 ($24) = mem[3] (1)
