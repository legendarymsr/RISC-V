# Bare-metal RV64 hello — talks to the UART, no OS.
#
#   make            # both M-mode (0x80000000) and S-mode (0x80200000)
#   make run        # QEMU virt, -bios none  (true bare metal)
#   make run-s      # QEMU virt, default OpenSBI (S-mode, like the VF2)
#
# Ctrl-A x quits QEMU. Assembling this is not compiling the world.

CROSS   ?= riscv64-linux-gnu-
AS      := $(CROSS)as
LD      := $(CROSS)ld

ASFLAGS ?= -march=rv64gc -mabi=lp64d
LDFLAGS ?= -m elf64lriscv -T link.ld -nostdlib

QEMU    ?= qemu-system-riscv64
# -nographic hooks the UART up to this terminal (Ctrl-A x to quit).
QEMUFLAGS ?= -machine virt -nographic

.PHONY: all clean run run-s

all: hello-m.elf hello-s.elf

hello-m.o: hello.s
	$(AS) $(ASFLAGS) -o $@ $<

hello-s.o: hello.s
	$(AS) $(ASFLAGS) --defsym SMODE=1 -o $@ $<

hello-m.elf: hello-m.o link.ld
	$(LD) $(LDFLAGS) --defsym BASE=0x80000000 -o $@ hello-m.o

hello-s.elf: hello-s.o link.ld
	$(LD) $(LDFLAGS) --defsym BASE=0x80200000 -o $@ hello-s.o

run: hello-m.elf
	$(QEMU) $(QEMUFLAGS) -bios none -kernel hello-m.elf

run-s: hello-s.elf
	$(QEMU) $(QEMUFLAGS) -kernel hello-s.elf

clean:
	rm -f hello-m.o hello-s.o hello-m.elf hello-s.elf
