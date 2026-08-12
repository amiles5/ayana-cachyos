# ayana-cachyos

Dotfiles for `ayana` — CachyOS + Hyprland (Wayland), managed with [yadm](https://yadm.io)
(`$HOME` is the yadm work tree; only selected files/dirs are tracked, see below).

This file is a running log of the configuration changes made on this machine, most recent
context at the bottom of each section.

## Keybind reference (`hypr/config/binds.lua`)

Source of truth is `binds.lua` itself — update this table when binds change.

Notation: `+` between keys means "hold together," it's not a literal key to
press. Punctuation keys (`comma`, `period`, `bracketleft`, `bracketright`,
etc.) are their unshifted form unless `SHIFT` is explicitly listed — e.g.
`SUPER + comma` is `SUPER` + the bare `,` key, not `SUPER` + `Shift` + `,`.

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
| `SUPER + SHIFT + C` / `XF86Calculator` | gnome-calculator |
| `SUPER + SHIFT + Return` | Firefox → workspace 5 |
| `SUPER + SHIFT + M` | ZapZap (WhatsApp) |
| `SUPER + SHIFT + O` | Sonos, Firefox PWA |
| `SUPER + SHIFT + P` | iCloud Photos, Flatpak |
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
| `XF86MonBrightnessUp` / `XF86MonBrightnessDown` | Brightness up/down (see note below — unreachable on the current keyboard) |
| `SUPER + bracketleft` / `SUPER + bracketright` | Brightness down/up (see note below) |

**Utilities**

| Bind | Action |
| --- | --- |
| `SUPER + P` | hyprpicker (color picker) |
| `Print` / `SUPER + Print` | Screenshot region/fullscreen (dead on the current keyboard, see note below) |
| `SUPER + comma` | Screenshot region |
| `SUPER + SHIFT + comma` | Screenshot fullscreen |
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

## Brightness — Apple Studio Display (`hypr/config/binds.lua`, `asdbctl`)

The Studio Display doesn't support DDC/CI like a normal external monitor — Apple
uses a proprietary HID protocol instead (confirmed: `ddcutil`/standard monitor
brightness APIs don't see it). Controlled via
[`asdbctl`](https://github.com/juliuszint/asdbctl), installed from the AUR
(`asdbctl` package, maintainer `mipxx`) since no AUR helper (`paru`/`yay`) is on
this system — built manually with `git clone
https://aur.archlinux.org/asdbctl.git && cd asdbctl && makepkg -si`. Ships a
udev rule (`/usr/lib/udev/rules.d/20-asd-backlight.rules`, tags the display's
`hidraw` node `uaccess`) so it works as a regular user, no sudo/group needed.

- `asdbctl get` / `asdbctl set <0-100>` / `asdbctl up` / `asdbctl down` (10%
  steps by default, `-s`/`--step` to change).
- Rebound `XF86MonBrightnessUp`/`XF86MonBrightnessDown` in `binds.lua` from
  noctalia's `brightness-up`/`brightness-down` (which targets
  `/sys/class/backlight`, empty on this machine — no internal panel, mini PC +
  external display only, so those keys were a silent no-op) to `asdbctl up`/
  `asdbctl down` directly.
- The keyboard in use (Logitech MX Keys Mechanical) has no dedicated
  display-brightness function on its F-row at all — it's lock/app-switcher/
  screenshot/media/volume instead — so those `XF86MonBrightness*` keys are
  unreachable from this keyboard regardless of the Hyprland-side binding.
  Added `SUPER + bracketleft`/`bracketright` as a reachable fallback.
- Also tried repurposing the keyboard's dedicated *illumination* up/down key
  as `SUPER + XF86KbdBrightnessUp`/`Down`. Didn't work — root-caused via
  `evtest` (installed to diagnose this, then removed again) on every input
  node the USB receiver exposes
  (`event9` main keyboard, `event11` Consumer Control, `event12` System
  Control): pressing the key produces **zero** kernel input events on any of
  them, confirming it's handled entirely in the keyboard's own firmware and
  never reaches Linux at all, regardless of what it's bound to. Reverted to
  the `SUPER + bracket` bind above.
- Both bindings now also call `noctalia msg brightness-osd <value>` after
  each change (fetching the new % from `asdbctl get`) so the change shows an
  on-screen OSD, same as volume/mic — `asdbctl` alone has no visual feedback.
- See "Screenshots" below — the same MX Keys Mechanical firmware-only-key
  situation also killed the `Print` bind.
- Since it's an AUR package, it lands in `.pkglist/pacman-foreign-aur.txt`
  (see "Package lists" section) rather than the plain pacman list — on a
  reinstall it needs the manual `git clone` + `makepkg -si` above, not
  `pacman -S`.

## Screenshots (`hypr/config/binds.lua`, `grim`/`slurp`/`satty`)

- `Print` (region) / `SUPER + Print` (fullscreen) call noctalia's
  `screenshot-region`/`screenshot-fullscreen`, which drive `grim` + `slurp`
  for capture and pipe the result into `satty` for annotation (arrows, text,
  blur, etc.) instead of saving straight to disk —
  `[shell.screenshot]` in `noctalia/config.toml`
  (`pipe_to_command = true`, `save_to_file = false`).
- `satty`'s toolbar Save button is icon-only (no text label — a small
  floppy-disk icon, tooltip "Save (Ctrl+S)" on hover), easy to miss,
  especially at this display's 3.2x scale. `Ctrl+S` works regardless of
  whether the icon is visible; `Ctrl+Shift+S` for Save As; `Ctrl+C` to copy
  to clipboard without saving at all.
- `pipe_command` now passes `-o ~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png`
  (satty supports `~` and `strftime`-style format specifiers natively in
  `-o`), so `Ctrl+S` saves straight to a timestamped file in
  `~/Pictures/Screenshots/` instead of opening a file-picker dialog every
  time (there was no `-o` before, so no default destination existed at all).
  `Ctrl+Shift+S` still opens the picker if you want a different location for
  a specific shot. Directory created (`~/Pictures/Screenshots`, empty,
  `.gitignore`-less — new files inside it obviously aren't yadm-tracked, only
  the empty dir would be were it in the tracked tree, which it isn't).
- The `Print` key is dead on the current keyboard (Logitech MX Keys
  Mechanical): confirmed via `evtest` that no key/Fn-combo on it produces a
  `KEY_PRINT` (or `KEY_SYSRQ`) event, even though the device's HID descriptor
  declares `KEY_PRINT` as a supported capability — same firmware-only-key
  situation as the keyboard-illumination key documented in "Brightness"
  above. Added `SUPER + comma` (region) / `SUPER + SHIFT + comma`
  (fullscreen) as reachable binds; kept the dead `Print` binds in case a
  future keyboard has a real PrtSc key.

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

### App-launch bind scheme

App-launch binds were rationalized onto a uniform `SUPER + SHIFT + <key>` prefix
(previously an inconsistent mix of plain `SUPER + <key>` and `SUPER + ALT + <key>`),
**except** the three most-used ones — terminal (`SUPER+Return`), file manager
(`SUPER+E`), editor (`SUPER+T`) — deliberately kept on their fast single-key
binds rather than adding a keystroke to the most common actions. Current
mapping: `SHIFT+C` calculator, `SHIFT+M` ZapZap, `SHIFT+O` Sonos, `SHIFT+P`
iCloud Photos, `SHIFT+Return` Firefox. `O` (Sonos) was picked to dodge existing non-app binds on `S` — see the Sonos
section below for specifics.

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

## iCloud — [iCloud-Linux](https://github.com/TaylanTatli/iCloud-Linux) (Flatpak)

- Third attempt at iCloud access, after the AUR Electron wrapper (dead end) and the
  firefoxpwa version (worked, but later removed — see below) documented next. This one
  is a **native** GTK4/Libadwaita app using WebKitGTK for rendering (C++, not Electron),
  distributed only as a downloadable `.flatpak` bundle attached to GitHub releases — not
  on Flathub, so `flatpak search`/`flatpak install <id>` won't find it.
- Installed the release bundle directly:
  `curl -fLO https://github.com/TaylanTatli/iCloud-Linux/releases/download/1.1.6/io.github.TaylanTatli.iCloud-Linux.flatpak`
  then `sudo flatpak install --system io.github.TaylanTatli.iCloud-Linux.flatpak`
  (system-wide, matching how ZapZap is installed). Pulled `org.gnome.Platform/x86_64/50`
  as a runtime dependency from the existing `flathub` remote; no extra remote was added
  for the app itself (bundle installs don't need one to keep working, only to auto-update
  — reinstall the same way for updates).
- Unlike the old firefoxpwa setup (one "iCloud" window for everything), this one exports
  a **separate launcher entry per service** — Mail, Calendar, Photos, Drive, Notes,
  Reminders, Contacts, Find, Pages, Numbers, Keynote — each its own
  `io.github.TaylanTatli.iCloud-Linux.<Service>.desktop`, all showing up individually in
  the noctalia app launcher (`SUPER + Space`). No dedicated keybind, same as before.
- Flatpak app data isn't yadm-tracked (same reasoning as ZapZap's `~/.var/app/...`
  exclusion) — nothing user-specific to track here anyway, install state lives in
  `.pkglist/flatpak.txt`.
- Bound `SUPER + SHIFT + P` to Photos specifically (the exact `Exec=` line from
  `io.github.TaylanTatli.iCloud-Linux.Photos.desktop`, no workspace targeting).
  Originally `SUPER + ALT + P` since plain `SUPER + P` was already taken by
  hyprpicker; moved to the `SUPER + SHIFT` scheme along with the rest of the
  app-launch binds (see "App launch" section below). Verified live: launches the
  "iCloud Photos" window correctly. No binds for the other services
  (Mail, Calendar, etc.) — launcher-only, same as before.
- Not yet signed in — installed, launcher entries and the Photos keybind confirmed
  working, but the actual iCloud login flow hasn't been exercised yet.

### Earlier attempts (history)

- No official iCloud Linux client exists. Tried the AUR `icloud-for-linux-git` package
  (unmaintained Electron wrapper around icloud.com, github.com/wmwnuk/icloud-for-linux,
  flagged out-of-date since Aug 2024) — its build fails on this system because npm 12's
  new script-allowlist blocks Electron's `postinstall`, and the old
  `extract-zip`-based Electron/electron-packager toolchain (pinned to Electron 21,
  ~2022-era) stalls mid-extraction against this system's Node v26 runtime — confirmed
  by cross-checking the project's (mislabeled) "flatpak" fork, which is actually a Snap
  manifest pinned to `node/16/stable`, i.e. the same fix, just via an even heavier path
  (snapd isn't installed here and isn't native to Arch/CachyOS). **Worth knowing if
  iCloud access is wanted again: don't retry this path, it's a dead end as-is.**
  Installed instead via `firefoxpwa` (Mozilla's native-PWA tooling — no Electron
  build involved), the same tooling used for WhatsApp/Sonos below.
- Later removed entirely (`firefoxpwa site uninstall <id>` +
  `firefoxpwa profile remove <id>`, dedicated profile since it wasn't shared with
  any other PWA), plus the leftover `~/.local/share/icloud-pwa` staging directory
  (manifest/favicon files used only for the one-time install, never yadm-tracked).
  `firefoxpwa` itself is left installed — WhatsApp and Sonos still use it.

## WhatsApp (`hypr/config/binds.lua`)

- No official WhatsApp Linux client exists. Using **ZapZap**
  (`com.rtosta.zapzap`, Flathub — GTK4/libadwaita wrapper around web.whatsapp.com,
  built on QtWebEngine), bound to `SUPER + SHIFT + M`
  (`flatpak run com.rtosta.zapzap`, opens on the current workspace — the
  `[workspace 2]` targeting it originally launched onto was removed).
  ZapZap's flatpak data dir
  (`~/.var/app/com.rtosta.zapzap/`) is deliberately untracked in yadm, same
  reasoning as the Joplin exclusion above — live session/message data, not config.
- ZapZap has no voice/video call button — a known upstream limitation, not
  something specific to this machine (see
  [rafatosta/zapzap#199](https://github.com/rafatosta/zapzap/issues/199) and
  [#529](https://github.com/rafatosta/zapzap/issues/529)).
- Tried working around it with a second, separate **firefoxpwa** WhatsApp Web
  install (same tooling as Sonos/iCloud, full Firefox WebRTC) specifically for
  calls. Removed again (`firefoxpwa site uninstall` + `profile remove`, dedicated
  profile) — video calling turned out not to work through it either, so it wasn't
  solving the problem it was installed for. Just using ZapZap for everything now;
  no video calling on this machine currently.

## Sonos (`hypr/config/binds.lua`)

- Installed the Sonos web app (play.sonos.com) as a native firefoxpwa app, same
  pattern as iCloud/WhatsApp — real manifest at
  `https://play.sonos.com/manifest.webmanifest`, no hand-written manifest needed.
- Bound to `SUPER + SHIFT + O` (`firefoxpwa site launch 01KZQREYPXKDBAHY9JWSG975VB`,
  no workspace targeting). Originally `SUPER + ALT + S`, but both `SUPER + S`
  (scratchpad toggle) and `SUPER + SHIFT + S` (move window to special workspace)
  were already taken when the app-launch binds got rationalized onto a uniform
  `SUPER + SHIFT + <key>` scheme — kept both of those as-is and used `O` instead
  (loose mnemonic: s**O**nos) rather than displacing existing window-management
  binds.

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

## Printer — Brother HL-1210W (CUPS + `brlaser`, AirPrint)

- Discovered on the LAN via `avahi-browse -a -t -r` (mDNS): `Brother HL-1210W
  series` at `192.168.1.252` (`BRN106FD981C68E.local`), offering raw
  JetDirect (port 9100), LPD (515), and IPP (631, `ipp/print`).
- Installed `cups`, `cups-filters`, `ghostscript` (`cups-pdf` too, for an
  optional "print to PDF" virtual printer — not the point of this exercise,
  just came along with it), enabled `cups.service`.
- The Brother-provided Linux drivers are proprietary/annoying to package, so
  used [`brlaser`](https://github.com/Owl-Maintain/brlaser) instead — an open
  source driver for Brother laser printers. Installed from the AUR
  (`brlaser` package) the same way as `asdbctl`: no AUR helper on this
  system, so `git clone https://aur.archlinux.org/brlaser.git && cd brlaser
  && makepkg -si`.
- `brlaser` ships an exact PPD for this model: `lpinfo -m | grep brlaser`
  lists `drv:///brlaser.drv/br1210.ppd` → "Brother HL-1210W series". Added
  the printer with that PPD over IPP:
  `lpadmin -p Brother_HL1210W -E -v ipp://192.168.1.252/ipp/print -m
  drv:///brlaser.drv/br1210.ppd`, set as the system default (only printer on
  this machine). Confirmed reachable: both port 9100 and 631 connect, and
  the PPD's options (A4, 600dpi/1200x600dpi, toner economode/density) loaded
  correctly via `lpoptions -p Brother_HL1210W -l` — an actual test page
  wasn't sent (uses real paper/toner), so end-to-end printing itself is
  unverified.
- `lpadmin` warned "Printer drivers are deprecated and will stop working in
  a future version of CUPS" — expected for any PPD-based setup like this one
  (CUPS is pushing toward driverless IPP Everywhere); not an error, `brlaser`
  is still the correct choice since this printer's built-in IPP support may
  not be full IPP Everywhere-compliant.
- CUPS config (`/etc/cups/*`) is outside `$HOME`, so none of this is
  yadm-tracked — noted here, and in "This repo" below, so it's not forgotten
  on a reinstall. `cups`, `cups-filters`, `cups-pdf`, `ghostscript`, and
  `brlaser` are captured in `.pkglist/` instead (`brlaser` lands in the
  foreign/AUR list, needs the manual `git clone` + `makepkg -si` above to
  restore).

### AirPrint (iOS)

By default CUPS only accepts connections from `localhost`, and UFW (active,
default-deny incoming) blocks everything else anyway — so the printer was
discoverable but couldn't actually receive a job from an iPhone/iPad without
these three changes:

- `lpadmin -p Brother_HL1210W -o printer-is-shared=true` — marks the queue
  shared (`printers.conf` → `Shared Yes`).
- `/etc/cups/cupsd.conf`: `Listen localhost:631` → `Port 631`, so `cupsd`
  binds `0.0.0.0:631`/`[::]:631` instead of just loopback. Backed up first to
  `/etc/cups/cupsd.conf.bak`. Restarted `cups.service` to apply.
- `sudo ufw allow from 192.168.1.0/24 to any port 631 proto tcp comment
  'CUPS/IPP printing (AirPrint)'` — scoped to the LAN subnet, not open
  globally. mDNS itself (5353/udp) didn't need a rule; UFW's default
  `before.rules` already carves out an exception for the
  224.0.0.251/1900 multicast groups avahi/SSDP use, which is why discovery
  already worked before this — only the actual IPP job-submission port was
  blocked.
- Verified via `avahi-browse -a -t -r`: the shared queue now advertises
  itself as "Brother HL-1210W (Bramley Woods) @ ayana-7" with
  `URF=V1.4,CP1,W8,PQ4,RS600,FN3` and
  `pdl=application/pdf,application/postscript,image/jpeg,image/png,image/pwg-raster,image/urf`
  in its TXT record — the specific fields iOS's AirPrint discovery checks
  for (`URF` + `application/pdf`/`image/urf` in `pdl`). Also picked up
  `mopria-certified=1.3` for free (Android/Mopria uses the same discovery
  mechanism). CUPS generates all of this automatically from the PPD; nothing
  hand-written. Not yet tested from an actual iOS device.
- UFW rules (`/etc/ufw/*`) are outside `$HOME` too — not yadm-tracked, noted
  here and in "This repo" below. To recreate: the `ufw allow` command above.

## Text expansion — [espanso](https://espanso.org) (`espanso/`, systemd user service)

Global text-replacement (type `ema`, get `anthony.miles@gmail.com` anywhere) —
the Linux equivalent of macOS's built-in text substitution.

- No official Arch package; X11-only tools like AutoKey don't work at all under
  Wayland/Hyprland, and the mainline `espanso` AUR package isn't built with
  Wayland support. Installed the Wayland-specific AUR build instead:
  `git clone https://aur.archlinux.org/espanso-wayland.git && cd
  espanso-wayland && makepkg -si` (same manual pattern as `asdbctl`/`brlaser`
  — no AUR helper on this system). Version 2.2.1, pulls `wxwidgets-gtk3` etc.
  as build deps; `cargo`/`rustc` were already present from earlier builds.
- Config lives at `~/.config/espanso/` — `config/default.yml` (global
  settings) and `match/base.yml` (the actual trigger → replacement rules).
  Neither is auto-created by installation; had to `mkdir -p
  ~/.config/espanso/{config,match}` and hand-write both files before the
  daemon would start at all (it fails immediately with `[ERROR] unable to
  load config / Caused by: missing config directory` otherwise — this isn't
  documented anywhere obvious, tracked down by running the hidden `espanso
  daemon` subcommand directly and, when that also failed silently, capturing
  a screenshot of the GUI "Troubleshooting" window it spawns on error, which
  states the real cause plainly).
- Registered as a systemd user service (`espanso service register` — creates
  `~/.config/systemd/user/espanso.service`, `ExecStart=/usr/bin/espanso
  launcher`, enabled via `default.target`).
- **Keyboard layout bug**: first real test expanded `ema` to
  `anthony.miles"gmail.com` — `"` instead of `@`. Root cause was in the
  worker log the whole time: `unable to determine keyboard layout
  automatically, please explicitly specify it in the configuration` — on
  Wayland espanso can't reliably auto-detect the active XKB layout, so its
  EVDEV injector defaulted to US, and `@`/`"` are swapped between US and GB
  layouts at the same physical key. Fixed with an explicit
  `keyboard_layout: { layout: "gb" }` in `config/default.yml` (matches
  `hypr/config/inputs.lua`'s `kb_layout = "gb"`) — confirmed in the log
  afterward: `inject module will use this keyboard layout: [... L=gb ...]`.
- **Red herring during setup**: the daemon appeared to be repeatedly SIGKILLed
  a few seconds after every start (`systemd[860]: espanso.service: Main
  process exited, code=killed, status=9/KILL`), which looked like a
  Hyprland/Wayland compatibility crash (a real, since-fixed one exists
  upstream — [espanso/espanso#1768](https://github.com/espanso/espanso/issues/1768),
  fixed in 2.2.0, already included in this build's 2.2.1). Turned out to be
  self-inflicted: `pkill -9 -f espanso`, run repeatedly while debugging to
  clear stray manually-started test processes, matches *any* process with
  "espanso" in its command line — including the systemd-managed worker
  running in parallel. Stopped interleaving manual kills with the
  systemd-managed instance and it ran stably from the first clean restart.
- `~/.cache/espanso/espanso.log` is the real log (`espanso log` just tails
  it) — more useful than `journalctl --user -u espanso.service`, which only
  captures the `launcher` process's own start/stop, not the daemon/worker's
  actual output.
- **Known upstream bug**: an empty/blank "Espanso Sync Tool" window (class-less)
  can pop up unprompted — wxWidgets-on-Wayland rendering issue, not specific
  to this machine ([espanso/espanso#1976](https://github.com/espanso/espanso/issues/1976),
  [#2156](https://github.com/espanso/espanso/issues/2156)). First seen right
  after setting `keyboard_layout` above — #1976 specifically notes layout
  changes retrigger this tool. **Recurs on every worker restart**, not a
  one-off (confirmed across several restarts in a row). Cosmetic — doesn't
  affect actual expansion.
- Fixed with a plain static rule in `windowrules.lua`
  (`shrink-espanso-sync-tool`): `float = true` + `size = { "monitor_w*0.10",
  "monitor_h*0.10" }` + `workspace = "6"`, matched by `title`. Shrinks it to
  a small (`160x90` on this display), floating window tucked away on
  workspace 6 instead of a full `1580x845` on whatever workspace happens to
  be active — out of the way, no longer disruptive. Verified live across a
  fresh worker respawn.
  - **Two other approaches were tried first and rejected**: a static
    `hl.window_rule({ ..., close = true })` reloaded without error but did
    nothing — Hyprland has no static "close" windowrule action (`close`/
    `kill` are dispatchers only, not rule fields). An `hl.on("window.open",
    ...)` event listener that force-killed the window the instant it opened
    was worse than useless — it reproducibly *broke espanso itself* (worker
    crash, exit code 90, dying during "Querying modifier status" before
    ever reaching the injector/clipboard init — i.e. real functionality
    lost, not just the cosmetic window). Confirmed by disabling it and
    getting a clean, stable start immediately after; reverted fully rather
    than leaving it disabled-but-present. The size/float rule that's in
    place now is purely declarative (no event handling, no interaction with
    espanso's own process), which is presumably why it doesn't have the
    same problem.
  - If the window is ever reported as genuinely "not responding" (not just
    blank) and needs manually clearing: `hyprctl clients -j | jq -r '.[] |
    select(.title=="Espanso Sync Tool") | .address'`, then
    `hyprctl dispatch 'hl.dsp.focus({ window = "address:<addr>" })'`
    followed by `hyprctl dispatch 'hl.dsp.window.kill()'` (escalate to
    `kill -9 <worker-pid>`, from `pgrep -f "espanso worker"`, if that
    doesn't close it). **Don't rapid-fire this** — killing/restarting the
    worker repeatedly within a few seconds left stale `.sock` files in
    `~/.cache/espanso/` and triggered the same worker-90 crash on its own.
    Recovery: `systemctl --user stop espanso`, `rm
    ~/.cache/espanso/*.{lock,sock}`, one clean `start`, then leave it alone
    for 15+ seconds.

## Fish shell — `ls`/`la`/`ll`/`lt`/`l.` aliases (`fish/config.fish`)

- `config.fish` sources CachyOS's `/usr/share/cachyos-fish-config/cachyos-config.fish`
  (system file, package-managed, not `$HOME`/not yadm-tracked), which defines
  `ls`/`la`/`ll`/`lt`/`l.` as `eza`-based aliases by default.
- Overridden immediately after that `source` line with plain coreutils `ls`
  equivalents instead (`--color=always --group-directories-first`, no icons).
  `lt` (was `eza -aT`, a tree listing) has no direct `ls` equivalent, so it
  falls back to `ls -R -a` (recursive, not a tree).
- `ll` is `ls -latr` (all files, long format, sorted by modification time,
  oldest first/newest last) rather than the plain `ls -l` it started as — no
  `--group-directories-first` here since that would fight the time-based
  sort order that's the whole point of `-tr`.
- `eza` itself is still installed — it's a hard dependency of
  `cachyos-fish-config` (`pacman -Qi eza` → `Required By: cachyos-fish-config`),
  so removing it would cascade-remove that package too, which still provides
  other defaults via the `source` line above. Left in place; just unused now.

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
  not from a configured repo). No AUR helper (`paru`/`yay`) is installed on
  this system, so anything in this file (currently just `asdbctl` — see
  "Brightness" section above) needs to be reinstalled manually on recovery:
  `git clone https://aur.archlinux.org/<pkg>.git && cd <pkg> && makepkg -si`.
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
  and `.local/share/firefoxpwa` (bundled Firefox runtime binary + the WhatsApp/Sonos
  PWA profiles' live session/auth cookies, same class as the `.config/mozilla`
  exclusion above).
- `/etc/sddm.conf.d/autologin.conf` (`[Autologin]`, `User=milesj`,
  `Session=hyprland-uwsm`) is outside `$HOME` entirely, so yadm can't track it — noted here
  so it's not forgotten on a reinstall. Session name confirmed as `hyprland-uwsm` (not
  plain `hyprland`) via `journalctl -u sddm`, matching what SDDM actually launches.
- `/boot/limine.conf` (`timeout: 2`) is also outside `$HOME` — same reasoning as the SDDM
  autologin config above. Backup at `/boot/limine.conf.bak`.
- `/etc/cups/*` (printer queue config, added by `lpadmin` for the Brother
  HL-1210W, plus the `Listen`→`Port` edit for AirPrint) and `/etc/ufw/*`
  (the LAN-scoped port-631 rule) are outside `$HOME` too — see "Printer"
  section above for the exact commands to recreate both if lost.
  `cupsd.conf.bak` is the only backup; the rest isn't backed up anywhere.
- Pushed to `git@github.com:amiles5/ayana-cachyos.git` (branch `master`).
