OUTPUT_ARCH(riscv)
ENTRY(_start)

/* BASE is 0x80000000 (M-mode, -bios none) or 0x80200000 (S-mode,
   OpenSBI). The Makefile passes --defsym BASE=...; PROVIDE supplies
   the M-mode default if you invoke ld by hand. */
PROVIDE(BASE = 0x80000000);

PHDRS
{
    text PT_LOAD FLAGS(5);       /* r-x */
    data PT_LOAD FLAGS(6);       /* rw- */
}

SECTIONS
{
    . = BASE;

    .text : {
        *(.text .text.*)
    } :text

    .rodata : {
        *(.rodata .rodata.*)
    } :text

    .data : {
        *(.data .data.*)
    } :data

    .bss : {
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(16);
        _stack_bottom = .;
        . = . + 0x4000;          /* 16 KiB stack */
        _stack_top = .;
    } :data
}
