# ==============================================================================
# Program: factorial.asm
# Description: Computes 5! = 120 (0x78) using nested repeated addition loop
#              (since single-cycle MIPS subset has no hardware multiplier).
# Expected Result: 5! = 120 in $s0 ($16) and mem[0] (byte address 0x00)
# ==============================================================================

# Step 1: Initialize
addi $s0, $0, 1         # 0x00: $s0 ($16) = result = 1
addi $s1, $0, 5         # 0x04: $s1 ($17) = n = 5
addi $s2, $0, 1         # 0x08: $s2 ($18) = constant 1

# Step 2: Outer loop (decrements n down to 1)
outer_loop:
beq  $s1, $s2, 9        # 0x0C: if n == 1, branch to done (offset 9 -> word 13, 0x34)
addi $t0, $0, 0         # 0x10: $t0 ($8)  = product accumulator = 0
add  $t1, $0, $s1       # 0x14: $t1 ($9)  = count = n

# Step 3: Inner loop (repeatedly adds result to product n times)
inner_loop:
beq  $t1, $0, 3         # 0x18: if count == 0, branch to inner_done (offset 3 -> word 10, 0x28)
add  $t0, $t0, $s0      # 0x1C: product = product + result
sub  $t1, $t1, $s2      # 0x20: count = count - 1
j    6                  # 0x24: jump back to inner_loop (word 6, addr 0x18)

# Step 4: Inner loop done, update result and decrement n
inner_done:
add  $s0, $0, $t0       # 0x28: result = product
sub  $s1, $s1, $s2      # 0x2C: n = n - 1
j    3                  # 0x30: jump back to outer_loop (word 3, addr 0x0C)

# Step 5: Finished
done:
sw   $s0, 0($0)         # 0x34: store 5! = 120 into mem[0]
