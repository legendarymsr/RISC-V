# RISC-V

My RISC-V stuff — configs and install scripts for RISC-V hardware, kept
separate from my main [`legenddots`](https://github.com/legendarymsr/legenddots).

The guiding idea: RISC-V silicon is slow, so **nothing gets compiled**. Where
`legenddots` leans on suckless source builds (`config.h` → recompile), the RISC-V
boxes use **binary packages** themed entirely through runtime dotfiles.

## Why not Gentoo?

I daily-drive Gentoo (and Exherbo) — source-based, compile-the-world systems, and
I love them *on hardware that can take it*. This board is a 1.5 GHz quad SiFive
U74. Emerging a desktop, let alone `@world`, on that would be **overnight builds
for a single package set**, every update a small eternity, the fans — well, there
are no fans — the *heatsink* quietly weeping.

I don't hate myself **that** much.

So on RISC-V I do the opposite of my usual: **Alpine**, prebuilt `riscv64` binary
packages, zero compilation. Same minimalist taste (bspwm, vis, lynx, Tokyo Night),
delivered without turning a dev board into a space heater. Source-based distros are
a joy when `make -j` finishes before you've finished your coffee; on slow silicon
they're a sentence. Right tool, right hardware.

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

## "Free" means *free as in freedom* — and why every board differs

Worth nailing down, because it's the whole philosophy. RISC-V being "free" does
**not** mean the hardware is cheap or the silicon is gratis — a VisionFive 2
costs real money, and plenty of RISC-V cores are commercial products you license
and pay for. What's free is the **ISA itself**: it's **unpatented and
un-owned**. Nobody holds the instruction set, nobody can patent-troll an
implementation of it, and no company can tell you you're not allowed to build,
modify, or extend a chip around it. *Libre*, not *zero-price* — free as in
**not proprietary**, not free as in beer.

A direct consequence worth bracing for: **there is no "the RISC-V platform."**
Because anyone can design a RISC-V SoC however they like — their own extensions,
boot ROM, firmware, peripherals, memory map — **every board boots differently.**
There's no RISC-V equivalent of the PC's standardized UEFI/ACPI world that lets
one image boot any machine. So:

- Flashing/boot steps are **per board.** The VisionFive 2 in this repo has its
  own U-Boot, boot-mode switches, and device tree; a SiFive HiFive, Milk-V
  Mars/Jupiter, Pine64 Star64, or Lichee Pi does it differently. Always read
  *that* board's docs for the firmware/kernel/bootloader bring-up.
- What **does** transfer is the software above the firmware: a `riscv64` Linux
  userland (like Alpine's) runs on any application-class board that follows the
  profiles. The kernel + device tree + bootloader is the part you re-learn per
  board; the OS and configs on top are portable.

That's the trade for having no gatekeeper — freedom at the ISA level buys a less
uniform hardware world. It's a feature, but it means "how do I flash my RISC-V
board?" has no one answer.

## What's here

| dir | board / target | stack |
|-----|----------------|-------|
| [`alpine/`](alpine/) | StarFive **VisionFive 2** (JH7110, `RV64GC`) | Alpine riscv64 · bspwm + xterm + vis + lynx — all binary `apk`, zero compilation |

See each directory's `README.md` for the install steps.

## Further reading

**The standard**
- [RISC-V International](https://riscv.org/) — the non-profit that stewards the ISA.
- [Specifications](https://riscv.org/technical/specifications/) — the official
  spec documents (the unprivileged ISA is the one to start with; the privileged
  spec covers supervisor/hypervisor modes).
- [RVA profiles](https://github.com/riscv/riscv-profiles) — the `RVA22`/`RVA23`
  profiles that pin down what application-class chips must implement (the
  anti-fragmentation answer).

**My hardware**
- [StarFive VisionFive 2](https://doc-en.rvspace.org/) — RVspace docs hub for the
  board (U-Boot, kernel, images).
- [Alpine `Riscv64` wiki](https://wiki.alpinelinux.org/wiki/Riscv64) — the official
  riscv64 page, and prebuilt VF2 SD images at
  [dev.alpinelinux.org/~mps/riscv64/](https://dev.alpinelinux.org/~mps/riscv64/).
- [Alpine on VisionFive (arvanta)](https://arvanta.net/alpine/alpine-on-visionfive/)
  and [ruyisdk VisionFive/Alpine](https://github.com/ruyisdk/support-matrix/blob/main/VisionFive/Alpine/README.md)
  — concrete VF2 install walkthroughs.
- **Gentoo** — [RISC-V hub](https://wiki.gentoo.org/wiki/Category:RISC-V) (general,
  all boards + the ABI/hardware pages) and the
  [VisionFive 2 page](https://wiki.gentoo.org/wiki/StarFive_VisionFive_2) specifically.
  Linked not because I'd run Gentoo *on* the board (see
  ["Why not Gentoo?"](#why-not-gentoo)), but because Gentoo's docs are **fucking
  amazing** and routinely the clearest writeup of a board's quirks anywhere.
  Honestly, Gentoo's docs should cover whatever you're stuck on. If you can't
  install Gentoo after reading their handbook, you probably shouldn't have a computer.
- [Fedora RISC-V](https://fedoraproject.org/wiki/Architectures/RISC-V)
  ([hardware/boards](https://fedoraproject.org/wiki/Architectures/RISC-V/Hardware)),
  [Debian RISC-V](https://wiki.debian.org/RISC-V), and
  [Ubuntu VF2](https://wiki.ubuntu.com/RISC-V/StarFive%20VisionFive%202) — more
  cross-references, though per the above, Gentoo's docs have usually already got it.

**Learn the ISA**
- [riscv-isa-manual](https://github.com/riscv/riscv-isa-manual) — the spec source,
  if you want to read the actual instruction encodings.
- [*The RISC-V Reader*](http://riscvbook.com/) (Patterson & Waterman) — the
  friendly book-length intro by the architecture's creators.
- [Awesome RISC-V](https://github.com/xmpf/awesome-risc-v) — a curated list of
  cores, tools, emulators, docs, and software. **Heads up:** it's ~7 years old and
  RISC-V moves *fast*, so treat it as a starting map, not current truth — cross-check
  anything important (profiles, toolchain/kernel support, board status) against newer
  docs.
