# asm — tiny RV64 programs, no libc

A handful of RISC-V 64-bit Linux programs written in GNU assembler. They talk
to the kernel with raw syscalls (`ecall`) — no C, no libc, no start files.
The point is to actually *see* the ISA from the [main README](../README.md#what-is-risc-v)
in real instructions: `write`/`exit`/`read`/`openat`, `div`/`rem` from the
**M** extension, the calling convention, argc/argv as the kernel left them
on the stack.

These are ordinary userspace programs, not bare-metal firmware. They run on
the VisionFive 2 (or any RV64 Linux) and, on an x86 machine, under
`qemu-riscv64`.

Assembling a 40-line `.s` file is **not** "compiling the world." `as` and `ld`
finish in a blink even on the 1.5 GHz U74. That's a different beast from
emerging a desktop.

## What's here

| file | what it shows |
|------|----------------|
| [`hello.s`](hello.s) | `write` (syscall 64) + `exit` (93) — the smallest useful program |
| [`fizzbuzz.s`](fizzbuzz.s) | loops, `div`/`rem` (M extension), integer-to-decimal |
| [`args.s`](args.s) | `argc`/`argv` as laid out on the stack at `_start` |
| [`cat.s`](cat.s) | `read` (63), `openat` (56), `close` (57) — stdin or files to stdout |

## Build and run

**On an x86 (or any non-riscv64) machine**, you need a RISC-V assembler/linker
and qemu-user:

```sh
# Debian 13+
sudo apt install binutils-riscv64-linux-gnu qemu-user

# Ubuntu / older Debian (the qemu binary is often named qemu-riscv64-static)
sudo apt install binutils-riscv64-linux-gnu qemu-user-static

# Alpine (x86)
doas apk add binutils-riscv64 qemu-riscv64
make CROSS=riscv64-alpine-linux-musl-

# Nix
nix-shell -p qemu pkgsCross.riscv64-multiplatform.buildPackages.binutils
make CROSS=riscv64-unknown-linux-gnu-
```

Then, from this directory:

```sh
make
make run          # hello, fizzbuzz 1..100, args, cat — via qemu-riscv64
```

`make` defaults to the Debian/Ubuntu prefix `riscv64-linux-gnu-`. Override it
with `CROSS=...` as above, or `QEMU=qemu-riscv64-static` if that's the binary
you have.

**On the VisionFive 2 itself** (or any riscv64 Alpine box), you don't need a
cross toolchain or qemu. Alpine's `binutils` gives you `as` and `ld`:

```sh
doas apk add binutils
make CROSS=
./hello
./fizzbuzz
./args foo bar
./cat README.md
```

## Registers and the syscall ABI

Linux on RISC-V uses the standard integer calling convention, plus `ecall`
for syscalls. Syscall number goes in `a7`, arguments in `a0`–`a6`, return
value in `a0`.

| name | x-reg | role |
|------|-------|------|
| `zero` | x0 | hardwired zero |
| `ra` | x1 | return address (`call` / `ret`) |
| `sp` | x2 | stack pointer (16-byte aligned) |
| `gp` | x3 | global pointer |
| `tp` | x4 | thread pointer |
| `t0`–`t2` | x5–x7 | temporaries (caller-saved) |
| `s0`/`fp` | x8 | saved / frame pointer |
| `s1` | x9 | saved (callee-saved) |
| `a0`–`a1` | x10–x11 | arguments / return values |
| `a2`–`a7` | x12–x17 | arguments; **`a7` = syscall number** |
| `s2`–`s11` | x18–x27 | saved (callee-saved) |
| `t3`–`t6` | x28–x31 | temporaries (caller-saved) |

At `_start` (there is no `main` without libc) the stack is:

```
sp + 0             argc
sp + 8             argv[0]  → program name
sp + 16            argv[1]  → first argument, if any
…
sp + 8*(argc+1)    NULL
then envp[], a NULL, and the auxiliary vector
```

Useful syscall numbers on **riscv64** Linux (they are *not* the same as on
x86_64): `openat` 56, `close` 57, `read` 63, `write` 64, `exit` 93.
