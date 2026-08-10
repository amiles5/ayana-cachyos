#!/usr/bin/env bash
# Reapply Hyprland config right after resume from suspend. Works around the
# Studio Display's DP-over-Thunderbolt (DPIA) link failing to retrain in
# time on wake, which drops the monitor to a fallback scale and can leave
# keybinds unresponsive until a reload.
gdbus monitor --system --dest org.freedesktop.login1 --object-path /org/freedesktop/login1 2>/dev/null |
while read -r line; do
    case "$line" in
        *PrepareForSleep*false*)
            sleep 2
            hyprctl reload
            ;;
    esac
done
