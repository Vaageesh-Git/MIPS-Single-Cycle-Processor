# Phase I smoke test program (matches programs/test.hex)
addi $t0, $0, 5      # 0x20080005 : $t0 ($8)  = 5
addi $t1, $0, 7      # 0x20090007 : $t1 ($9)  = 7
add  $t2, $t0, $t1   # 0x01095020 : $t2 ($10) = $t0 + $t1 = 12
sw   $t2, 0($0)      # 0xAC0A0000 : mem[0]    = $t2 (12)
lw   $t3, 0($0)      # 0x8C0B0000 : $t3 ($11) = mem[0] (12)

