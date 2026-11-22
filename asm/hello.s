# hello.s — the smallest useful RISC-V Linux program.
# Writes a string to stdout and exits. No libc, no start files:
# we talk to the kernel with raw syscalls (`ecall`).
#
# riscv64 Linux syscall ABI:
#   a7 = syscall number
#   a0–a6 = arguments
#   ecall
#   a0 = return value (or -errno)
#
# Syscall numbers (riscv64 — these differ from x86_64):
#   write = 64, exit = 93

        .text
        .global _start

_start:
        # write(1, msg, len)
        li      a7, 64              # SYS_write
        li      a0, 1               # fd = stdout
        la      a1, msg             # buf
        la      a2, msg_end
        sub     a2, a2, a1          # count = msg_end - msg
        ecall

        # exit(0)
        li      a7, 93              # SYS_exit
        li      a0, 0               # status
        ecall

        .section .rodata
msg:
        .ascii  "Hello, RISC-V\n"
msg_end:
