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
  monitor (`hl.dsp.focus({ workspace = "m+1" / "m-1" })`), i.e. a mouse-free equivalent of
  the existing `SUPER+scroll wheel` behaviour. Noctalia's built-in window-switcher was
  intentionally *not* used for this — kept to native Hyprland dispatchers only.

## Monitor-targeting bind guard (`hypr/config/binds.lua`)

`SUPER+2`/`SUPER+3` and `SUPER+SHIFT+2`/`SUPER+SHIFT+3` were erroring
(`monitor not found` / `Invalid monitor`) because `MONITOR2`/`MONITOR3` are empty strings
on this single-monitor setup. Wrapped each of those binds in
`if MONITORx ~= "" then ... end` so they only register once a monitor slot is actually
populated.

> Note: `binds.lua` also has plain `SUPER+1..6` → focus-workspace-N binds and
> `SUPER+SHIFT+1..6` → move-window-to-workspace-N binds using the *same* key combos as the
> monitor-focus/move binds above. Harmless today (only one monitor), but worth revisiting
> if a second monitor is ever added, since both dispatchers fire on the same keypress.

## Workspaces (`hypr/config/workspaces.lua`, `variables.lua`)

- Expanded from 3 to 6 persistent workspaces on startup, all pinned to `MONITOR1`.
- Bumped `NUM_WPM` (workspaces per monitor) from 3 to 6 so the `SUPER+ALT+1-6`,
  `SUPER+CONTROL+1-6`, and `SUPER+SHIFT+CONTROL+1-6` loops cover all six.

## Input / keyboard model (`hypr/config/inputs.lua`)

- `kb_layout = "gb"`, `kb_model = "apple"`, `kb_variant = "mac"`, `follow_mouse = 1`,
  `sensitivity = 0`, `touchpad.natural_scroll = false`; kept `accel_profile = "flat"`.
- Fixed a duplicate `kb_model` entry that had silently reverted the effective keyboard
  model to `pc105`/`evdev` (a second, uncommented `kb_model`/`kb_options`/`kb_rules` block
  had appeared below the intended one — last key wins in a Lua table). Removed the stray
  duplicate lines; `apple`/`mac` is now the live setting again.

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

## This repo

- Tracked: `hypr`, `kitty`, `fish`, `fastfetch`, `noctalia`, `alacritty`, `btop`,
  GTK3/4 & Qt5/6ct theming, `dolphinrc`/`kdeglobals`, `micro` (`settings.json` +
  colorschemes only), and assorted XDG files (`mimeapps.list`, `user-dirs.*`, etc).
- Deliberately excluded: `.config/mozilla` (191MB Firefox profile — history/cookies/saved
  logins), `.config/pulse` and `.config/dconf` (small binary runtime state, not really
  "config"), and micro's 146 bundled default syntax-highlighting files (not user-authored).
- Pushed to `git@github.com:amiles5/ayana-cachyos.git` (branch `master`).
