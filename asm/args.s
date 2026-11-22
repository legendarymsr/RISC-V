# args.s — dump argv as the kernel left it on the stack.
#
# When Linux enters `_start` (there is no `main` without libc), the
# stack looks like this (each slot is an 8-byte word on RV64):
#
#   sp + 0             argc
#   sp + 8             argv[0]  → program name (NUL-terminated)
#   sp + 16            argv[1]  → first argument, if any
#   ...
#   sp + 8*(argc+1)    NULL
#   then envp[], a NULL, and the auxiliary vector.
#
# We print each argv[i] on its own line.

        .text
        .global _start

        .equ    SYS_write, 64
        .equ    SYS_exit,  93

_start:
        ld      s0, 0(sp)           # s0 = argc
        addi    s1, sp, 8           # s1 = &argv[0]
        beqz    s0, done

loop:
        ld      a0, 0(s1)           # a0 = argv[i]
        call    puts
        addi    s1, s1, 8
        addi    s0, s0, -1
        bnez    s0, loop

done:
        li      a7, SYS_exit
        li      a0, 0
        ecall

# puts(a0=NUL-terminated string) — write it to stdout, then a newline.
# Does not call anyone else, so `ra` can stay as `_start` left it.
puts:
        mv      a1, a0              # buf
        mv      t0, a0
1:      lbu     t1, 0(t0)
        beqz    t1, 2f
        addi    t0, t0, 1
        j       1b
2:      sub     a2, t0, a1          # length
        li      a0, 1               # stdout
        li      a7, SYS_write
        ecall

        li      a0, 1
        la      a1, nl
        li      a2, 1
        li      a7, SYS_write
        ecall
        ret

        .section .rodata
nl:
        .ascii  "\n"
