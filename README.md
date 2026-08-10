# ayana-cachyos

Dotfiles for `ayana` — CachyOS + Hyprland (Wayland), managed with [yadm](https://yadm.io)
(`$HOME` is the yadm work tree; only selected files/dirs are tracked, see below).

This file is a running log of the configuration changes made on this machine, most recent
context at the bottom of each section.

## Display — Apple Studio Display (`hypr/config/monitors.lua`, `variables.lua`)

- Replaced the wildcard/auto monitor rule with an explicit pinned rule for `DP-3`
  (`MONITOR1 = "DP-3"` in `variables.lua`).
- Mode `5120x2880@60`, position `0x0`; scale was set to `2.666`, then later re-tuned
  (currently `3.2000`).

## Audio — Apple Studio Display over Thunderbolt

Not a dotfile change, but a system fix worth recording: the display's audio/mic/webcam
are tunnelled over USB inside the Thunderbolt/USB4 link, so they don't appear until the
Thunderbolt device is authorized.

- One-off authorization confirmed the theory (devices appeared in `wpctl status`).
- Installed and enabled the `bolt` daemon, then ran
  `boltctl enroll --policy auto <uuid>` so the display auto-authorizes on every
  reconnect/boot instead of needing manual authorization each time.
- The NixOS install on the same physical machine (separate SSD) will need the same fix —
  not yet done, pending an SSD swap to boot into it.

## App launch → workspace targeting (`hypr/config/binds.lua`)

- `SUPER+Return` launches kitty directly onto workspace 1: `[workspace 1] ... kitty`.
- `SUPER+SHIFT+Return` launches Firefox directly onto workspace 5: `[workspace 5] ... firefox`
  (this bind replaced the old `SUPER+W` Firefox launcher).

## Keyboard/workspace cycling (`hypr/config/binds.lua`)

- `ALT+Tab` — native Hyprland window cycling within the current workspace, followed by
  `bring_to_top` so the newly focused window is actually raised.
- `SUPER+Tab` / `SUPER+SHIFT+Tab` — forward/backward **workspace** cycling on the current
  monitor, mouse-free equivalent of `SUPER+scroll wheel`. Noctalia's built-in
  window-switcher was intentionally *not* used for this — kept to native Hyprland
  dispatchers only.
- Upgraded further to **skip empty workspaces**: a `focusNonEmptyWorkspace(step)` helper
  walks the current monitor's workspace list (via `hl.get_active_workspace()` /
  `hl.get_workspaces()`, filtered by `ws.monitor.id` and sorted by `ws.id`) and focuses the
  next one with `not ws.is_empty`, wrapping around. Verified live via `hyprctl dispatch`
  IIFEs against real workspace occupancy before wiring into the actual binds. (Note:
  `hl.get_workspace(id)` re-lookup by integer ID returned `nil` in testing — the working
  version reuses the `HL.Workspace` objects already returned by `get_workspaces()` instead
  of re-querying.)

## Monitor-targeting binds removed (`hypr/config/binds.lua`)

`SUPER+1..6` (focus workspace) and `SUPER+SHIFT+1..6` (move window to workspace) were
added at some point using the same key combos as the pre-existing `SUPER+1..3`
(focus monitor) and `SUPER+SHIFT+1..3` (move window to monitor) binds, which caused
`monitor not found` / `Invalid monitor` errors whenever `MONITOR2`/`MONITOR3` (empty
strings, single-monitor setup) were targeted. Resolved by removing the monitor-by-number
binds entirely — monitor navigation is still fully covered by the existing relative binds
(`SUPER+CONTROL+Left/Right`, `SUPER+scroll`, `SUPER+SHIFT+scroll`), so nothing was lost,
and `SUPER+1..6`/`SUPER+SHIFT+1..6` are now exclusively workspace binds.

## Workspaces (`hypr/config/workspaces.lua`, `variables.lua`)

- Expanded from 3 to 6 persistent workspaces on startup, all pinned to `MONITOR1`.
- Bumped `NUM_WPM` (workspaces per monitor) from 3 to 6 so the `SUPER+ALT+1-6`,
  `SUPER+CONTROL+1-6`, and `SUPER+SHIFT+CONTROL+1-6` loops cover all six.

## Input / keyboard model (`hypr/config/inputs.lua`)

- Initially set `kb_layout = "gb"`, `kb_model = "apple"`, `kb_variant = "mac"`,
  `follow_mouse = 1`, `sensitivity = 0`, `touchpad.natural_scroll = false`, kept
  `accel_profile = "flat"`.
- Fixed a duplicate `kb_model` entry that had silently reverted the effective keyboard
  model to `pc105`/`evdev` (a second, uncommented `kb_model`/`kb_options`/`kb_rules` block
  had appeared below the intended one — last key wins in a Lua table). Removed the stray
  duplicate lines.
- **Then corrected the model entirely**: the actual keyboard in use is a **Logitech MX
  Mechanical** (connected via a Logi USB receiver — `hyprctl devices -j` showed it as
  `logitech-usb-receiver-1`), not an Apple keyboard (the Studio Display has none built in).
  `kb_model = "apple"` + `kb_variant = "mac"` was applying Apple's ISO key mapping to a
  standard ISO-UK keyboard, which swaps the `` ` ``/`§` key (next to left shift) and the
  `#`/`\` key (next to right shift) — exactly the symptom reported. Changed to
  `kb_model = "pc105"` with no `kb_variant`; `hyprctl devices -j` now correctly reports
  `English (UK)` instead of `English (UK, Macintosh)`.

## Idle → lock screen (`noctalia/config.toml`)

- Added `[idle.behavior.lock]` (`timeout = 1800`, `action = "lock"`, `enabled = true`) so
  Noctalia's lock screen triggers automatically after 30 minutes idle.
- Deliberately left `[idle.behavior.screen-off]` disabled — no DPMS/screen-blanking, only
  the lock action fires.
- Verified via Noctalia's hot-reload (`~/.cache/noctalia/noctalia.log` logged
  `config changed, reloading` immediately after the edit, no parse errors).

## Kitty terminal (`kitty/kitty.conf`)

- Middle-click now pastes the system **clipboard** rather than the primary selection:
  `mouse_map middle release ungrabbed paste_from_clipboard`.

## fastfetch (`fastfetch/config.jsonc`)

- Forced the Arch Linux logo instead of the CachyOS default. Generated the config with
  `fastfetch --gen-config` (to capture the full default module list) before adding the
  `logo` override — an earlier attempt that set only a bare `logo` key had accidentally
  wiped every system-info module, since an incomplete config replaces the defaults rather
  than merging with them.

## Networking

- Installed Tailscale, enabled/started `tailscaled`; now active and joined the tailnet
  (visible as `ayana-1`).
- Diagnosed Wi-Fi latency/jitter to the `mt7921e` driver's power-save mode plus
  suboptimal AP/BSSID selection on a dual-band mesh network; fixed via NetworkManager
  connection-profile settings (power save disabled, pinned to the better-performing BSSID).

## SSH

- Found and removed a dangling `~/.ssh/config` symlink pointing at a since-garbage-collected
  home-manager/Nix store path.
- Restored the previous real config from `~/.ssh/config.backup`, which defines host aliases
  (`github`, `bogdan`, `maiya`, `ayana`, `yakov`).
- Enabled the socket-activated `ssh-agent.socket` user service so an agent is always
  reachable at `/run/user/1000/ssh-agent.socket`.
- Loaded the `id_ed25519` key into that agent (verified against GitHub as `amiles5`).

## Hardware — Minisforum mini PC BIOS (blank screen on boot / Studio Display replug)

Not a dotfile change, but recorded here for reference since it took real investigation.

**Symptom:** on boot, the Apple Studio Display often stays blank even after login —
typing the login password blind works (session is clearly running), and the display
sometimes needs to be physically replugged to come alive. Asked whether disabling the
machine's HDMI ports in BIOS would let Thunderbolt/USB4 "take precedence" on boot.

**Root cause:** `lspci -nnk` shows the USB4/Thunderbolt controller is
`AMD Family 19h USB4/Thunderbolt PCIe tunnel [1022:14cd]` — i.e. natively integrated into
the Ryzen 9 6900HX SoC, not a discrete controller (e.g. Intel Titan Ridge) with its own
option-ROM/GOP support for pre-OS display output. Practically, this means **no picture can
ever appear on a USB4-tunnelled DisplayPort device during BIOS POST, GRUB, or early kernel
boot on this platform, regardless of HDMI state** — the DP tunnel only comes up once
Linux's `thunderbolt` driver, `bolt` authorization, and `amdgpu`'s display core have all
initialized, which lines up with the screen appearing right around when the login greeter
starts. Disabling HDMI in BIOS would not fix this — it would only remove the one output
that *can* show a picture pre-OS, with USB4 not gaining boot-time capability in exchange.

**Getting into BIOS with only the Studio Display connected:** since USB4 has no pre-OS
display, a monitor must be temporarily connected via one of the two native HDMI 2.0 ports
to see BIOS/POST/UEFI Shell output at all. Enter setup with **Del** (or **F7** for the
one-time boot menu) at power-on.

**Machine identification** (confirmed via `dmidecode`, important before flashing any
firmware):
- System Product Name: `UM690` (not `UM690S` — DMI does not report an "S" suffix)
- Baseboard Product Name: `F7BFC`
- Cross-checked against Minisforum's own product page
  (`minisforum.net/front/support/64/UM690`), titled plainly "UM690 Download", listing the
  same CPU (Ryzen 9 6900HX) and WiFi chip (AMD RZ608) as this machine — no separate
  "UM690S" BIOS line was found. **Board code `F7BFC` is the authoritative identifier for
  firmware compatibility, not the marketing SKU name on the box.**

**BIOS update found:** `F7BFC_BIOS_V1.20.zip` (in `~/Downloads/`), containing:
  - `AfuEfix64.efi` — AMI firmware update utility
  - `F7BFC120.rom` — the BIOS image itself, v1.20
  - `Flash.nsh` — flash script: `AfuEfix64.efi F7BFC120.rom /p /b /n /r /k /l /x /reboot`
  - `Release_Note.txt`, `WIN_F7BFC_BIOS_V1.20.exe` (Windows-based flasher alternative)

  Verified as the correct file for this exact board: the release notes list
  `1.16, 2023/02/15` as a prior version — an exact match to this machine's
  currently-installed BIOS version *and* date at the time of writing. Currently running
  1.16; 1.20 would be a multi-version jump (skips 1.17–1.19), which is fine for a full
  AMI image flash (not a delta patch), but worth watching for any on-screen warning from
  `AfuEfix64.efi` insisting on incremental steps.

**No-Windows flashing procedure** (from
[Intermittent Technology's Minisforum-without-Windows guide](https://blog.intermit.tech/2025/05/firmware-update-minisforum-without-windows.html/),
adapted for the files above):
  1. Get `shellx64.efi` from the
     [UEFI-Shell GitHub releases](https://github.com/pbatard/UEFI-Shell/releases)
     (2024/24H2 build or newer).
  2. FAT32-format a USB stick; copy `shellx64.efi` plus all 5 files from
     `F7BFC_BIOS_V1.20.zip` to its root.
  3. In BIOS: set an admin password if needed, then Secure Boot → Disabled, Secure Boot
     Mode → Custom, then "Restore Factory Keys". Reboot and confirm it stuck.
  4. Boot the UEFI Shell from the USB stick via the one-time boot menu.
  5. In the shell: `FS0:` (try `FS1:`/`FS2:` if that's not the USB drive), `dir` to
     confirm the files are visible, then run `Flash.nsh`.
  6. Let it flash untouched (5–10 min) — do not power off. It reboots automatically and
     does memory retraining afterward (can take several more minutes with no visible
     progress).
  7. BIOS settings reset to factory defaults after flashing — reconfigure anything
     customized (boot order, PCIe/graphics allocation, etc.) afterward.

## This repo

- Tracked: `hypr`, `kitty`, `fish`, `fastfetch`, `noctalia`, `alacritty`, `btop`,
  GTK3/4 & Qt5/6ct theming, `dolphinrc`/`kdeglobals`, `micro` (`settings.json` +
  colorschemes only), and assorted XDG files (`mimeapps.list`, `user-dirs.*`, etc).
- Deliberately excluded: `.config/mozilla` (191MB Firefox profile — history/cookies/saved
  logins), `.config/pulse` and `.config/dconf` (small binary runtime state, not really
  "config"), micro's 146 bundled default syntax-highlighting files (not user-authored), and
  `.config/joplin-desktop` (holds the actual notes `database.sqlite`, a live `api.token`
  secret in `settings.json`, and `ipc_secret_key.txt` — user data/secrets, not config).
- Pushed to `git@github.com:amiles5/ayana-cachyos.git` (branch `master`).
