# RISC-V

My RISC-V stuff — configs and install scripts for RISC-V hardware, kept
separate from my main [`legenddots`](https://github.com/legendarymsr/legenddots).

The guiding idea: RISC-V silicon is slow, so **nothing gets compiled**. Where
`legenddots` leans on suckless source builds (`config.h` → recompile), the RISC-V
boxes use **binary packages** themed entirely through runtime dotfiles.

## What is RISC-V?

An **ISA** — an *instruction set architecture*, the contract between the
hardware and the software: the actual machine instructions a CPU understands
(`add`, `load`, `branch`, …). It is **not** a chip and not a company's product;
it's a *specification* that anyone can build a chip to. Think of it as the
language, not the speaker.

RISC-V (said "risk-five") came out of UC Berkeley in 2010 — the fifth Berkeley
RISC design, hence the V. **RISC** = *Reduced Instruction Set Computer*: a small
set of simple, fixed-length, fast instructions, as opposed to **CISC** (x86),
which piles on large, complex, variable-length ones. The whole thing is now
stewarded by **RISC-V International**, a non-profit that (pointedly) relocated to
Switzerland in 2020 to stay out of any one country's export politics.

The design is **modular**. There's a tiny mandatory base — `RV32I`/`RV64I`, just
integer ops — and everything else is an optional, standardized **extension** you
bolt on:

| ext | adds |
|-----|------|
| **M** | integer multiply / divide |
| **A** | atomics (needed for real multithreading) |
| **F** / **D** | single- / double-precision floating point |
| **C** | compressed 16-bit encodings of common instructions (smaller code) |
| **V** | vector / SIMD |

`IMAFD` together is abbreviated **G** ("general"), so the Linux-capable baseline
you'll see everywhere — including the VisionFive 2 in this repo — is **`RV64GC`**:
64-bit, general-purpose, compressed. That's the sweet spot for a desktop-ish board.

## Why care?

**It's open and royalty-free.** This is the whole point. The spec is a public
standard — you can read it, implement it, extend it, and ship silicon without
asking anyone's permission or paying a license fee. That means:

- **No vendor lock-in and no gatekeeper.** No single company can revoke your
  licence, jack up royalties, get acquired and change terms, or be blocked by an
  export ban from selling to you. The ISA just *exists*.
- **Anyone can make a chip** — universities, startups, hobbyists, nation-states
  hedging against sanctions. That's why RISC-V is exploding in exactly the places
  that dislike depending on a foreign IP owner.
- **It's hackable all the way down.** Custom extensions are a first-class feature,
  so people build RISC-V cores tuned for AI accelerators, microcontrollers, GPUs,
  storage controllers — one ISA from a 25¢ MCU up to a server.
- **It fits a free-software worldview.** An open ISA under an open OS with open
  tooling, no proprietary layer in the stack you *have* to accept.

The honest catch: it's **young**. The software, drivers, and prebuilt packages
are catching up fast but still trail the incumbents, and high-end performance
parts are only now arriving. You run RISC-V today because the idea is right and
you want in early — not because it'll out-benchmark your laptop.

## RISC-V vs ARM — the closest comparison

ARM is the fair yardstick: it's also a **load/store RISC** architecture (not the
x86/CISC world), it dominates everything RISC-V wants to be in — phones,
embedded, increasingly servers and laptops — and it's the thing RISC-V is most
often pitched *against*. The gap isn't really technical; it's about **who owns
the ISA**.

- **ARM is proprietary IP.** Arm Holdings designs the architecture and the Cortex/
  Neoverse cores and **licenses** them: you either buy an *architecture licence*
  to design your own compatible core (what Apple does for the M-series) or a
  *core licence* to use Arm's ready-made designs — and you pay **per-chip
  royalties** either way. Arm controls the roadmap, the terms, and who's allowed
  to play.
- **RISC-V is a free standard.** No licence, no royalty, no permission. You can
  even design a core in your garage and call it RISC-V if it conforms. The
  Qualcomm↔Arm licensing lawsuit and the Arm-China governance mess are exactly
  the kind of thing that can't happen to an open ISA — and a big reason companies
  are migrating.

| | **RISC-V** | **ARM** |
|---|-----------|---------|
| **Type** | RISC ISA (open standard) | RISC ISA (proprietary) |
| **Who owns it** | RISC-V International (non-profit) | Arm Holdings (SoftBank; IPO'd 2023) |
| **Cost to implement** | free — no licence, no royalties | licence fee + per-chip royalty |
| **Born** | 2010 (UC Berkeley) | 1985 (Acorn) — decades of maturity |
| **Software ecosystem** | young, improving fast; some gaps | vast, mature, rock-solid tooling & distros |
| **Standardization** | modular + *profiles* (RVA22/RVA23) to curb fragmentation | uniform baselines (ARMv8-A / v9-A) |
| **Top-end performance** | emerging (SiFive P-series, Ventana, Tenstorrent) | world-class (Apple M, Neoverse, Graviton) |
| **Customize the ISA itself** | yes — custom extensions are first-class | no — you implement Arm's ISA as specified |
| **Where it's strong today** | microcontrollers, accelerators, dev boards | phones, servers, laptops, embedded — everywhere |

**The trade in one line:** ARM gives you a mature, uniform, battle-tested
platform that you'll never fully *own*; RISC-V gives you a free, open, infinitely
hackable ISA whose ecosystem is still filling in. ARM's biggest risk is its
modularity-free dependence on one company; RISC-V's biggest risk is
**fragmentation** — because anyone can pick-and-choose extensions, two "RISC-V"
chips needn't run the same binaries. The community's answer is **profiles** like
`RVA23`, which pin down a mandatory extension set that application-class chips
(the ones that boot a normal Linux distro) must implement, so a single
`riscv64` build Just Works — which is exactly why Alpine's prebuilt `riscv64`
packages in this repo install and run without a recompile.

If you care about owning your stack end to end — open ISA, open OS, open
tooling, no proprietary layer you're forced to accept — RISC-V is the only one of
the two that lets you go all the way down. That's why it's here.

## What's here

| dir | board / target | stack |
|-----|----------------|-------|
| [`alpine/`](alpine/) | StarFive **VisionFive 2** (JH7110, `RV64GC`) | Alpine riscv64 · bspwm + xterm + vis + lynx — all binary `apk`, zero compilation |

See each directory's `README.md` for the install steps.
