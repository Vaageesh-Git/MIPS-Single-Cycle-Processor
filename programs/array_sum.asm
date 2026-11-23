# ==============================================================================
# Program: array_sum.asm
# Description: Computes the sum of a 5-element array: {3, 7, 2, 9, 4}
# Expected Result: sum = 25 (0x19) in $t2 ($10) and mem[5] (byte address 0x14)
# ==============================================================================

# Step 1: Initialize array in data memory
addi $t1, $0, 3         # 0x00: $t1 ($9) = 3
sw   $t1, 0($0)         # 0x04: mem[0] = 3
addi $t1, $0, 7         # 0x08: $t1 ($9) = 7
sw   $t1, 4($0)         # 0x0C: mem[1] = 7
addi $t1, $0, 2         # 0x10: $t1 ($9) = 2
sw   $t1, 8($0)         # 0x14: mem[2] = 2
addi $t1, $0, 9         # 0x18: $t1 ($9) = 9
sw   $t1, 12($0)        # 0x1C: mem[3] = 9
addi $t1, $0, 4         # 0x20: $t1 ($9) = 4
sw   $t1, 16($0)        # 0x24: mem[4] = 4

# Step 2: Initialize loop variables
addi $t2, $0, 0         # 0x28: $t2 ($10) = sum = 0
addi $t3, $0, 0         # 0x2C: $t3 ($11) = byte offset i = 0
addi $t4, $0, 20        # 0x30: $t4 ($12) = limit = 20 (5 words * 4 bytes)

# Step 3: Loop and accumulate
loop:
beq  $t3, $t4, 4        # 0x34: if i == limit, branch to done (offset 4 -> 0x48)
lw   $t5, 0($t3)        # 0x38: $t5 ($13) = mem[i]
add  $t2, $t2, $t5      # 0x3C: sum = sum + mem[i]
addi $t3, $t3, 4        # 0x40: i = i + 4
j    13                 # 0x44: jump back to loop (word 13, addr 0x34)

# Step 4: Store final result
done:
sw   $t2, 20($0)        # 0x48: store sum (25) to mem[5] (byte address 20)
