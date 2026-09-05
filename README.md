# ayana-cachyos

Dotfiles for `ayana` — CachyOS + Hyprland (Wayland), managed with [yadm](https://yadm.io)
(`$HOME` is the yadm work tree; only selected files/dirs are tracked, see below).

This file is a running log of the configuration changes made on this machine, most recent
context at the bottom of each section.

## Full rebuild from a CachyOS boot disk

Disaster-recovery runbook for rebuilding `ayana` from nothing but this repo and a CachyOS
ISO. Confirmed disk/bootloader facts below are read from the live system (`findmnt`,
`btrfs subvolume list`, `pacman -Qs`), not guessed.

**1. Boot media & installer choices**

- ISO: **CachyOS Desktop, Hyprland edition** (or a generic CachyOS ISO, selecting the
  `cachyos-hypr-noctalia` package group at the desktop-environment step — that's the exact
  meta-package installed on this machine, pulling in Hyprland + Noctalia + everything this
  repo's `hypr`/`noctalia` config depends on).
- Kernel: `linux-cachyos` (the BORE-scheduler CachyOS kernel) as primary. This machine also
  keeps `linux-cachyos-lts` installed as a fallback boot entry — add it via
  `cachyos-kernel-manager` after first boot if the installer doesn't offer a second kernel.
- Locale/keyboard: `en_GB.UTF-8`, keyboard layout **GB**, model **pc105** (*not* an Apple/Mac
  layout, even though the display is a Studio Display — the physical keyboard is a Logitech
  MX Mechanical; see *Input / keyboard model* below for what picking the wrong model breaks).
- User: `milesj`.

**2. Partitioning — match the existing layout exactly**

| Partition | Size | Filesystem | Mount |
| --- | --- | --- | --- |
| 1 (ESP) | ~4GiB | FAT32 | `/boot` (not `/boot/efi` — CachyOS mounts the ESP directly at `/boot`) |
| 2 | rest of disk | Btrfs | `/` |

No separate swap partition — this machine uses `zram` (swap-on-compressed-RAM), configured
automatically by `cachyos-settings`, not a disk partition.

For the Btrfs partition, use the installer's **automatic subvolumes + Snapper** preset
rather than hand-crafting subvolumes — it produces exactly this layout (verified live):

```
@         →  /
@home     →  /home
@root     →  /root
@srv      →  /srv
@cache    →  /var/cache
@tmp      →  /var/tmp
@log      →  /var/log
.snapshots (holds Snapper's numbered snapshot subvolumes)
```

Mount options on every subvolume: `noatime,compress=zstd:1,ssd,discard=async,space_cache=v2`.

**3. Bootloader**

**Limine**, not GRUB or systemd-boot — select it explicitly if the installer offers a
choice. The installer's default Snapper integration already wires up `limine-snapper-sync`
(confirmed installed: `limine`, `limine-mkinitcpio-hook`, `limine-snapper-sync`, `snapper`,
`snap-pac`, `cachyos-snapper-support` — all part of the standard CachyOS Btrfs+Limine
preset, nothing hand-installed here). After first boot, re-apply the boot-time tweak from
*Power-on → desktop boot time* below (`timeout: 2` in `/boot/limine.conf`) — it's outside
`$HOME` so the installer's default (`timeout: 5`) comes back on a fresh install.

**4. First boot — get the dotfiles**

```sh
sudo pacman -S --needed yadm github-cli
gh auth login                     # browser/device flow, sets up the git credential helper
yadm clone https://github.com/amiles5/ayana-cachyos.git
```

(No `yadm encrypt`/secrets are used in this repo — see *This repo* below for the full list
of what's deliberately excluded instead. Everything cloned is safe to apply immediately.)

**5. Restore packages**

```sh
# Native packages (explicitly installed, excludes pulled-in deps)
sudo pacman -S --needed - < ~/.pkglist/pacman-explicit.txt

# AUR/foreign packages — no paru/yay on this system, build each manually:
for pkg in $(cat ~/.pkglist/pacman-foreign-aur.txt); do
    git clone "https://aur.archlinux.org/$pkg.git" "/tmp/$pkg" && \
    (cd "/tmp/$pkg" && makepkg -si)
done

# Flatpaks
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub $(cat ~/.pkglist/flatpak.txt)
```

**Firefox PWAs are not captured by any pkglist** (WhatsApp Web, Sonos) — reinstall them
per the *WhatsApp* and *Sonos* sections below. **Important**: `firefoxpwa site install`
generates a fresh random site ID every time, so the new IDs will **not** match the ones
currently hardcoded in `hypr/config/binds.lua` (`FFPWA-01M00K4G8CW4N60N8Q6G1BF8QB` for
WhatsApp, `FFPWA-01KZQREYPXKDBAHY9JWSG975VB` for Sonos) or `hypr/config/windowrules.lua`'s
matching auto-workspace rules. After reinstalling each PWA, run `firefoxpwa profile list`
to get the new ID and update both files' `FFPWA-<ID>`/launch-command references before
those binds and auto-workspace rules will work again.

**6. System-level config outside `$HOME`**

None of this is yadm-tracked (yadm's work tree is `$HOME`) — recreate by hand, referencing
the full detail in each linked section:

| File/action | Purpose | Detail |
| --- | --- | --- |
| `/etc/sddm.conf.d/autologin.conf` | Autologin to `hyprland-uwsm` as `milesj` | *SDDM autologin* section |
| `/boot/limine.conf` `timeout: 2` | Faster boot | *Power-on → desktop boot time* section |
| `/etc/udev/hwdb.d/70-logitech-uk-102nd.hwdb` + `sudo systemd-hwdb update && sudo udevadm trigger` | Logitech 102nd-key remap | *Input / keyboard model* section |
| `lpadmin -p Brother_HL1210W ...` (CUPS) + `/etc/cups/cupsd.conf` `Listen`→`Port` | Printer + AirPrint | *Printer* section |
| `sudo ufw allow from 192.168.1.0/24 to any port 631 proto tcp` | Let AirPrint through the firewall | *Printer → AirPrint* section |

**7. Services to enable**

```sh
sudo systemctl enable --now bolt.service cups.service tailscaled.service
systemctl --user enable --now ssh-agent.socket pkglist-update.timer \
    hyprland-resume-fix.service studio-display-tunnel-fix.service
```

**8. Noctalia plugin & GUI-managed state**

`~/.local/share/noctalia/plugins/sonos-control` comes along automatically with the yadm
clone (it's inside `$HOME`), but plugin *enablement* lives in the untracked
`~/.local/state/noctalia/settings.toml` — re-enable it with
`noctalia msg plugins enable milesj/sonos-control`. Also update the speaker IPs hardcoded
in `service.luau` if the LAN has changed since — see *Noctalia shell → Sonos control*
below. More generally: expect `~/.local/state/noctalia/settings.toml` to start from
noctalia's own defaults, not this machine's tuned state — re-apply anything from the
*Noctalia shell — bar widgets, plugins, and the config/state split* section that matters
(weather location, bar widget layout, etc.) via the Settings GUI, since `config.toml` alone
doesn't fully determine the live bar layout.

**9. Reboot and verify**

`hyprctl monitors` (scale `3.2000` on the Studio Display, EDID-matched not port-matched),
`hyprctl binds -j` (spot-check a few keybinds), `systemctl --user list-timers`, and
`lpstat -v` (printer). Re-run the PTZ camera framing tune from *Camera framing* below if
using the webcam — those values don't persist across a fresh install any more than they
persist across a reboot on the current one.

## Keybind reference (`hypr/config/binds.lua`)

Source of truth is `binds.lua` itself — update this table when binds change. A generated,
side-by-side comparison against the `aerospace-config` (macOS) keymap also exists as a
published Claude Artifact ("Mirrored Keymap") — a static snapshot, regenerate on request
rather than trusting it to auto-track this table.

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
| `SUPER + ALT + Left/Right` | Resize the split boundary between two tiled windows (20px steps, repeating) |
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
| `SUPER + SHIFT + M` | WhatsApp Web, Firefox PWA → workspace 2 |
| `SUPER + SHIFT + U` | Sonos, Firefox PWA → workspace 6 |
| `SUPER + SHIFT + P` | iCloud Photos, Flatpak |
| `SUPER + SHIFT + N` | Joplin → workspace 4 |
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
- `MONITOR1` was later switched from a fixed port name to an EDID-description match
  (`desc:Apple Computer Inc StudioDisplay 0xBE714649`) to survive connector renumbering —
  see *Resume-from-suspend fixes* below for why.

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

### Camera & mic access verified

- Camera: detected via the standard `uvcvideo` driver (no proprietary driver
  needed) as `Studio Display: Studio Display`, exposing `/dev/video0` (main,
  1664x1248 MJPEG) and `/dev/video1` (metadata). User is already in the
  `video` group, so apps (browser, video-call clients, etc.) get access with
  no extra setup. Verified live by capturing an actual frame with `ffmpeg`.
- Mic: detected via `snd_usb_audio` as PipeWire source
  `alsa_input...Studio_Display...mono-fallback` ("Studio Display Mono"),
  mic port active. Verified live with a short `parec` recording — measured
  mean -38 dB / peak -24.8 dB (real ambient signal, not silence). A second
  check later measured mean -13.8 dB / peak -0.9 dB — noticeably hotter,
  close to clipping. Flagged but left untouched (no gain adjustment made) —
  revisit if audio calls sound distorted.
- Test captures were deleted immediately after each verification (a photo/
  audio of the room, not something worth keeping around) — except one
  deliberate snapshot explicitly saved to `~/Downloads` on request.

### Camera framing — real UVC pan/tilt/zoom controls

The initial test snapshot was dark and off-center. Investigated whether the
camera exposes any framing/exposure controls:

- `v4l2-ctl -d /dev/video0 --list-ctrls` confirmed the Studio Display exposes
  genuine hardware PTZ over standard UVC controls: `pan_absolute`,
  `tilt_absolute`, `zoom_absolute` — settable with `v4l2-ctl --set-ctrl=`.
  **No exposure/brightness/gain control exists at all**, even after forcing
  `auto_exposure=1` (Manual Mode) — no new controls appeared. The dark image
  is a closed auto-exposure black box; only fixable via lighting changes or
  an external gamma-correction pipeline (not built).
- Framing was tuned live: `qv4l2` gives a preview + control panel (has to be
  launched with `setsid nohup qv4l2 -d /dev/video0 ... &` — plain
  backgrounding died between terminal calls). `pan_absolute`'s huge range
  renders as a spin-box rather than a slider in `qv4l2`, so pan was tuned by
  hand via `v4l2-ctl --set-ctrl` with live visual feedback instead, in
  ~500,000-unit nudges. `tilt_absolute` was tuned by bisecting the range
  based on "too high"/"too low" feedback.
- Final values: `pan_absolute=1000800`, `tilt_absolute=-1440000`,
  `zoom_absolute=300` (maxed at the control's range ceiling). **Not
  persisted** — resets on reboot/replug; deliberately left that way rather
  than wiring up a restore script.
- Other webcam apps evaluated/installed via Flatpak: **Cameractrls** and
  **Facetracker** (per-request install), **Webcamoid** (broader
  compositing/effects tool). All confirmed working, left installed but not
  set to autostart — `.pkglist/flatpak.txt`.

## App launch → workspace targeting (`hypr/config/binds.lua`, `hypr/config/windowrules.lua`)

- `SUPER+Return` launches kitty directly onto workspace 1: `[workspace 1] ... kitty`.
- `SUPER+SHIFT+Return` launches Firefox directly onto workspace 5: `[workspace 5] ... firefox`
  (this bind replaced the old `SUPER+W` Firefox launcher).

### App-launch bind scheme

App-launch binds were rationalized onto a uniform `SUPER + SHIFT + <key>` prefix
(previously an inconsistent mix of plain `SUPER + <key>` and `SUPER + ALT + <key>`),
**except** the three most-used ones — terminal (`SUPER+Return`), file manager
(`SUPER+E`), editor (`SUPER+T`) — deliberately kept on their fast single-key
binds rather than adding a keystroke to the most common actions. Current
mapping: `SHIFT+C` calculator, `SHIFT+M` WhatsApp Web, `SHIFT+U` Sonos, `SHIFT+P`
iCloud Photos, `SHIFT+N` Joplin, `SHIFT+Return` Firefox.

### Auto-assigned workspaces (`windowrules.lua`)

Mirrors `amiles5/aerospace-config`'s `on-window-detected` rules — apps land on
the same workspace whether launched via keybind, the app launcher, or a
notification click, not just when using the dedicated bind:

| Workspace | App (Hyprland class match) |
| --- | --- |
| 1 | kitty |
| 2 | WhatsApp Web (`FFPWA-01M00K4G8CW4N60N8Q6G1BF8QB`) |
| 3 | iCloud Photos |
| 4 | Joplin (`joplin-app-desktop`) |
| 5 | Firefox / Zen |
| 6 | Sonos (`FFPWA-01KZQREYPXKDBAHY9JWSG975VB`) |

macOS-only apps in the aerospace-config source with no Linux equivalent installed
(Finder, FaceTime, Moneydance, System Preferences, Logi Options+) are intentionally
not mirrored here. Window classes were verified live via `hyprctl clients -j`, not
guessed from `.desktop` file hints — Joplin's `StartupWMClass` in particular is
wrong (`@joplin/app-desktop`), the real class is `joplin-app-desktop`.

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

## Split-boundary resize (`hypr/config/binds.lua`)

`SUPER + ALT + Left/Right` moves the split boundary between two tiled windows (grows/
shrinks the active window against its neighbor), 20px steps, repeating. `SUPER+Left/Right`
was already focus-switching, so this couldn't reuse that combo — `ALT` was free and matches
the existing `mainMod + ALT` pattern used elsewhere for secondary actions.

Uses `hl.dsp.window.resize({ x, y, relative = true })` — this custom Lua-based Hyprland
config layer reinterprets `hyprctl dispatch` arguments as Lua source, so classic
`hyprctl dispatch resizeactive <dx> <dy>` CLI syntax doesn't work here; had to find the
actual table signature (`{ x, y, relative?, window? }`) by testing directly via
`hyprctl dispatch 'hl.dsp.window.resize(...)'` and reading the resulting error messages.

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
- There's also a named `gaming` workspace (`name:gaming`) for Steam/games, not part of
  the numbered 1–6 set.
- **Random startup-workspace bug, fixed**: Hyprland occasionally started on the `gaming`
  workspace (or an unexpected numbered one) instead of workspace 1. Root cause: the
  `gaming` workspace rule *and* all six numbered workspace rules were marked
  `default = true` on the same monitor — only one `default` can actually win per monitor,
  and which one did was effectively random across boots. Fixed by removing
  `default = true` from the `gaming` rule only, leaving workspace `1` as the sole default.
  Verified via a full `systemctl reboot` — confirmed starting on workspace 1 afterward.

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
- Added `kb_options = "terminate:ctrl_alt_bksp"` and `kb_rules = "evdev"`, discovered
  missing during a comparison against `amiles5/ayana-nixos`'s equivalent Hyprland input
  block (same machine, separate NixOS install on another SSD, not yet booted into). The
  `terminate` option gives a Ctrl+Alt+Backspace session-kill escape hatch that existed on
  nixos but not here.
- **Logitech 102nd-key remap** (also found missing via the same nixos comparison): on this
  Logitech UK keyboard, the key left of `1` reports as `grave` (HID usage `0x70035`)
  instead of the expected ISO 102nd-key position. Fixed with a udev hwdb rule —
  `/etc/udev/hwdb.d/70-logitech-uk-102nd.hwdb` (`evdev:input:*` /
  `KEYBOARD_KEY_70035=102nd`), applied via `sudo systemd-hwdb update && sudo udevadm
  trigger`. **Outside `$HOME`, not yadm-tracked** — see *This repo* below.

## Idle → lock screen (`noctalia/config.toml`)

- Added `[idle.behavior.lock]` (`action = "lock_and_suspend"`, `enabled = true`) so the
  system locks and suspends automatically after a period of inactivity. Timeout started
  at `1800` (30 min), later increased to `3600` (60 min).
- Deliberately left `[idle.behavior.screen-off]` disabled — no separate DPMS/screen-blanking
  behavior, only the lock-and-suspend action fires.
- Verified via Noctalia's hot-reload (`~/.cache/noctalia/noctalia.log` logged
  `config changed, reloading` immediately after the edit, no parse errors).
- Briefly changed `action` to `lock` (from `lock_and_suspend`) right after SDDM autologin was
  enabled (see *This repo* below), over concern that auto-suspending an unattended, autologin
  machine means losing the ability to remote in or otherwise regain control until someone is
  physically there to wake and unlock it. Reverted back to `lock_and_suspend` shortly after —
  accepted the tradeoff deliberately rather than leaving it lock-only.
- **Bug found and fixed (2026-09-05): resume-from-suspend leaves the Studio Display
  permanently black.** After that day's `pacman -Syu` (kernel `linux-cachyos` 7.1.8 → 7.2.2,
  plus `mesa` 26.1.6→26.2.2 and `aquamarine` 0.14.0→0.15.0), auto-suspend triggered twice and
  both times the machine came back from S3 at the OS level fine (`journalctl`: `PM: suspend
  exit`, GPU/SMU resumed) but the display never lit up — repeated `amdgpu ...: [drm] DPIA AUX
  failed on 0xf0000(10), error 7` in the kernel log, meaning the Studio Display's
  DisplayPort-over-Thunderbolt (DPIA) link never retrains on wake. No keypress or cable
  replug recovers it since the machine is genuinely awake behind a dead link, not asleep —
  the only way out was a power-cycle, which (correctly, since it's a real button press)
  triggers `systemd-logind`'s default poweroff-on-short-press and kills the session outright.
  - **Root cause, found by elimination:** `journalctl -b -N` on boots from *before* the
    update (Sept 2, Sept 4) showed the exact same `DPIA AUX failed` kernel message on every
    prior suspend/resume — it's a pre-existing, harmless quirk of this Thunderbolt link that
    `resume-fix.sh`'s `hyprctl reload` had always successfully papered over. So the AUX
    hiccup itself isn't new; what broke is *recovery* from it. Confirmed the kernel was
    innocent by reproducing the identical failure on three kernels (7.2.2, `linux-cachyos-lts`
    6.18.48, and 7.1.8 — the exact pre-update kernel). Downgrading the Hyprland
    display-backend stack instead — `aquamarine` 0.14.0-2.1, `hyprland` 0.56.2-1,
    `hyprtoolkit` 0.5.4-4.1, `mesa`/`opencl-mesa`/`vulkan-radeon`/
    `vulkan-mesa-implicit-layers` (+ `lib32-*` variants) 26.1.6-1, all from cached packages —
    fixed it: same `DPIA AUX failed` message on resume, but the display recovered and the
    session survived.
  - **Fix:** kernel left on current (7.2.2 — cleared, no reason to run an old one).
    `aquamarine`/`hyprland`/`hyprtoolkit`/`mesa` (+ split/`lib32` packages) downgraded to
    their pre-2026-09-05 versions and pinned via `IgnorePkg` in `/etc/pacman.conf` so the next
    `pacman -Syu` doesn't silently reintroduce the regression. **Before ever removing that
    pin**, check upstream changelogs for a fix to Hyprland/aquamarine's DRM output
    reinitialization on resume, then re-test suspend/resume before trusting it unattended
    again. `idle.behavior.lock.action` restored to `lock_and_suspend`.

## Noctalia shell — bar widgets, plugins, and the config/state split

Noctalia has **two** relevant TOML files, and it's easy to edit the wrong one:

- `~/.config/noctalia/config.toml` — declarative, **yadm-tracked**, source of truth for a
  fresh install.
- `~/.local/state/noctalia/settings.toml` — runtime state written by the Settings GUI,
  **not yadm-tracked** (lives under `.local/state`, which yadm doesn't sweep in). For any
  table/key the GUI has ever touched (e.g. `[bar.default]`'s widget arrays, `[widget.clock]`
  format, `[widget.workspaces]`), the state file's value wins at runtime over `config.toml`.

This means `config.toml` can silently drift from what's actually running whenever the
Settings UI is used instead of hand-editing the file. A full audit found and fixed several
places where this had already happened: `bar.default.end` (the `media` widget had been
removed and `notifications` wrapped in a capsule group via the GUI, but `config.toml` still
had the old arrangement), `widget.clock`'s date format (live was UK `d/m/y`, tracked config
still said US `m/d/y`), `widget.workspaces` (`show_labels`/`pill_scale`/`label_source`/
`labels_only_when_occupied` all stale), and three whole tables that existed only in the
state file with no tracked equivalent at all: `[nightlight]`, `[wallpaper]` (directory,
automation settings, and the static per-monitor paths — deliberately **not** tracking
`wallpaper.default`/`wallpaper.last`/`wallpaper.monitors.DP-2`, since automation cycles
DP-2's wallpaper every 120s and pinning that would just be stale noise), and
`[lockscreen_widgets]` (a full 4-monitor login-box layout, currently `enabled = false`).
**Practical takeaway**: after using the Settings GUI for anything bar/widget/wallpaper/
lockscreen-related, check `yadm diff .config/noctalia/config.toml` isn't silently missing
the change — the GUI doesn't write there.

Separately, `noctalia config validate` also flagged three plain **deprecated setting
names** early on (fixed via `noctalia config export full` to find the current key names):
`[widget.temp]`/`[widget.sysmon_2]` `show_label` → `show_value`, and `[widget.workspaces]`
`display = "none"` → `show_labels = false` (later revised again by the GUI drift above).

### Weather widget

Added `weather` to `bar.default.center`, right after `clock` with a `spacer` gap
(`[widget.weather]`, `type = "weather"`; `[location] address = "old alresford uk"`).
The address is deliberately a plain place-name string, not a full postcode — a stricter
`"Old Alresford, SO24 9DR, UK"` query broke geocoding entirely (showed "No location" in
the bar) despite being more precise; reverted to the original string, which already
resolves correctly to the right village via the cached `~/.cache/noctalia/location.json`
lookup (lat/lon `51.11542, -1.14211`) and is precise enough for weather.

### Sonos control (local noctalia plugin)

`~/.local/share/noctalia/plugins/sonos-control/` (**yadm-tracked** — unlike
`.local/state`, `.local/share` is inside the yadm work tree). Talks **directly** to each
Sonos speaker's local UPnP/SOAP control endpoint on port 1400 — no cloud account, no
bridge process, no Python dependency. Three entries declared in `plugin.toml`
(`plugin_api = 9`):

- **`service.luau`** (headless) — the single source of truth. Polls all three rooms every
  5s (transport state, track title, volume, group-coordinator) and publishes to
  `noctalia.state`; handles every command (`sonos.cmd`) from the bar/panel — play/pause,
  volume, switch active room, join/leave a group, refresh favourites, play a favourite.
  Neither UI file talks to a speaker directly.
- **`bar.luau`** — thin widget, just watches state and renders. **Click** toggles
  play/pause on the active room, **scroll** adjusts its volume (±2%/step), **right-click**
  opens the panel.
- **`panel.luau`** — opened via `noctalia.togglePanel(...)`. Room switcher (tap a room to
  make it "active"), a grouping toggle per non-active room ("grouped with the active
  room?"), play/pause + a volume slider for the active room, and a scrollable list of
  Sonos Favourites to tap and play.
- Speaker IPs/RINCON ids hardcoded in `service.luau`, discovered via `avahi-browse -a -t`
  (`_sonos._tcp`): Bedroom `192.168.1.181`, Dining `192.168.1.194`, Kitchen `192.168.1.204`,
  Living Room `192.168.1.227` (this 4th speaker was added to the household after the
  plugin's initial build and was invisible to it until fixed — the room list isn't
  auto-discovered, so a new physical speaker needs a manual entry added here).
- **Auto-pause on host audio**: watches `pactl list sinks short` for the Studio Display's
  own analog-stereo sink (hardcoded by its full PipeWire sink name) going `RUNNING` — a
  call, a video, a notification sound — and pauses whichever room is currently "active" (if
  it was playing), resuming it once the host goes quiet again. Only resumes a room this
  code itself paused, and only if nothing else already changed its transport in the
  meantime (checked before firing `Play`). Pausing a live internet-radio stream (this
  household's main use case) usually reports `STOPPED` rather than `PAUSED_PLAYBACK`, since
  most streams can't be truly paused — both count as "still where we left it, safe to
  resume". Checked alongside the room poll (~5s cadence); no separate faster timer, since
  PipeWire's own sink-suspend hysteresis already provides a natural debounce against
  flapping on brief gaps.
- **Grouping**: `SetAVTransportURI` with `x-rincon:<coordinator-RINCON>` on the joining
  speaker adds it to a group; `BecomeCoordinatorOfStandaloneGroup` pulls it back out. Group
  membership itself is inferred cheaply with no extra UPnP service needed: a follower's
  `GetPositionInfo` returns `TrackURI: x-rincon:<RINCON_ID>` instead of real track data, so
  rooms sharing the same resolved coordinator RINCON are in the same group.
- **Favourites**: `ContentDirectory` `Browse` on `ObjectID=FV:2` returns the Sonos
  Favourites list as DIDL-Lite. Not every favourite is directly playable — browse-only
  entries like "Albums" or "Discover Sonos Radio" have an empty `<res>` and are silently
  skipped on click; real ones (individual stations/tracks/playlists) are played by feeding
  their `<res>` URI + `<r:resMD>` metadata into `SetAVTransportURI` then `Play`, same as a
  real Sonos controller does.
- **Bugs found and fixed after the initial single-file build**:
  - `ui.label` doesn't support an `onClick` prop (silently ignored, logged as a `ui-tree`
    warning) — whole-widget clicks need a reserved top-level `onClick()` function instead.
  - `ui.toggle` takes a `checked` prop, not `value` (same silent-`ui-tree`-warning failure
    mode as above — confirmed from the `checked`/`onChange` example in noctalia's official
    `example` plugin).
  - Parsing the favourites `<Result>` blob (decode + regex over ~10KB of DIDL-Lite) reliably
    exceeded the plugin sandbox's CPU budget for a single "async http callback" invocation,
    even after trimming to the minimum work needed. Fixed by only stashing the raw text in
    that callback and parsing it inside `update()` instead — one `<item>` per tick, spread
    across several ticks, so no single invocation does more than one decode+match.
  - A double-escaping bug in `playFavorite`: the extracted `<res>` URI was already at the
    "safe to re-embed in a new XML element" escaping level (matching `resMD`), but the code
    ran it through an XML-escape helper anyway, turning every `&` in stream URLs into
    `&amp;amp;` — Sonos rejected the malformed request outright (HTTP 500). Fixed by
    embedding `res` as-is, same as `resMD`.
  - All four verified end-to-end: temporarily installed `ydotool` (removed again after),
    precisely located widgets/buttons on-screen, and confirmed synthetic clicks produced
    real, correct state changes on the actual speakers via direct SOAP checks — not just
    that a click handler fired or a log warning went away.
- **Machine restored from a Clonezilla disk image whose snapshot predated a commit already
  pushed to GitHub** (the auto-pause-on-host-audio feature above) — the working directory
  came back looking "out of date" even though `git log` on this machine showed nothing
  missing, because the commit existed on `origin/master` but had never been pulled down to
  this disk before the image was taken. Confirmed by fetching origin and diffing rather than
  assuming — a local push/commit search alone would have missed it entirely, since nothing
  was ever lost or uncommitted, just not yet fetched. Resolved with a plain fast-forward
  merge (`yadm merge --ff-only origin/master`) after carefully undoing a parallel
  reimplementation of the same feature built independently in the same session, before
  realising the original already existed upstream.
- Plugin discovered/loaded from `~/.local/share/noctalia/plugins/<name>/` as a "local"
  source (noctalia's dev-plugin convention); enabled via `[plugins] enabled =
  ["milesj/sonos-control"]` in both `config.toml` and the live state file.
- **DHCP reservations recommended but not yet configured** — the speaker IPs above are
  currently unreserved on the router (a Vantiva/Technicolor-based ISP gateway, identified
  via the gateway's MAC OUI `D8:D8:E5`; no admin credentials available to configure it from
  here). MACs for reference: Bedroom `78:28:CA:E2:85:F8`, Dining `78:28:CA:E6:B2:EA`,
  Kitchen `34:7E:5C:35:CD:B8`, Living Room `38:42:0B:9B:1F:EE`. If the router ever
  reassigns these, `service.luau`'s hardcoded `ROOMS` table needs updating.

## Desktop watermark (`hypr/scripts/watermark.py`, `hypr/config/autostart.lua`)

Persistent, click-through, always-on-top corner watermark ("Ayana" / "CACHYOS") for
personal branding/aesthetic — no existing Noctalia feature does this, so it's a bespoke
GTK4 + `gtk4-layer-shell` Python script.

- Renders via the Wayland layer-shell overlay layer (`Gtk4LayerShell.Layer.OVERLAY`),
  anchored bottom-right, click-through via an empty `cairo.Region()` input region set on
  the `"realize"` signal so it never intercepts clicks meant for windows underneath.
- **Linking-order bug**: plain launch, and `LD_PRELOAD=/usr/lib/liblayer-shell-preload.so`,
  both failed with "GTK4 Layer Shell may have been linked after libwayland" — Python's own
  startup already links `libwayland-client` before the layer-shell library gets a chance to
  hook in. Fixed with `LD_PRELOAD=/usr/lib/libgtk4-layer-shell.so.0` (the versioned real
  library path specifically — the unversioned symlink and the dedicated preload-helper
  `.so` both did not work). Required installing the `gtk4-layer-shell` pacman package.
- Wired into `autostart.lua` with that exact `LD_PRELOAD` invocation.
- Tuned live per iterative feedback (font size, position, alignment, spacing, opacity),
  verified via scaled screenshot crops each round — physical vs. logical pixel coordinates
  matter here (`grim` captures physical px, `hyprctl layers` reports logical px; this
  display's `scale=3.2` means a 3.2x conversion factor between them).

## Printer — Brother HL-1210W (CUPS + `brlaser`, AirPrint)

- Discovered on the LAN via `avahi-browse -a -t -r` (mDNS): `Brother HL-1210W
  series` at `192.168.1.252` (`BRN106FD981C68E.local`), offering raw
  JetDirect (port 9100), LPD (515), and IPP (631, `ipp/print`). MAC address
  `10:6F:D9:81:C6:8E` (matches the `BRN...` hostname — Brother derives it directly from
  the MAC; also confirmed via `ip neigh show 192.168.1.252`). Not yet DHCP-reserved.
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
- Router is a Vantiva-manufactured (rebranded Technicolor Connected Home) ISP gateway at
  `192.168.1.1`, identified via its MAC OUI (`D8:D8:E5`) rather than logging in — no admin
  credentials available from here. Relevant if DHCP reservations are ever set up (see
  *Sonos control* and *Printer* above, both currently unreserved).

## SSH

- Found and removed a dangling `~/.ssh/config` symlink pointing at a since-garbage-collected
  home-manager/Nix store path.
- Restored the previous real config from `~/.ssh/config.backup`, which defines host aliases
  (`github`, `bogdan`, `maiya`, `ayana`, `yakov`).
- Enabled the socket-activated `ssh-agent.socket` user service so an agent is always
  reachable at `/run/user/1000/ssh-agent.socket`.
- Loaded the `id_ed25519` key into that agent (verified against GitHub as `amiles5`).

## GitHub authentication — `gh` token over HTTPS (not SSH key)

Switched from the SSH key (`id_ed25519`, passphrase-protected, required
`SSH_AUTH_SOCK`/`GIT_SSH_COMMAND` on every push) to a GitHub CLI-managed
token over HTTPS.

- Installed `github-cli` (`gh`), then ran `gh auth login` interactively
  (device/browser flow — GitHub.com, HTTPS, "Login with a web browser",
  answered "Yes" to "Authenticate Git with your GitHub credentials?"). This
  step needs a real browser login and can't be scripted/run non-interactively.
- `gh` stored the OAuth token at `~/.config/gh/hosts.yml` and registered
  itself as git's credential helper for `github.com`/`gist.github.com` in
  `~/.gitconfig`: `credential."https://github.com".helper = !/usr/bin/gh
  auth git-credential`.
- Switched the yadm remote from `git@github.com:...` to
  `https://github.com/amiles5/ayana-cachyos.git` (`yadm remote set-url
  origin ...`) so it picks up that credential helper.
- Result: plain `yadm push`/`yadm fetch` work with no env var prefix and no
  passphrase prompt — verified with a live fetch + push round trip.
- **Not yadm-tracked** (secrets/host-specific): `~/.config/gh/hosts.yml`
  (the token itself) and the `credential.helper` lines in `~/.gitconfig`
  (`.gitconfig` isn't tracked at all). To recover on a fresh machine:
  install `github-cli`, run `gh auth login` again (repeats the browser
  flow above), then re-point the yadm remote to the HTTPS URL as above —
  `gh auth login` sets up the credential helper automatically.
- The old SSH key/agent setup above is left in place, untouched, as a
  fallback — nothing was deleted.
- Also used directly (via `gh api`) to pull `amiles5/aerospace-config`'s `aerospace.toml`
  for cross-referencing keybinds/workspace rules against this repo — see *Auto-assigned
  workspaces* above.

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
  Notable recent additions: `gparted`, `gtk4-layer-shell` (desktop watermark).
- `pacman-foreign-aur.txt` — output of `pacman -Qqm` (foreign/AUR packages, i.e.
  not from a configured repo). No AUR helper (`paru`/`yay`) is installed on
  this system, so anything in this file (`asdbctl`, `brlaser` — see the
  "Brightness" and "Printer" sections above) needs to be reinstalled manually on
  recovery: `git clone https://aur.archlinux.org/<pkg>.git && cd <pkg> && makepkg -si`.
- `flatpak.txt` — output of `flatpak list --app --columns=application`.
  Currently: `de.z_ray.Facetracker`, `hu.irl.cameractrls`,
  `io.github.TaylanTatli.iCloud-Linux`, `io.github.webcamoid.Webcamoid` — **not**
  ZapZap, which was uninstalled after switching WhatsApp to a Firefox PWA (see
  *WhatsApp* below). Restore with `flatpak install flathub $(cat ~/.pkglist/flatpak.txt)`.
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

## WhatsApp (`hypr/config/binds.lua`, `hypr/config/windowrules.lua`)

- No official WhatsApp Linux client exists. Originally used **ZapZap**
  (`com.rtosta.zapzap`, Flathub — GTK4/libadwaita wrapper around web.whatsapp.com,
  built on QtWebEngine), bound to `SUPER + SHIFT + M`.
- ZapZap has no voice/video call button — a known upstream limitation, not
  something specific to this machine (see
  [rafatosta/zapzap#199](https://github.com/rafatosta/zapzap/issues/199) and
  [#529](https://github.com/rafatosta/zapzap/issues/529)). Toggling ZapZap's beta mode
  later did surface call buttons in the UI, but by then a replacement was already in
  motion.
- Tried working around it earlier with a second, separate **firefoxpwa** WhatsApp Web
  install specifically for calls — removed again, video calling didn't work through it
  either.
- **ZapZap fully removed** (`flatpak uninstall com.rtosta.zapzap`) and replaced with a
  proper **WhatsApp Web Firefox PWA** (`firefoxpwa site install
  https://web.whatsapp.com/manifest.json`, same `firefoxpwa` tooling as Sonos/iCloud —
  WhatsApp Web does publish a real manifest). Bound to the same `SUPER + SHIFT + M` key,
  now targeting `[workspace 2]`, and auto-assigned to workspace 2 via `windowrules.lua`
  (class `FFPWA-01M00K4G8CW4N60N8Q6G1BF8QB`) — see *Auto-assigned workspaces* above.
- ZapZap's flatpak data dir (`~/.var/app/com.rtosta.zapzap/`) is gone along with the app.
  The WhatsApp PWA's session/auth data lives under `.local/share/firefoxpwa`, which is
  deliberately untracked — see *This repo* below.

## Sonos (`hypr/config/binds.lua`, `hypr/config/windowrules.lua`)

- Installed the Sonos web app (play.sonos.com) as a native firefoxpwa app, same
  pattern as iCloud/WhatsApp — real manifest at
  `https://play.sonos.com/manifest.webmanifest`, no hand-written manifest needed.
- Bound to `SUPER + SHIFT + U` (`firefoxpwa site launch 01KZQREYPXKDBAHY9JWSG975VB`),
  now targeting `[workspace 6]`, and auto-assigned to workspace 6 via `windowrules.lua`
  (class `FFPWA-01KZQREYPXKDBAHY9JWSG975VB`). Originally `SUPER + ALT + S`, then
  `SUPER + SHIFT + O` when app-launch binds were rationalized onto the uniform
  `SUPER + SHIFT + <key>` scheme (both `SUPER + S` and `SUPER + SHIFT + S` were already
  taken by scratchpad binds); later moved once more to `SUPER + SHIFT + U` to free up `O`
  and give it a workspace-6 default.
- A real in-bar **Sonos playback control widget** was also built — see *Noctalia shell —
  Sonos control* above for the full technical writeup (local UPnP/SOAP plugin, no cloud
  dependency). DHCP reservations for the speakers are recommended but not yet configured.

## Joplin (`hypr/config/binds.lua`, `hypr/config/windowrules.lua`)

- Installed natively via the `joplin-desktop` pacman package (not a Flatpak) — initially
  missed because an earlier check only grepped the Hyprland config directory rather than
  the whole system.
- Bound to `SUPER + SHIFT + N`, launching `[workspace 4] joplin-desktop`; auto-assigned to
  workspace 4 via `windowrules.lua`. The real Hyprland window class is
  `joplin-app-desktop` — the `.desktop` file's `StartupWMClass` (`@joplin/app-desktop`) is
  wrong and was not used; the class was confirmed live via `hyprctl clients -j` instead.
- Notes/database (`.config/joplin-desktop`) are deliberately untracked — see *This repo*
  below (live user data + secrets, not config).

## This repo

- Tracked: `hypr`, `kitty`, `fish`, `fastfetch`, `noctalia`, `alacritty`, `btop`,
  GTK3/4 & Qt5/6ct theming, `dolphinrc`/`kdeglobals`, `micro` (`settings.json` +
  colorschemes only), assorted XDG files (`mimeapps.list`, `user-dirs.*`, etc),
  `.pkglist` (package lists for recovery — see "Package lists" section above), and
  `.local/share/noctalia/plugins/sonos-control` (the local Sonos-control plugin — note
  this is the one thing tracked under `.local/share` rather than `.config`; everything
  else under `.local/state`/`.local/share` is deliberately left untracked, see below).
- Deliberately excluded: `.config/mozilla` (191MB Firefox profile — history/cookies/saved
  logins), `.config/pulse` and `.config/dconf` (small binary runtime state, not really
  "config"), micro's 146 bundled default syntax-highlighting files (not user-authored),
  `.config/joplin-desktop` (holds the actual notes `database.sqlite`, a live `api.token`
  secret in `settings.json`, and `ipc_secret_key.txt` — user data/secrets, not config),
  `.local/share/firefoxpwa` (bundled Firefox runtime binary + the WhatsApp/Sonos PWA
  profiles' live session/auth cookies, same class as the `.config/mozilla` exclusion
  above), and `~/.local/state/noctalia/settings.toml` (GUI-written runtime state — see
  *Noctalia shell — bar widgets, plugins, and the config/state split* above for why this
  one in particular is worth understanding, not just excluding).
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
- `/etc/udev/hwdb.d/70-logitech-uk-102nd.hwdb` (Logitech UK keyboard 102nd-key remap) is
  outside `$HOME` too — see *Input / keyboard model* above for the exact rule to recreate
  it (`sudo systemd-hwdb update && sudo udevadm trigger` after writing the file).
- Pushed to `https://github.com/amiles5/ayana-cachyos.git` (branch `master`)
  — HTTPS + `gh`-managed token, see "GitHub authentication" section above
  (was `git@github.com:...` SSH remote until this was switched over).
