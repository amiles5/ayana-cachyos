#!/usr/bin/env bash
# Regenerate the package lists in this directory from current system state.
# Run after installing/removing packages, then `yadm add`/commit/push to keep
# the recovery list in sync. See README.md "Package lists" section.
set -eu
cd "$(dirname "$0")"

pacman -Qqe > pacman-explicit.txt
pacman -Qqm > pacman-foreign-aur.txt
flatpak list --app --columns=application 2>/dev/null > flatpak.txt || true
