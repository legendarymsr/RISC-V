# fizzbuzz.s — print FizzBuzz for 1..100.
# Uses the M extension (`div` / `rem`) to test divisibility and to
# turn integers into decimal digits. Still no libc: write(2) and exit(2)
# only.
#
# s0 = i, s1 = 100. Those are callee-saved, so they survive `call`.
# `ra` (x1) is the return address; functions that call other functions
# have to save it on the stack. The ABI wants `sp` 16-byte aligned.

        .text
        .global _start

        .equ    SYS_write, 64
        .equ    SYS_exit,  93
        .equ    STDOUT,    1

_start:
        li      s0, 1
        li      s1, 100

loop:
        # i % 15 == 0 → FizzBuzz
        li      t0, 15
        rem     t1, s0, t0
        beqz    t1, do_fizzbuzz

        # i % 3 == 0 → Fizz
        li      t0, 3
        rem     t1, s0, t0
        beqz    t1, do_fizz

        # i % 5 == 0 → Buzz
        li      t0, 5
        rem     t1, s0, t0
        beqz    t1, do_buzz

        # otherwise the number itself
        mv      a0, s0
        call    print_num
        j       newline

do_fizzbuzz:
        la      a0, s_fizzbuzz
        li      a1, 8
        call    print
        j       newline

do_fizz:
        la      a0, s_fizz
        li      a1, 4
        call    print
        j       newline

do_buzz:
        la      a0, s_buzz
        li      a1, 4
        call    print

newline:
        la      a0, s_nl
        li      a1, 1
        call    print

        addi    s0, s0, 1
        ble     s0, s1, loop

        li      a7, SYS_exit
        li      a0, 0
        ecall

# print(a0=buf, a1=len) — write to stdout. Clobbers a0–a2 and a7.
print:
        mv      a2, a1
        mv      a1, a0
        li      a0, STDOUT
        li      a7, SYS_write
        ecall
        ret

# print_num(a0=unsigned n) — decimal via repeated div/rem by 10, then write.
# Handles 0. Digits are generated backwards into a small stack buffer.
print_num:
        addi    sp, sp, -32
        sd      ra, 24(sp)

        mv      t2, a0              # n
        addi    t3, sp, 20          # cursor, grows downward
        li      t0, 10

        bnez    t2, digit
        # n == 0: emit a single '0'
        addi    t3, t3, -1
        li      t1, '0'
        sb      t1, 0(t3)
        j       emit

digit:
        beqz    t2, emit
        rem     t1, t2, t0          # t1 = n % 10
        div     t2, t2, t0          # n    = n / 10
        addi    t1, t1, '0'
        addi    t3, t3, -1
        sb      t1, 0(t3)
        j       digit

emit:
        mv      a0, t3              # start of the digits
        addi    a1, sp, 20
        sub     a1, a1, t3          # length
        call    print

        ld      ra, 24(sp)
        addi    sp, sp, 32
        ret

        .section .rodata
s_fizzbuzz:
        .ascii  "FizzBuzz"
s_fizz:
        .ascii  "Fizz"
s_buzz:
        .ascii  "Buzz"
s_nl:
        .ascii  "\n"
