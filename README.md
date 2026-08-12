# ayana-cachyos

Dotfiles for `ayana` — CachyOS + Hyprland (Wayland), managed with [yadm](https://yadm.io)
(`$HOME` is the yadm work tree; only selected files/dirs are tracked, see below).

This file is a running log of the configuration changes made on this machine, most recent
context at the bottom of each section.

## Keybind reference (`hypr/config/binds.lua`)

Source of truth is `binds.lua` itself — update this table when binds change.

**Window management**

| Bind | Action |
| --- | --- |
| `SUPER + Escape` | Kill focused window (force) |
| `SUPER + Q` | Close focused window |
| `SUPER + ALT + Space` | Toggle floating |
| `SUPER + D` | Fullscreen (mode 1) |
| `SUPER + F` | Fullscreen |
| `SUPER + J` | Toggle split layout |
| `SUPER + Left/Right/Up/Down` | Move focus |
| `ALT + Tab` | Cycle windows in current workspace, raise focused |
| `SUPER + Tab` / `SUPER + SHIFT + Tab` | Cycle to next/previous non-empty workspace on current monitor |
| `SUPER + 1..6` | Focus workspace 1–6 |
| `SUPER + SHIFT + 1..6` | Move window to workspace 1–6 |
| `SUPER + SHIFT + Left/Right/Up/Down` | Move window in direction |
| `SUPER + SHIFT + mouse up/down` | Move window to previous/next monitor |
| `SUPER + CONTROL + SHIFT + Left/Right` | Move window to workspace on previous/next monitor |
| `SUPER + CONTROL + SHIFT + mouse up/down` | Same, via scroll |
| `SUPER + SHIFT + CONTROL + 1..6` | Move window to workspace N on relative monitor |
| `SUPER + mouse:272` (left) | Drag-move window |
| `SUPER + mouse:273` (right) | Drag-resize window |
| `SUPER + Minus` / `SUPER + Plus` | Cursor zoom out/in (repeating) |
| `SUPER + keypad -` / `keypad +` | Same, via keypad |

**Launcher / apps**

| Bind | Action |
| --- | --- |
| `SUPER + Return` | Kitty → workspace 1 |
| `SUPER + E` | Dolphin (file manager) |
| `SUPER + T` | gnome-text-editor |
| `SUPER + C` / `XF86Calculator` | gnome-calculator |
| `SUPER + SHIFT + Return` | Firefox → workspace 5 |
| `SUPER + M` | ZapZap (WhatsApp) → workspace 2 |
| `SUPER + SHIFT + M` | WhatsApp Web, Firefox PWA (for calls) → workspace 2 |
| `SUPER + ALT + S` | Sonos, Firefox PWA |
| `CONTROL + SHIFT + Escape` | kitty running btop |
| `SUPER + Z` | Noctalia settings toggle |
| `SUPER + X` | Noctalia control center |
| `SUPER + Space` | Noctalia launcher |
| `SUPER + period` | Noctalia launcher, emoji picker (`/emo`) |
| `SUPER + L` | Lock session |
| `SUPER + ALT + C` | Noctalia session panel (power menu) |

**Hardware controls** (all `{ locked = true }`, work on the lock screen)

| Bind | Action |
| --- | --- |
| `XF86AudioRaiseVolume` / `XF86AudioLowerVolume` | Volume up/down |
| `XF86AudioMute` | Mute |
| `XF86AudioMicMute` | Mic mute |
| `XF86AudioPlay` / `XF86AudioPause` | Media play/pause toggle |
| `XF86AudioNext` / `XF86AudioPrev` | Media next/previous |
| `XF86MonBrightnessUp` / `XF86MonBrightnessDown` | Brightness up/down |

**Utilities**

| Bind | Action |
| --- | --- |
| `SUPER + P` | hyprpicker (color picker) |
| `Print` | Screenshot region |
| `SUPER + Print` | Screenshot fullscreen |
| `SUPER + SHIFT + W` | Wallpaper picker |
| `SUPER + V` | Clipboard history |
| `SUPER + A` | Notifications panel |

**Workspaces & monitors**

| Bind | Action |
| --- | --- |
| `SUPER + ALT + 1..6` | Focus workspace 1–6 (absolute) |
| `SUPER + CONTROL + 1..6` | Focus workspace N on relative monitor |
| `SUPER + CONTROL + Right/Left` | Focus next/previous monitor |
| `SUPER + CONTROL + Down` | Focus next empty workspace on current monitor |
| `SUPER + scroll down/up` | Focus next/previous monitor |
| `SUPER + CONTROL + scroll up/down` | Focus previous/next monitor |
| `SUPER + SHIFT + S` | Move window to special workspace (scratchpad) |
| `SUPER + S` | Toggle special workspace (scratchpad) |

## Display — Apple Studio Display (`hypr/config/monitors.lua`, `variables.lua`)

- Replaced the wildcard/auto monitor rule with an explicit pinned rule for `DP-3`
  (`MONITOR1 = "DP-3"` in `variables.lua`).
- Mode `5120x2880@60`, position `0x0`; scale was set to `2.666`, then later re-tuned
  (currently `3.2000`).
- Both HDMI ports (`HDMI-A-1`, `HDMI-A-2`) are explicitly `disabled = true` in
  `monitors.lua`, unconditionally. Without this, plugging any monitor into either HDMI
  port makes Hyprland auto-enable it and extend the desktop onto it — confirmed live via
  `hyprctl monitors` showing a second, unconfigured HDMI monitor as `disabled: false`
  alongside the Studio Display. This is a Hyprland/session-level fix, not a BIOS one — see
  the *Hardware — Minisforum mini PC BIOS* section below for why the boot-time picture
  (BIOS/GRUB) can only ever come from HDMI regardless of this setting: the Studio Display's
  USB4/Thunderbolt tunnel has no pre-OS display capability on this SoC, so this only
  controls what happens once Hyprland has loaded, not what's on screen during boot itself.

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

- Added `[idle.behavior.lock]` (`timeout = 1800`, `action = "lock_and_suspend"`,
  `enabled = true`) so the system locks and suspends automatically after 30 minutes idle.
- Deliberately left `[idle.behavior.screen-off]` disabled — no separate DPMS/screen-blanking
  behavior, only the lock-and-suspend action fires.
- Verified via Noctalia's hot-reload (`~/.cache/noctalia/noctalia.log` logged
  `config changed, reloading` immediately after the edit, no parse errors).
- Briefly changed `action` to `lock` (from `lock_and_suspend`) right after SDDM autologin was
  enabled (see *This repo* below), over concern that auto-suspending an unattended, autologin
  machine means losing the ability to remote in or otherwise regain control until someone is
  physically there to wake and unlock it. Reverted back to `lock_and_suspend` shortly after —
  accepted the tradeoff deliberately rather than leaving it lock-only.

## iCloud — native PWA via firefoxpwa

- No official iCloud Linux client exists. Tried the AUR `icloud-for-linux-git` package
  (unmaintained Electron wrapper around icloud.com, github.com/wmwnuk/icloud-for-linux,
  flagged out-of-date since Aug 2024) — its build fails on this system because npm 12's
  new script-allowlist blocks Electron's `postinstall` (worked around with
  `npm_config_dangerously_allow_all_scripts=true`, scoped to just that one `npm install`),
  and then the old `extract-zip`-based Electron/electron-packager toolchain (pinned to
  Electron 21, ~2022-era) stalls mid-extraction against this system's Node v26 runtime —
  confirmed by cross-checking the project's (mislabeled) "flatpak" fork, which is actually
  a Snap manifest pinned to `node/16/stable`, i.e. the same fix, just via an even heavier
  path (snapd isn't installed here and isn't native to Arch/CachyOS).
- Installed instead via `firefoxpwa` (`extra/firefoxpwa` / `cachyos-extra-v3/firefoxpwa`),
  Mozilla's native-PWA tooling — no Electron build involved, uses Firefox's own dedicated
  runtime instead:
  - `sudo pacman -S firefoxpwa`, then `firefoxpwa runtime install` (downloads + locally
    patches a standalone Firefox runtime for running PWAs).
  - `firefoxpwa profile create --name iCloud` — dedicated profile, isolated from the
    regular Firefox profile.
  - `firefoxpwa site install --profile <ULID> ...` installs the site. icloud.com has no
    real web app manifest, and `site install` requires an `http(s)://` manifest URL (no
    `file://`), so a minimal hand-written manifest + the site's own favicon were staged at
    `~/.local/share/icloud-pwa/{manifest.json,favicon.ico}` and served briefly over
    `python3 -m http.server` just for the install step (not needed afterward).
  - Generates `~/.local/share/applications/FFPWA-<ULID>.desktop` — shows up in the app
    launcher as "iCloud", own window class (`FFPWA-<ULID>`), no browser chrome.
- `~/.local/share/icloud-pwa` (the staged manifest/icon) is a one-time install artifact,
  not meaningful config — not yadm-tracked.

## WhatsApp (`hypr/config/binds.lua`)

- No official WhatsApp Linux client exists. Installed **ZapZap**
  (`com.rtosta.zapzap`, Flathub — GTK4/libadwaita wrapper around web.whatsapp.com,
  built on QtWebEngine) as the primary chat app, bound to `SUPER + M` (opens on
  workspace 2, `flatpak run com.rtosta.zapzap`). ZapZap's flatpak data dir
  (`~/.var/app/com.rtosta.zapzap/`) is deliberately untracked in yadm, same
  reasoning as the Joplin exclusion above — live session/message data, not config.
- ZapZap has no voice/video call button — a known upstream limitation, not
  something specific to this machine (see
  [rafatosta/zapzap#199](https://github.com/rafatosta/zapzap/issues/199) and
  [#529](https://github.com/rafatosta/zapzap/issues/529)). Real WhatsApp Web does
  support calls now, just not through ZapZap's QtWebEngine wrapper.
- Fixed by installing WhatsApp Web as a second, separate **firefoxpwa** native app
  (same tooling as the iCloud PWA above — full Firefox WebRTC, so calls work),
  bound to `SUPER + SHIFT + M` (also workspace 2,
  `firefoxpwa site launch 01KZQMBXYK6RHNHCWK5S1R1BRG`). Installed straight from
  WhatsApp Web's real manifest (`https://web.whatsapp.com/data/manifest.json`) —
  no manifest hand-writing/local HTTP server needed, unlike iCloud.
- Net result: `SUPER + M` = ZapZap for regular chatting, `SUPER + SHIFT + M` =
  WhatsApp (Firefox PWA) for voice/video calls.

## Sonos (`hypr/config/binds.lua`)

- Installed the Sonos web app (play.sonos.com) as a native firefoxpwa app, same
  pattern as iCloud/WhatsApp — real manifest at
  `https://play.sonos.com/manifest.webmanifest`, no hand-written manifest needed.
- Bound to `SUPER + ALT + S` (`firefoxpwa site launch 01KZQREYPXKDBAHY9JWSG975VB`,
  no workspace targeting). `SUPER + S` was already taken (scratchpad toggle,
  `hl.dsp.workspace.toggle_special()`) — kept that bind as-is and used
  `SUPER + ALT + S` instead rather than overriding it.

## Resume-from-suspend fixes (`hypr/config/variables.lua`, `hypr/scripts/resume-fix.sh`, systemd user service)

- Symptom: after suspend/resume (idle-triggered or manual) or a reboot, the
  Studio Display's monitor scale reset from `3.2000` to `2`, and Hyprland
  keybinds (e.g. `SUPER + Return` for kitty) stopped responding.
- Two separate causes, both stemming from the display's DP-over-Thunderbolt
  (DPIA) tunnel:
  1. **Port renumbering** (the actual scale bug): the display doesn't
     reliably come back on the same DRM connector — observed as `DP-3` in
     one boot and `DP-2` in the next (`hyprctl monitors -j`). `MONITOR1`
     in `variables.lua` was hardcoded to `"DP-3"`, so after a renumber the
     monitor rule (and the `PRIMARY_MONITOR`-based workspace/window rules
     in `workspaces.lua`/`windowrules.lua`) silently stopped matching and
     Hyprland fell back to an auto-computed scale. Fixed by switching
     `MONITOR1` to `"desc:Apple Computer Inc StudioDisplay 0xBE714649"` —
     Hyprland's EDID-description match, which is stable across
     renumbering. This is the durable fix; `monitors.lua` itself is
     unchanged (still references the `MONITOR1` variable, per its own
     "edit variables.lua instead" comment).
  2. **Slow link retrain on wake** (separate, causes stale keybinds): on
     resume the DPIA AUX channel logs ~175 `amdgpu: [drm] DPIA AUX failed`
     / `Mode Validation Warning` lines in the same second as
     `PM: suspend exit` before the link settles. `hyprctl reload`
     reapplies everything (monitors + binds) once triggered. Fixed with
     `hypr/scripts/resume-fix.sh`, which runs `gdbus monitor` against
     `org.freedesktop.login1`'s `PrepareForSleep` signal and, on
     `(false,)` (resume), waits 2s then runs `hyprctl reload`. Wired up as
     a long-running systemd `--user` service,
     `systemd/user/hyprland-resume-fix.service`
     (`WantedBy=graphical-session.target`, restarts on failure). A
     `WantedBy=sleep.target` unit was tried first but systemd user
     managers don't have a `sleep.target` by default (`enable` warned
     "added as a dependency to a non-existent unit") — the D-Bus signal
     approach is what actually works at the user-service level.
- Verified live: after applying the `desc:` match, `hyprctl reload` set
  `scale: 3.2` on the (still-renamed) `DP-2` connector immediately. The
  resume-fix service is enabled and running; the `PrepareForSleep`
  detection logic was confirmed against a manual D-Bus test but not yet
  exercised by a real suspend cycle.

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

## SDDM autologin + Studio Display boot race (`hypr/scripts/studio-display-tunnel-fix.sh`, systemd user service)

- Enabled SDDM autologin to `hyprland-uwsm` for `milesj`
  (`/etc/sddm.conf.d/autologin.conf` — see *This repo* below, outside `$HOME` so not
  yadm-tracked).
- This exposed a pre-existing Thunderbolt race: `journalctl -b` shows the Studio Display's
  DP tunnel activation failing with `not enough bandwidth` in the same second the machine's
  own USB4 retimer reports `new retimer found` — i.e. the DP tunnel gets requested before
  the retimer has finished initializing, the kernel logs it as a bandwidth problem, and
  never retries on its own. Manually typing a password at the SDDM greeter used to add just
  enough delay to dodge this; autologin removes that delay, so the display now reliably
  needs a physical unplug/replug to force a fresh tunnel-activation attempt.
- Confirmed it's not a cable/link problem — `/sys/bus/thunderbolt/devices/0-2/{rx,tx}_speed`
  already negotiate cleanly at `10.0 Gb/s x 2 lanes` (generation 3, 20 Gbps total), the
  Studio Display's own TB3-class controller's expected ceiling, and the USB side of the
  tunnel (keyboard passthrough, mic, webcam) comes up fine — only the DP/video tunnel
  specifically fails.
- Fixed with `hypr/scripts/studio-display-tunnel-fix.sh`, run once at session start via the
  `studio-display-tunnel-fix.service` systemd user unit (`WantedBy=graphical-session.target`,
  same pattern as `hyprland-resume-fix.service`): polls `hyprctl monitors -j` once/sec for up
  to 10s for the Studio Display's description; if it never shows up, finds its Thunderbolt
  device under `/sys/bus/thunderbolt/devices/*/device_name` and cycles `authorized` `0` → `1`
  (via passwordless `sudo`, since that sysfs attribute is root-only) to force the same retry a
  physical replug does, then `hyprctl reload`. Logs outcome via `logger` (tag
  `studio-display-tunnel-fix`, viewable with `journalctl --user -t studio-display-tunnel-fix`).
- First real reboot test: the DP tunnel failed the same way (`journalctl -b` showed the
  identical `not enough bandwidth` line), but the display came up on its own within the
  ~10s poll window — so the kernel *does* eventually recover by itself sometimes, just not
  reliably or quickly enough to count on, and not always (hence still keeping the forced
  reauth as a fallback). Originally used a flat `sleep 8` before the first check at all,
  which wasted time on boots that resolve faster; switched to a 1s poll loop so it reacts as
  soon as the display appears instead of always eating the full wait.
- Verified live: manually deauthorized/reauthorized the display's Thunderbolt device
  (`/sys/bus/thunderbolt/devices/0-2/authorized`) while running — the USB tunnel
  re-enumerated (keyboard/webcam/sensors) and Hyprland picked the display back up under a
  new connector name (`DP-2` → `DP-3`) without issue, since `monitors.lua` targets it by
  `desc:` rather than port name.
- **A worse, separate failure mode exists that this script can't fix.** On one boot the
  Thunderbolt device wasn't detected *at all* for 75 seconds (`journalctl -b`: nothing
  between boltd starting at `11.1s` and `thunderbolt 0-2: new device found... Apple Inc.
  Studio Display` at `75.4s`) — confirmed to be a genuine physical-link failure, not a
  logging artifact: a manual unplug/replug at ~75s is what made it appear, timestamps
  matching to the second. This is different from the "tunnel activation fails but the
  device is already enumerated" race the script targets — there's no
  `/sys/bus/thunderbolt/devices/` entry to reauthorize if the device was never discovered
  in the first place, so the script's recovery mechanism doesn't apply here. Decided against
  extending the script to cover it (would mean either a much longer poll window slowing
  down every normal boot, or a mechanism to force-rescan the Thunderbolt bus that hasn't
  been identified) — treating this as a rare, occasionally-needs-manual-replug case for now.
- **Found and fixed a false positive while investigating the above.** The script logged
  "already up, nothing to do" at `20.15s` on that same boot — 55 seconds *before* the
  display was actually detected, which shouldn't be possible. Root cause not confirmed (jq's
  handling of empty/missing `hyprctl` output was tested and ruled out), but added a debounce
  regardless: the poll loop now requires the check to pass twice in a row (1s apart) before
  trusting it, and logs the raw `hyprctl monitors -j` output if a check passes once then
  fails on recheck, so a repeat has actual forensic data instead of a guess.

## Power-on → desktop boot time (`/boot/limine.conf`)

Power button to Studio Display visible was measured at ~60s. Broken down with
`systemd-analyze`:

```
16.6s  firmware (BIOS POST)
 5.4s  loader (Limine)
 0.6s  kernel
21.9s  initrd
 9.4s  userspace (login → Hyprland graphical.target)
```

- **Limine timeout**: reduced from `5` to `2` in `/boot/limine.conf` (`timeout: 2`), saves
  ~3s. Outside `$HOME` so not yadm-tracked — see *This repo* below. Backed up first to
  `/boot/limine.conf.bak`. Confirmed safe to hand-edit: Secure Boot is disabled and
  `ENABLE_ENROLL_LIMINE_CONFIG` (config-checksum protection) isn't set, and the header
  settings (`timeout:`/`default_entry:`/`remember_last_entry:`/theme) aren't touched by
  `limine-entry-tool` — it only rewrites the per-kernel entry blocks, so this survives
  kernel updates.
- **Firmware (16.6s)**: BIOS POST, not controllable from software here without risking the
  HDMI-for-BIOS-access setup already documented above.
- **initrd (21.9s) — investigated, not fixed**: nearly the entire initrd phase is a single
  stall, not many small delays. `journalctl -b -o short-monotonic` shows the last log line
  at `[4.525s]` (amdgpu/KMS init finishing), then nothing until `[22.39s]`:
  ```
  xhci_hcd 0000:07:00.0: Abort failed to stop command ring: -110
  xhci_hcd 0000:07:00.0: xHCI host controller not responding, assume dead
  xhci_hcd 0000:07:00.0: HC died; cleaning up
  ```
  `0000:07:00.0` is an **Intel JHL7440 "Titan Ridge" Thunderbolt 3 controller**
  (`lspci -nnk`) — a genuine discrete TB3 chip, which is notable on its own: the earlier
  *Hardware — Minisforum mini PC BIOS* investigation above concluded there's no discrete
  controller, only the AMD SoC's integrated USB4 (seen separately as
  `0000:36:00.5`/domain0 elsewhere in this doc) — worth revisiting that conclusion at some
  point, but out of scope here. The controller's xHCI command ring hangs for ~18s, the
  kernel declares it dead and resets it, and everything downstream re-enumerates fine
  afterward — a known general class of Linux/xHCI bug (command-ring timeouts on
  Thunderbolt-attached xHCI controllers at boot).
  - **Tested and ruled out device-tied causes.** There are two Logitech receiver dongles:
    one in a native USB-A port directly on the UM690 (enumerates on a completely different
    controller, `0000:01:00.0`, instantly at `~1s` — almost certainly there specifically for
    keyboard/mouse during BIOS access over HDMI, since the Titan Ridge/Thunderbolt path
    isn't available that early) and one in the Studio Display's own USB hub (tunnelled
    through Thunderbolt, i.e. through the same `0000:07:00.0` that hangs). Rebooted with the
    UM690's dongle physically unplugged the entire boot: the hang still happened at the
    identical timestamp (`22.42s` vs `22.39s`/`22.45s` on two prior boots), and the Studio
    Display's dongle (the only device that ever attaches to `0000:07:00.0`) doesn't even
    enumerate until `27.57s` — *after* the hang already resolved. So the hang isn't caused by
    anything attached to the controller; it's inherent to the chip/driver's own boot-time
    init, matching a kernel mailing list report of the same Titan-Ridge-class symptom
    occurring "even without USB4 peripherals plugged in."
  - **Tried `pcie_aspm=off` as a one-off boot test.** Added it to just the `linux-cachyos`
    entry's `cmdline` in `/boot/limine.conf` (backed up first, reverted immediately after),
    rebooted, confirmed it took effect (`PCIe ASPM is disabled` in the kernel log) — no
    change: hang still at `22.459s`, indistinguishable from every untouched boot. Kernel log
    also showed ACPI FADT already reports ASPM as unsupported/BIOS-disabled on this board
    regardless of the parameter, so there was nothing for it to actually change here — a
    clean negative result, not an inconclusive one.
  - No fix confirmed safe for this exact chip was found. Left alone deliberately —
    kernel-parameter/quirk changes risk an unbootable system, unlike everything else in this
    doc, and 18s isn't worth that risk.
- Net result of this investigation: power-on-to-desktop measured at **50.9s**, down from the
  original ~60s (`systemd-analyze`: 16.4s firmware + 2.4s loader + 0.6s kernel + 21.9s initrd
  + 9.5s userspace), almost entirely from the Limine timeout cut — the initrd hang is
  unchanged and understood to be structural, not a regression from anything in this repo.

## Package lists (`.pkglist/`) — system recovery

- `pacman-explicit.txt` — output of `pacman -Qqe` (explicitly installed native
  packages; excludes dependencies pulled in automatically). To restore on a
  fresh install: `sudo pacman -S --needed - < ~/.pkglist/pacman-explicit.txt`.
- `pacman-foreign-aur.txt` — output of `pacman -Qqm` (foreign/AUR packages, i.e.
  not from a configured repo). Currently empty — no AUR helper (`paru`/`yay`)
  is installed and everything on this system comes from CachyOS/Arch repos.
  Kept so it's not forgotten if that changes.
- `flatpak.txt` — output of `flatpak list --app --columns=application`
  (currently just `com.rtosta.zapzap` — WhatsApp). Restore with
  `flatpak install flathub $(cat ~/.pkglist/flatpak.txt)`.
- `update.sh` — regenerates all three files from current system state.
  Run automatically **weekly** by the `pkglist-update.timer` systemd user
  unit (`pkglist-update.{service,timer}`, `WantedBy=timers.target`; no cron
  daemon is installed on this system, so a systemd timer is the equivalent).
  Check next/last run: `systemctl --user list-timers pkglist-update.timer`.
  The timer only regenerates the files — it does **not** `yadm add`/commit/push
  automatically (didn't want unreviewed commits happening unattended). Still
  need to run `yadm add .pkglist` + commit + push by hand to actually capture
  a change; `Persistent=true` means a missed weekly run (machine off) fires
  once at next boot instead of being skipped.

## This repo

- Tracked: `hypr`, `kitty`, `fish`, `fastfetch`, `noctalia`, `alacritty`, `btop`,
  GTK3/4 & Qt5/6ct theming, `dolphinrc`/`kdeglobals`, `micro` (`settings.json` +
  colorschemes only), assorted XDG files (`mimeapps.list`, `user-dirs.*`, etc), and
  `.pkglist` (package lists for recovery — see "Package lists" section below).
- Deliberately excluded: `.config/mozilla` (191MB Firefox profile — history/cookies/saved
  logins), `.config/pulse` and `.config/dconf` (small binary runtime state, not really
  "config"), micro's 146 bundled default syntax-highlighting files (not user-authored),
  `.config/joplin-desktop` (holds the actual notes `database.sqlite`, a live `api.token`
  secret in `settings.json`, and `ipc_secret_key.txt` — user data/secrets, not config),
  and `.local/share/firefoxpwa` (bundled Firefox runtime binary + the iCloud PWA's live
  profile — session/auth cookies, same class as the `.config/mozilla` exclusion above).
- `/etc/sddm.conf.d/autologin.conf` (`[Autologin]`, `User=milesj`,
  `Session=hyprland-uwsm`) is outside `$HOME` entirely, so yadm can't track it — noted here
  so it's not forgotten on a reinstall. Session name confirmed as `hyprland-uwsm` (not
  plain `hyprland`) via `journalctl -u sddm`, matching what SDDM actually launches.
- `/boot/limine.conf` (`timeout: 2`) is also outside `$HOME` — same reasoning as the SDDM
  autologin config above. Backup at `/boot/limine.conf.bak`.
- Pushed to `git@github.com:amiles5/ayana-cachyos.git` (branch `master`).
