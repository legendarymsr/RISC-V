# alpine — minimal Alpine riscv64 desktop (StarFive VisionFive 2)

A deliberately tiny desktop for a **RISC-V** board: **bspwm + xterm + vis + lynx**,
every piece a **binary `apk` package — nothing compiled**. This is the KISS/suckless
idea *adapted to slow silicon*: on a 1.5 GHz SiFive U74, the suckless "just recompile
`config.h`" loop is misery, so the terminal is themed via `~/.Xresources`, the WM via
runtime `~/.config`, and vis via Lua. No source builds, no GPU/compositor.

> **Why not Gentoo/Exherbo here?** Those are my daily-driver, source-based systems —
> and I don't hate myself enough to `emerge` the world on a 1.5 GHz U74 (overnight
> builds for one package set). Alpine's prebuilt riscv64 packages install in seconds.
> Right tool, right hardware — see the main [README](../README.md#why-not-gentoo).

## Hardware

StarFive **VisionFive 2** — JH7110 SoC (quad SiFive U74, `RV64GC`, 1.5 GHz), 2/4/**8 GB**
LPDDR4. Get the 8 GB if you can. Boot from **NVMe (M.2)** or **eMMC**, not microSD — SD
is slow and wears out on a board this class.

**The GPU is a trap, and we sidestep it.** The VF2's Imagination BXE GPU has no clean
open driver. This setup uses X11 on the **software/`fbdev`/modesetting** path — no 3D,
no compositing, which dwm-class WMs + a terminal don't need. Don't install `picom`.

## 1. Base install (board-specific — do this first)

> **⚠️ These steps are for the VisionFive 2 specifically.** A different RISC-V
> board flashes differently — see ["Every board is different"](#every-board-is-different)
> at the bottom. Don't copy VF2 switch positions or `mtd` layouts onto another board.

### Easiest: flash the prebuilt VF2 image

An Alpine dev (mps) publishes **ready-made riscv64 SD images**, VisionFive 2
included — so you can skip hand-rolling the kernel/U-Boot entirely:

```sh
# on your host — check the device with lsblk, wrong target = wiped disk
wget https://dev.alpinelinux.org/~mps/riscv64/visionfive-v2-mmc.img.xz
xz -dc visionfive-v2-mmc.img.xz | doas dd of=/dev/sdX bs=4M conv=fsync status=progress
```

Set the boot switches to boot from SD (see the table below), insert, power on. It
boots a working Alpine riscv64; log in, then `setup-alpine` + `setup-disk` to move
it onto NVMe/eMMC and enable the **community** repo. This is by far the least
painful path — [other boards' images are in the same directory](https://dev.alpinelinux.org/~mps/riscv64/)
(VF1, SpaceMIT K1, BPI-F3…).

### Or roll it yourself (the fiddly way)

If you want a custom kernel, or there's no prebuilt image for your board, do it
by hand. The shape of it:

1. **U-Boot / SPL** — the VF2 boots a two-stage U-Boot (SPL → OpenSBI + U-Boot
   proper) out of its onboard **QSPI flash**. U-Boot is what then loads an OS off
   SD/NVMe. Boards from ~late 2022 on ship a recent enough U-Boot; early boards need
   it updated. This is the main first-day hurdle.
2. **Kernel + device tree** — HDMI display needs the JH7110 DRM driver, which is in
   **mainline ≥ 6.6**. Use a recent mainline kernel (cleaner) or StarFive's vendor
   fork (more peripheral coverage). Match it with the VF2 `.dtb`. Alpine's VF2
   kernel/U-Boot recipes live at
   [gitlab.alpinelinux.org/nmeum/alpine-visionfive](https://gitlab.alpinelinux.org/nmeum/alpine-visionfive).
3. **Alpine rootfs** — put an Alpine **riscv64** rootfs on the NVMe/eMMC, then
   run `setup-alpine` for the base (hostname, network, users, `apk` mirror) and
   `setup-disk` to install it properly. Enable the **community** repo.

The official [**Alpine riscv64 wiki page**](https://wiki.alpinelinux.org/wiki/Riscv64)
and this [**VisionFive 1/2 walkthrough**](https://arvanta.net/alpine/alpine-on-visionfive/)
have the current specifics — cross-check them, the details move fast.

### Flashing the VisionFive 2 (concretely)

**a. Set the boot-mode switches.** The VF2 has two boot-mode pins near the 40-pin
header, labelled **`RGPIO_0`** (bit 0) and **`RGPIO_1`** (bit 1). They pick where
the SoC's mask ROM looks first:

| RGPIO_1 | RGPIO_0 | boots from |
|:-------:|:-------:|------------|
| 0 | 0 | **QSPI flash** (the normal U-Boot boot — use this once U-Boot is flashed) |
| 0 | 1 | SD card (SDIO3.0) |
| 1 | 0 | eMMC |
| 1 | 1 | **UART** (recovery — used to reflash U-Boot) |

For a normal install leave both at **0 0** (boot U-Boot from QSPI; U-Boot then
finds your SD/NVMe). Power the board off before moving them.

**b. (If needed) update U-Boot in the QSPI flash.** Two common ways:

- *From a Linux already running on the board* (e.g. StarFive's Debian image on an
  SD): download the matching `u-boot-spl.bin.normal.out` + `visionfive2_fw_payload.img`
  and write them to the flash's MTD partitions with `flashcp`:
  ```sh
  doas flashcp -v u-boot-spl.bin.normal.out /dev/mtd0
  doas flashcp -v visionfive2_fw_payload.img /dev/mtd1
  ```
  (confirm the partition numbers with `cat /proc/mtd` — **don't** assume).
- *UART recovery* — set the switches to `1 1`, connect a USB-UART to the debug
  header (3.3 V, 115200 baud), and use StarFive's `vf2-recovery`/`Tools` flow to
  push U-Boot over serial. Use this if the board won't boot at all.

**c. Write the OS image to SD or NVMe.** On your host, with the card/NVMe at
`/dev/sdX` (check with `lsblk` — writing to the wrong device nukes your disk):
```sh
# plain dd
doas dd if=starfive-visionfive2.img of=/dev/sdX bs=4M conv=fsync status=progress
# or, faster/safer if the image ships a .bmap:
doas bmaptool copy starfive-visionfive2.img /dev/sdX
```
microSD is fine to get booting, but **NVMe (M.2) or eMMC is the right target** —
SD is slow and wears out on a board this class. Easiest path: flash StarFive's
Debian image to SD first to confirm the board boots and to get a recent U-Boot in
flash, *then* move your real install to NVMe.

**d. Boot.** Switches at `0 0`, media inserted, power on. U-Boot runs from QSPI,
finds the bootloader/kernel on your media, and boots. From there run
`setup-alpine` → `setup-disk`, enable the community repo, and continue to the
desktop step below.

## 2. Desktop (one script, all binary)

Once Alpine boots and you're at a root shell, clone this repo and run:

```sh
apk add git
git clone https://github.com/legendarymsr/RISC-V
cd RISC-V/alpine
TARGET_USER=legend ./setup.sh
```

`setup.sh` is dead simple: it enables the community repo, `apk add`s the whole
stack (**no compilation**), creates your user, and **symlinks** the dotfiles from
[`config/`](config/) into your home. Because they're symlinks, editing a file in
the repo changes the live config immediately — keep the clone around.

| thing | package | dotfile (symlinked from `config/`) |
|-------|---------|------------------------------------|
| **bspwm** + **sxhkd** | `bspwm sxhkd` | `config/bspwm/bspwmrc`, `config/sxhkd/sxhkdrc` → `~/.config/…` |
| **lemonbar** | `lemonbar` | `config/bspwm/panel` — tiny panel: desktops + clock, `bspc subscribe`-driven |
| **xterm** | `xterm` | `config/Xresources` → `~/.Xresources` (Tokyo Night) |
| **bemenu** | `bemenu` | dmenu-alike, themed by launch flags in `sxhkdrc` (runtime, no config.h) |
| **vis** | `vis` | `config/vis/visrc.lua` + Tokyo Night theme → `~/.config/vis/` |
| **lynx** | `lynx` | `config/lynx/lynx.cfg` + `lynx.lss` → `~/.config/lynx/` (Tokyo Night, vi keys; `LYNX_CFG`/`LYNX_LSS` set in `config/profile`) |
| **vi** (busybox) | (base) | `$EXINIT` in `config/profile` → `~/.profile` |
| **Xorg** | `xorg-server xinit xf86-input-libinput xf86-video-fbdev` | `config/xinitrc` → `~/.xinitrc` (`exec bspwm`) |

**Keyboard layout** lives in `config/bspwm/bspwmrc` (`setxkbmap se`) — edit that one
line to `us`/`de`/whatever. Then log in as your user and:

```sh
startx
```

**Keys** (Super = mod): `Return` xterm · `d` bemenu · `b` lynx · `e` vis · `q`/`shift+q`
close/kill · `{1-5}` desktops · `{h,j,k,l}` focus · `t`/`f` tiled/fullscreen · `shift+r`
reload bspwm · `shift+Escape` quit · `Escape` reload sxhkd.

## Notes

- **No compiling, ever.** Every tweak is a dotfile edit in [`config/`](config/)
  (the symlinks mean it's instantly live): colors in `config/Xresources`
  (`xrdb -merge ~/.Xresources` to reload), binds in `config/sxhkd/sxhkdrc`
  (`super+Escape` reloads), WM in `config/bspwm/bspwmrc` (`super+shift+r` restarts).
- **lynx** is riced in [`config/lynx/`](config/lynx/): `lynx.lss` maps Tokyo Night onto
  the 16 ANSI colours xterm already gets from `Xresources` (links blue, current link a
  blue bar, headings magenta/blue/cyan, code green, status bar on gray). `lynx.cfg`
  includes `/etc/lynx.cfg`, turns on **vi keys** (`h` back · `j`/`k` links · `l`
  follow), plus `g`/`G` top/bottom, `^D`/`^U` half-page, `o` open URL, `O` edit
  URL, `u`/`U` back/forward, `c` options, `/` `n` `N` search. Form fields need
  `Enter` before typing (so `j`/`k` never land in a text box). Start page is
  DuckDuckGo Lite; cookies are accepted silently but kept in RAM only. Lynx has
  no "visited link" colour, so `V` lists visited links instead.
- The **Tokyo Night** palette is the same one used across my `legenddots`
  (st/Termux), delivered here purely at runtime instead of baked into a binary.
- **vis** uses the same name-based Tokyo Night theme as Termux, so it renders through
  xterm's palette and works regardless of vis's color-depth support.
- The **panel** is a ~30-line `config/bspwm/panel` feeding **lemonbar**: desktops
  on the left (focused highlighted, empty dimmed), clock on the right, updated by
  `bspc subscribe` (event-driven, no polling). Edit that file to change it; nuke a
  segment by deleting its block. Alpine's lemonbar is the non-Xft build (bitmap
  fonts only) — it defaults to `fixed`; see the note at the top of `panel` for
  using Terminus instead. Don't want a bar at all? Delete the panel lines from
  `bspwmrc` and drop `top_padding`.

## Every board is different

The flashing steps above are **VisionFive 2 specific** — and that's not a wart,
it's RISC-V working as intended. RISC-V is "free" in the sense of **libre**: the
instruction set is unpatented and un-owned, so anyone can design a chip around it
without a licence. The flip side of *no gatekeeper* is *no single mandated
platform* — there's no RISC-V equivalent of the PC's standardized UEFI/ACPI boot
world. Every vendor picks their own boot ROM, firmware, switches, and device tree.

So on a **Milk-V Mars/Jupiter**, a **SiFive HiFive**, a **Pine64 Star64**, a
**Lichee Pi 4A**, etc., expect the base install to differ: different U-Boot,
different boot-mode selection (jumpers, DIP switches, or none), different image,
different `.dtb`. **Read that board's own docs for step 1 — do not reuse the VF2
switch table or `mtd` partitions.**

What *does* carry over is everything from **section 2 onward**: `setup.sh` and the
dotfiles are plain `riscv64` userland and runtime config. Once any
application-class board boots a `riscv64` Alpine (or Debian/Fedora) userland, the
desktop half of this repo works unchanged. The firmware/kernel/bootloader is the
part you re-learn per board; the software on top is portable.
