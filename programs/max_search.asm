# ==============================================================================
# Program: max_search.asm
# Description: Finds the maximum element in a 6-element array:
#              {3, 17, 5, 42, 8, 23}
# Expected Result: max = 42 (0x2A) in $s0 ($16) and mem[6] (byte address 0x18)
# ==============================================================================

# Step 1: Initialize array in data memory
addi $t2, $0, 3         # 0x00: $t2 ($10) = 3
sw   $t2, 0($0)         # 0x04: mem[0] = 3
addi $t2, $0, 17        # 0x08: $t2 ($10) = 17
sw   $t2, 4($0)         # 0x0C: mem[1] = 17
addi $t2, $0, 5         # 0x10: $t2 ($10) = 5
sw   $t2, 8($0)         # 0x14: mem[2] = 5
addi $t2, $0, 42        # 0x18: $t2 ($10) = 42
sw   $t2, 12($0)        # 0x1C: mem[3] = 42
addi $t2, $0, 8         # 0x20: $t2 ($10) = 8
sw   $t2, 16($0)        # 0x24: mem[4] = 8
addi $t2, $0, 23        # 0x28: $t2 ($10) = 23
sw   $t2, 20($0)        # 0x2C: mem[5] = 23

# Step 2: Initialize maximum with first element
lw   $s0, 0($0)         # 0x30: $s0 ($16) = max = mem[0] = 3
addi $t0, $0, 4         # 0x34: $t0 ($8)  = i = 4 (byte offset of 2nd element)
addi $t1, $0, 24        # 0x38: $t1 ($9)  = limit = 24 (6 elements * 4 bytes)

# Step 3: Loop and compare
loop:
beq  $t0, $t1, 6        # 0x3C: if i == limit, branch to done (offset 6 -> word 22, 0x58)
lw   $t2, 0($t0)        # 0x40: $t2 ($10) = current = mem[i]
slt  $t3, $s0, $t2      # 0x44: $t3 ($11) = (max < current) ? 1 : 0
beq  $t3, $0, 1         # 0x48: if not (max < current), skip update (offset 1 -> word 20, 0x50)
add  $s0, $0, $t2       # 0x4C: max = current

not_max:
addi $t0, $t0, 4        # 0x50: i = i + 4
j    15                 # 0x54: jump back to loop (word 15, addr 0x3C)

# Step 4: Store final maximum
done:
sw   $s0, 24($0)        # 0x58: store max (42) to mem[6] (byte address 24)
