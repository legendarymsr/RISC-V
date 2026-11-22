# Tiny RV64 Linux programs, no libc.
#
# Cross (Debian/Ubuntu):
#   apt install binutils-riscv64-linux-gnu qemu-user
#   make
# On the VisionFive 2 (native as/ld from Alpine's binutils):
#   apk add binutils
#   make CROSS=
# Assembling these is not "compiling the world." as/ld finish in a blink
# even on a 1.5 GHz U74.

CROSS   ?= riscv64-linux-gnu-
AS      := $(CROSS)as
LD      := $(CROSS)ld

# RV64GC / lp64d — same ABI as the VisionFive 2 (and any RVA-profile Linux).
ASFLAGS ?= -march=rv64gc -mabi=lp64d
LDFLAGS ?= -m elf64lriscv

PROGS   := hello fizzbuzz args cat

# qemu-user on Debian 13+; qemu-riscv64-static on Ubuntu / older Debian.
# On a real riscv64 board, just run the binaries directly.
ifeq ($(shell uname -m),riscv64)
QEMU    ?=
else
QEMU    ?= $(shell command -v qemu-riscv64 2>/dev/null || command -v qemu-riscv64-static 2>/dev/null || echo qemu-riscv64)
endif

.PHONY: all clean run

all: $(PROGS)

$(PROGS): %: %.o
	$(LD) $(LDFLAGS) -o $@ $<

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

run: all
	@echo '== hello =='
	@$(QEMU) ./hello
	@echo '== fizzbuzz =='
	@$(QEMU) ./fizzbuzz
	@echo '== args =='
	@$(QEMU) ./args foo bar
	@echo '== cat =='
	@printf 'piped text\n' | $(QEMU) ./cat

clean:
	rm -f $(PROGS) *.o
