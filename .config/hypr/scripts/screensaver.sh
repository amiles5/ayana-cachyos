#!/usr/bin/env bash
# Terminal-based idle screensaver (cbonsai), driven by hypridle on a short
# timeout -- separate from and much shorter than Noctalia's own idle
# lock/suspend timeout (60 min, noctalia/config.toml), so this just covers
# the earlier idle window before anything actually locks.
case "$1" in
    stop)
        pkill -f "kitty --class cbonsai-screensaver"
        ;;
    *)
        setsid kitty --class cbonsai-screensaver -o background_opacity=1.0 -e cbonsai -li >/dev/null 2>&1 &
        disown
        ;;
esac
