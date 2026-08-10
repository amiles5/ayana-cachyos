-- Input configuration

hl.config({
    input = {
        kb_layout    = "gb",
        kb_model     = "apple",
        kb_variant   = "mac",
        follow_mouse = 1,
        sensitivity  = 0,
        accel_profile = "flat",
        touchpad = {
            natural_scroll = false,
        },
    },
    -- Uncomment the section below to enable software cursors; this can help with cursor display or behavior issues
    -- cursor = {
    --     no_hardware_cursors = 1,
    -- },
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down",       action = "close" })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "left",       action = "float" })
