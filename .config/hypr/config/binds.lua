local mainMod = "SUPER"
local noctCall = "noctalia msg "
local launchPrefix = "uwsm app -- " -- if you are not using UWSM, make this empty (e.g. "")

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

-- Window manipulation
hl.bind(mainMod .. " + Escape",      hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mainMod .. " + Q",           hl.dsp.window.close())
hl.bind(mainMod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D",           hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + F",           hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + J",           hl.dsp.layout("togglesplit"))

-- Change focus
hl.bind(mainMod .. " + Left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + Up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + Down",  hl.dsp.focus({ direction = "down" }))
local function cycleAndRaise(opts)
    hl.dispatch(hl.dsp.window.cycle_next(opts))
    hl.dispatch(hl.dsp.window.bring_to_top())
end
hl.bind("ALT + Tab",                 function() cycleAndRaise() end)

local function focusNonEmptyWorkspace(step)
    local activeWs = hl.get_active_workspace()
    if not activeWs or not activeWs.monitor then return end
    local monId = activeWs.monitor.id
    local list = {}
    for _, ws in ipairs(hl.get_workspaces()) do
        if ws.monitor and ws.monitor.id == monId and not ws.special then
            table.insert(list, ws)
        end
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    local n = #list
    if n == 0 then return end
    local idx = 1
    for i, ws in ipairs(list) do
        if ws.id == activeWs.id then idx = i end
    end
    local target = activeWs.id
    for offset = 1, n do
        local i2 = ((idx - 1 + step * offset) % n + n) % n + 1
        local ws = list[i2]
        if not ws.is_empty then
            target = ws.id
            break
        end
    end
    hl.dispatch(hl.dsp.focus({ workspace = target }))
end
hl.bind(mainMod .. " + Tab",         function() focusNonEmptyWorkspace(1) end)
hl.bind(mainMod .. " + SHIFT + Tab", function() focusNonEmptyWorkspace(-1) end)

-- Move active window around workspaces & monitors
hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = "1" }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = "2" }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = "3" }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = "4" }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = "5" }))
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = "6" }))
hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = "1" }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = "2" }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = "3" }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = "4" }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = "5" }))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = "6" }))

hl.bind(mainMod .. " + SHIFT + Up",                   hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + Right",                hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + Left",                 hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + Down",                 hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + mouse_up",             hl.dsp.window.move({ monitor   = "-1" }))
hl.bind(mainMod .. " + SHIFT + mouse_down",           hl.dsp.window.move({ monitor   = "+1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + Right",      hl.dsp.window.move({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + Left",       hl.dsp.window.move({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_up",   hl.dsp.window.move({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "m+1" }))
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + CONTROL + " .. key, hl.dsp.window.move({ workspace = "m~" .. i }))
end

-- Move & Resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- Zoom
local function zoomfunction(value)
    local zoomvalue = hl.get_config("cursor:zoom_factor")
    if (zoomvalue + value) > 3.0 then
        hl.config({ cursor = { zoom_factor = 3.0 } })
    elseif (zoomvalue + value) < 1.0 then
        hl.config({ cursor = { zoom_factor = 1.0 } })
    else
        hl.config({ cursor = { zoom_factor = zoomvalue + value } })
    end
end
hl.bind(mainMod .. " + Minus", function() zoomfunction(-0.3) end, { repeating = true})
hl.bind(mainMod .. " + Plus", function() zoomfunction(0.3) end, { repeating = true })

--# Zoom with keypad
hl.bind(mainMod .. " + code:82", function() zoomfunction(-0.3) end, { repeating = true })
hl.bind(mainMod .. " + code:86", function() zoomfunction(0.3) end, { repeating = true })


------------------
---- LAUNCHER ----
------------------

-- Kept on their fast single-key binds (most frequently used): terminal, file
-- manager, editor. Everything else below rationalized onto SUPER+SHIFT+<key>.
hl.bind(mainMod .. " + Return",     hl.dsp.exec_cmd("[workspace 1] " .. launchPrefix .. TERMINAL))
hl.bind(mainMod .. " + E",          hl.dsp.exec_cmd(launchPrefix .. FILE_MANAGER))
hl.bind(mainMod .. " + T",          hl.dsp.exec_cmd(launchPrefix .. EDITOR))
hl.bind(mainMod .. " + SHIFT + C",  hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
hl.bind("XF86Calculator",           hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("[workspace 5] " .. launchPrefix .. BROWSER))
hl.bind(mainMod .. " + SHIFT + M",  hl.dsp.exec_cmd(launchPrefix .. "flatpak run com.rtosta.zapzap"))
hl.bind(mainMod .. " + SHIFT + O",  hl.dsp.exec_cmd(launchPrefix .. "firefoxpwa site launch 01KZQREYPXKDBAHY9JWSG975VB"))
hl.bind(mainMod .. " + SHIFT + P",  hl.dsp.exec_cmd(launchPrefix .. "flatpak run --branch=master --arch=x86_64 --command=icloud-linux io.github.TaylanTatli.iCloud-Linux photos Photos"))
hl.bind(mainMod .. " + SHIFT + N",  hl.dsp.exec_cmd("[workspace 4] " .. launchPrefix .. "joplin-desktop"))
hl.bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e btop"))
hl.bind(mainMod .. " + Z",          hl.dsp.exec_cmd(noctCall .. "settings-toggle"))
hl.bind(mainMod .. " + X",          hl.dsp.exec_cmd(noctCall .. "panel-toggle control-center"))
hl.bind(mainMod .. " + Space",      hl.dsp.exec_cmd(noctCall .. "panel-toggle launcher"))
hl.bind(mainMod .. " + period",     hl.dsp.exec_cmd(noctCall .. "panel-toggle launcher /emo"))
hl.bind(mainMod .. " + L",          hl.dsp.exec_cmd(noctCall .. "session lock"))
hl.bind(mainMod .. " + ALT + C",    hl.dsp.exec_cmd(noctCall .. "panel-toggle session"))

---------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(noctCall .. "volume-up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(noctCall .. "volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(noctCall .. "volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(noctCall .. "mic-mute"),    { locked = true })

-- Media
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(noctCall .. "media toggle"),   { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(noctCall .. "media toggle"),   { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(noctCall .. "media next"),     { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(noctCall .. "media previous"), { locked = true })

-- Brightness
-- No internal backlight on this machine (mini PC + external display only), so
-- noctalia's brightness-up/down (targets /sys/class/backlight, which is empty
-- here) was a no-op. Studio Display brightness isn't DDC/CI-controllable -
-- Apple uses a proprietary HID protocol instead - so we drive it via asdbctl,
-- then push the resulting % to noctalia's OSD (brightness-osd only displays,
-- it doesn't itself change anything) so a brightness change is still visible
-- on screen the way volume/mic changes are.
local brightnessUpCmd   = "asdbctl up && noctalia msg brightness-osd $(asdbctl get | awk '{print $2}')"
local brightnessDownCmd = "asdbctl down && noctalia msg brightness-osd $(asdbctl get | awk '{print $2}')"
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(brightnessUpCmd),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(brightnessDownCmd), { locked = true, repeating = true })
-- The Logitech MX Keys Mechanical's F-row has no display-brightness function
-- at all (lock/app-switcher/screenshot/media/volume instead), so the XF86
-- keys above are unreachable from this keyboard. Its dedicated keyboard-
-- illumination key was tried as SUPER+XF86KbdBrightnessUp/Down, but that key
-- is handled entirely in the keyboard's own firmware - confirmed via evtest
-- on every input node the receiver exposes (event9/11/12): pressing it
-- produces zero kernel input events, so there is no keysym to ever bind to.
-- SUPER+bracket is the reachable fallback instead.
hl.bind(mainMod .. " + bracketleft",  hl.dsp.exec_cmd(brightnessDownCmd), { repeating = true })
hl.bind(mainMod .. " + bracketright", hl.dsp.exec_cmd(brightnessUpCmd),   { repeating = true })

-------------------
---- UTILITIES ----
-------------------

-- Screen Capture
hl.bind(mainMod .. " + P",     hl.dsp.exec_cmd("hyprpicker -a -n"))
-- "Print" is dead on the MX Keys Mechanical: the device declares KEY_PRINT as
-- a supported capability but no physical key actually sends it (confirmed
-- via evtest across every key/Fn-combo tried, same firmware-only situation as
-- the keyboard-illumination key). Kept below in case of a future keyboard
-- with a real PrtSc key, but SUPER+comma/SHIFT+comma are the reachable binds.
hl.bind("Print",               hl.dsp.exec_cmd(noctCall .. "screenshot-region"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(noctCall .. "screenshot-fullscreen"))
hl.bind(mainMod .. " + comma",         hl.dsp.exec_cmd(noctCall .. "screenshot-region"))
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.exec_cmd(noctCall .. "screenshot-fullscreen"))

-- Theming and Wallpaper
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(noctCall .. "panel-toggle wallpaper"))

-- Clipboard
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(noctCall .. "panel-toggle clipboard"))

-- Notifications
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(noctCall .. "panel-toggle control-center notifications"))

-------------------------------
---- WORKSPACES & MONITORS ----
-------------------------------

-- Focus on workspace number
-- Absolute
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + ALT + " .. key, hl.dsp.focus({ workspace = i }))
end
-- Relative
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + CONTROL + " .. key, hl.dsp.focus({ workspace = "m~" .. i }))
end

-- Move to adjacent workspaces and next empty on a given monitor
hl.bind(mainMod .. " + CONTROL + Right",       hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + Left",        hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + Down",        hl.dsp.focus({ workspace = "emptym" }))

-- Scroll through existing workspaces & monitors
hl.bind(mainMod .. " + mouse_down",           hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + mouse_up",             hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + mouse_up",   hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + mouse_down", hl.dsp.focus({ workspace = "m+1" }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special())
