-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("noctalia")
    hl.exec_cmd("xhost +SI:localuser:root")
    -- LD_PRELOAD works around gtk4-layer-shell needing to load before
    -- libwayland-client, which Python's own startup order breaks otherwise.
    hl.exec_cmd("env LD_PRELOAD=/usr/lib/libgtk4-layer-shell.so.0 python3 " .. os.getenv("HOME") .. "/.config/hypr/scripts/watermark.py")
end)
