-- Hyprland default apps

TERMINAL     = "kitty"
FILE_MANAGER = "dolphin"
BROWSER      = "firefox"
EDITOR       = "gnome-text-editor --new-window"
CALCULATOR   = "gnome-calculator"

-- Monitors
-- Matched by EDID description, not port name: the Studio Display's
-- DP-over-Thunderbolt (DPIA) tunnel re-enumerates as a different connector
-- (DP-2/DP-3/...) across reboots and suspend/resume, so a fixed port name
-- silently stops matching.
MONITOR1 = "desc:Apple Computer Inc StudioDisplay 0xBE714649" -- Apple Studio Display
MONITOR2 = ""
MONITOR3 = ""
PRIMARY_MONITOR = MONITOR1

-- Workspaces
NUM_WPM = 6 -- Number of workspaces per monitor (Max 10)
