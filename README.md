# RISC-V

My RISC-V stuff — configs and install scripts for RISC-V hardware, kept
separate from my main [`legenddots`](https://github.com/legendarymsr/legenddots).

The guiding idea: RISC-V silicon is slow, so **nothing gets compiled**. Where
`legenddots` leans on suckless source builds (`config.h` → recompile), the RISC-V
boxes use **binary packages** themed entirely through runtime dotfiles.

## What's here

| dir | board / target | stack |
|-----|----------------|-------|
| [`alpine/`](alpine/) | StarFive **VisionFive 2** (JH7110, `RV64GC`) | Alpine riscv64 · bspwm + xterm + vis + lynx — all binary `apk`, zero compilation |

See each directory's `README.md` for the install steps.
