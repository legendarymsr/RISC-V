# hello.s — bare-metal hello on QEMU's `virt` machine.
# No OS, no libc, no SBI calls: we write the NS16550A UART ourselves,
# then sit in `wfi`.
#
# QEMU virt puts a 16550-compatible UART at 0x10000000 with *byte*
# registers (reg-shift 0):
#   +0  THR  transmit holding register
#   +5  LSR  line status register; bit 5 (THRE) = transmitter empty
#
# The VisionFive 2's uart0 is also at 0x10000000, but it's a Synopsys
# DW 8250 with reg-shift = 2 (LSR at +0x14) and 32-bit accesses. This
# program is written for QEMU virt and is untested on the board.
#
# Two load addresses, picked by the linker script:
#   0x80000000  M-mode  —  qemu-system-riscv64 -bios none -kernel hello-m.elf
#   0x80200000  S-mode  —  qemu-system-riscv64 -kernel hello-s.elf
#                          (OpenSBI in front, the way the VF2 boots)

        .text
        .global _start

        .equ    UART_BASE, 0x10000000
        .equ    UART_THR,  0
        .equ    UART_LSR,  5
        .equ    LSR_THRE,  (1 << 5)

_start:
        # Only hart 0 prints. Other harts (if QEMU was started with
        # -smp N) park in wfi. mhartid is an M-mode CSR; in S-mode
        # OpenSBI starts only the boot hart, so the S-mode build
        # skips this (a csrr would trap).
        .ifndef SMODE
        csrr    t0, mhartid
        bnez    t0, park
        .endif

        la      sp, _stack_top      # 16-byte-aligned, see link.ld

        la      a0, msg
        call    puts

park:
        wfi
        j       park

# puts(a0 = NUL-terminated string) — write each byte to the UART.
puts:
        addi    sp, sp, -16
        sd      ra, 8(sp)
        sd      s0, 0(sp)
        mv      s0, a0
1:      lbu     a0, 0(s0)
        beqz    a0, 2f
        call    putc
        addi    s0, s0, 1
        j       1b
2:      ld      s0, 0(sp)
        ld      ra, 8(sp)
        addi    sp, sp, 16
        ret

# putc(a0 = character) — wait for THRE, then write THR.
putc:
        li      t0, UART_BASE
1:      lbu     t1, UART_LSR(t0)
        andi    t1, t1, LSR_THRE
        beqz    t1, 1b
        sb      a0, UART_THR(t0)
        ret

        .section .rodata
msg:
        .asciz  "Hello, RISC-V (bare metal)\n"
