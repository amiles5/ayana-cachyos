-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Example: output can be found with hyprctl monitors. Edit variables.lua for the monitor outputs instead of here directly
-- hl.monitor({
--     output    = "MONITOR1",
--     mode      = "1920x1080@60",
--     position  = "0x0",
--     scale     = "1",
-- })

hl.monitor({
    output    = MONITOR1,
    mode      = "5120x2880@60",
    position  = "0x0",
    scale     = "3.2000",
})

-- Ignore both HDMI ports unconditionally, regardless of what's plugged into them.
-- Studio Display (MONITOR1, above) is the only monitor Hyprland should ever use.
hl.monitor({
    output   = "HDMI-A-1",
    disabled = true,
})

hl.monitor({
    output   = "HDMI-A-2",
    disabled = true,
})
