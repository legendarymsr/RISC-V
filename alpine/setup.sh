#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# alpine/setup.sh — minimal Alpine riscv64 desktop (StarFive VisionFive 2, or
# any riscv64 box): bspwm + xterm + vis + lynx. Dead simple.
#
# EVERYTHING is a binary apk — ZERO compilation (recompiling on a 1.5 GHz U74
# is misery). The "dots" live as real files in ./config and get SYMLINKED into
# your home, so editing them in the repo updates the live config. No GPU, no
# compositor (software/fbdev rendering — the VF2's GPU driver is a mess and a
# tiling WM + terminal don't need it).
#
# Run as root on a booted Alpine, AFTER the base install (see README.md):
#   ./setup.sh                 # user defaults to 'legend'
#   TARGET_USER=me ./setup.sh
#
# Keyboard layout is set in config/bspwm/bspwmrc (`setxkbmap se`) — edit it there.
# =============================================================================
set -eu
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTS="$SELF_DIR/config"
CYAN='\033[0;36m'; YEL='\033[0;33m'; GRN='\033[0;32m'; NC='\033[0m'
say()  { printf '%b:: %s%b\n' "$CYAN" "$*" "$NC"; }
warn() { printf '%b!! %s%b\n' "$YEL" "$*" "$NC"; }
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 1; }
TARGET_USER="${TARGET_USER:-legend}"

# ── 1. community repo (bspwm, sxhkd, vis, bemenu live there) ──────────────────
if ! grep -qE '^[^#].*/community$' /etc/apk/repositories 2>/dev/null; then
  say "enabling the community repo"
  sed -i -E 's|^#(\s*https?://.*/community)$|\1|' /etc/apk/repositories || true
fi
apk update

# ── 2. the whole stack — all binary, no compilation ──────────────────────────
say "installing the desktop (binary packages)"
apk add \
  xorg-server xinit xf86-input-libinput xf86-video-fbdev \
  xrdb setxkbmap xsetroot \
  bspwm sxhkd bemenu lemonbar xterm vis lynx \
  || warn "core install had issues — check the apk output above"
# bemenu's X11 renderer (sometimes a separate subpackage; may already be bundled)
apk add bemenu-x11 2>/dev/null || true
# font: prefer JetBrains Mono Nerd (icons), fall back to Terminus (tiny, fast)
apk add font-jetbrains-mono-nerd 2>/dev/null \
  || apk add font-terminus 2>/dev/null \
  || warn "no preferred font found — xterm falls back to a default"

# ── 3. user ───────────────────────────────────────────────────────────────────
if ! id "$TARGET_USER" >/dev/null 2>&1; then
  say "creating user $TARGET_USER"
  adduser -D "$TARGET_USER"
  for g in input video wheel; do addgroup "$TARGET_USER" "$g" 2>/dev/null || true; done
  passwd "$TARGET_USER"
fi
UH="$(awk -F: -v u="$TARGET_USER" '$1==u{print $6}' /etc/passwd)"
[ -n "$UH" ] && [ -d "$UH" ] || { warn "no home dir for $TARGET_USER"; exit 1; }

# ── 4. symlink the dots in (edit in the repo → live) ─────────────────────────
say "linking dotfiles into $UH"
mkdir -p "$UH/.config"
ln -sfn "$DOTS/bspwm"      "$UH/.config/bspwm"
ln -sfn "$DOTS/sxhkd"      "$UH/.config/sxhkd"
ln -sfn "$DOTS/vis"        "$UH/.config/vis"
ln -sfn "$DOTS/Xresources" "$UH/.Xresources"
ln -sfn "$DOTS/xinitrc"    "$UH/.xinitrc"
ln -sfn "$DOTS/profile"    "$UH/.profile"

# vis only searches its INSTALL theme dir — drop the theme there too.
VISBIN="$(command -v vis 2>/dev/null || true)"
if [ -n "$VISBIN" ]; then
  VT="$(cd "$(dirname "$VISBIN")/../share/vis/themes" 2>/dev/null && pwd || true)"
  [ -n "$VT" ] && cp "$DOTS/vis/themes/tokyonight.lua" "$VT/tokyonight.lua" 2>/dev/null || true
fi

chown "$TARGET_USER:$TARGET_USER" "$UH/.config" 2>/dev/null || true
chown -h "$TARGET_USER:$TARGET_USER" \
  "$UH/.config/bspwm" "$UH/.config/sxhkd" "$UH/.config/vis" \
  "$UH/.Xresources" "$UH/.xinitrc" "$UH/.profile" 2>/dev/null || true

say "done"
printf '%bLog in as %s and run: startx%b\n' "$GRN" "$TARGET_USER" "$NC"
printf 'Keys: super+Return xterm · super+p bemenu · super+w lynx · super+e vis · super+shift+Esc quit\n'
printf 'The dots are symlinked from %s — edit there and the change is live.\n' "$DOTS"
