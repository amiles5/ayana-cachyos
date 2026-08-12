#!/usr/bin/env bash
# Regenerate the package lists in this directory from current system state.
# Run automatically weekly via the pkglist-update.timer systemd user unit,
# and also after installing/removing packages if you want it sooner. Either
# way, still need to `yadm add .pkglist` + commit + push manually - this
# script only regenerates the files, it never commits. See README.md
# "Package lists" section.
set -eu
cd "$(dirname "$0")"

pacman -Qqe > pacman-explicit.txt
# pacman -Qqm exits 1 (with no output) when there are no foreign/AUR packages
# installed, which is normal on this system - don't let `set -e` kill the
# script over that.
pacman -Qqm > pacman-foreign-aur.txt || true
flatpak list --app --columns=application 2>/dev/null > flatpak.txt || true
