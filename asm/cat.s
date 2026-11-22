# cat.s — copy file contents to stdout with read(2) and write(2).
# No arguments: read stdin. Otherwise open each argument with openat(2)
# (the RISC-V/Linux way to open a path — there is no plain `open` syscall
# on this ABI) and copy that file.
#
# Syscall numbers (riscv64):
#   openat = 56, close = 57, read = 63, write = 64, exit = 93

        .text
        .global _start

        .equ    SYS_openat, 56
        .equ    SYS_close,  57
        .equ    SYS_read,   63
        .equ    SYS_write,  64
        .equ    SYS_exit,   93
        .equ    AT_FDCWD,   -100    # open relative to the cwd
        .equ    O_RDONLY,   0
        .equ    BUFSIZE,    4096

_start:
        ld      s0, 0(sp)           # argc
        addi    s1, sp, 8           # argv
        li      t0, 1
        beq     s0, t0, from_stdin  # argc == 1 → stdin only

        addi    s1, s1, 8           # skip argv[0]
        addi    s0, s0, -1

next_arg:
        beqz    s0, ok
        ld      a1, 0(s1)           # path
        call    open_path
        bltz    a0, fail            # a0 < 0 is -errno
        mv      s2, a0              # fd
        call    copy
        li      a7, SYS_close
        mv      a0, s2
        ecall
        addi    s1, s1, 8
        addi    s0, s0, -1
        j       next_arg

from_stdin:
        li      a0, 0               # stdin
        call    copy
ok:
        li      a7, SYS_exit
        li      a0, 0
        ecall

fail:
        li      a7, SYS_write
        li      a0, 2               # stderr
        la      a1, err
        la      a2, err_end
        sub     a2, a2, a1          # count = err_end - err
        ecall
        li      a7, SYS_exit
        li      a0, 1
        ecall

# open_path(a1=path) → a0 = fd, or -errno on failure.
open_path:
        li      a7, SYS_openat
        li      a0, AT_FDCWD
        li      a2, O_RDONLY
        li      a3, 0
        ecall
        ret

# copy(a0=fd) — read until EOF, write every byte to stdout.
# s3 holds the fd (callee-saved). Short writes are retried.
copy:
        addi    sp, sp, -16
        sd      ra, 8(sp)
        sd      s3, 0(sp)
        mv      s3, a0

read_more:
        li      a7, SYS_read
        mv      a0, s3
        la      a1, buf
        li      a2, BUFSIZE
        ecall
        beqz    a0, copy_done       # 0 = EOF
        bltz    a0, copy_fail

        mv      t2, a0              # bytes still to write
        la      t3, buf
write_more:
        li      a7, SYS_write
        li      a0, 1               # stdout
        mv      a1, t3
        mv      a2, t2
        ecall
        bltz    a0, copy_fail
        add     t3, t3, a0
        sub     t2, t2, a0
        bnez    t2, write_more
        j       read_more

copy_done:
        ld      s3, 0(sp)
        ld      ra, 8(sp)
        addi    sp, sp, 16
        ret

copy_fail:
        ld      s3, 0(sp)
        ld      ra, 8(sp)
        addi    sp, sp, 16
        j       fail

        .section .rodata
err:
        .ascii  "cat: open/read/write failed\n"
err_end:

        .bss
        .align  3
buf:
        .space  BUFSIZE
