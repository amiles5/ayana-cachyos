#!/usr/bin/env bash
# Works around a boot-time Thunderbolt race: the Studio Display's DP tunnel
# is sometimes requested before the machine's own USB4 retimer has finished
# initializing, so the kernel logs "not enough bandwidth" and gives up
# without retrying (confirmed via journalctl -b: retimer-found and
# DP-tunnel-activation-failed land in the same second). A physical
# unplug/replug fixes it by forcing a fresh tunnel-activation attempt once
# the retimer has settled; this reproduces that in software by
# deauthorizing/reauthorizing the display's Thunderbolt device.
#
# Only autologin exposed this reliably: the few seconds spent typing a
# password at the SDDM greeter used to happen to be enough delay to dodge
# the race.
#
# NOTE: this only covers the "tunnel activation fails but the device is
# already enumerated" race. A separate, worse failure has been observed
# where the Thunderbolt device isn't detected at all for 60+ seconds and
# needs a physical replug to appear - this script can't do anything about
# that (there's no /sys/bus/thunderbolt/devices/ entry yet to toggle), and
# on that occasion it logged a false "already up" a full 55s before the
# device actually appeared. The debounce below (require the check to pass
# twice, 1s apart) guards against a repeat of that specific false positive,
# though the underlying cause of the single spurious pass wasn't confirmed.

set -u

DISPLAY_DESC="Apple Computer Inc StudioDisplay 0xBE714649"
LOG_TAG="studio-display-tunnel-fix"

is_display_up() {
    hyprctl monitors -j 2>/dev/null | jq -e --arg d "$DISPLAY_DESC" \
        'any(.[]; .description == $d)' >/dev/null
}

# Give the retimer/tunnel race a chance to resolve on its own first, polling
# instead of a flat sleep so we react as soon as it comes up rather than
# always eating the full wait (observed: it self-heals within ~10s on some
# boots without needing the reauth below at all). Requires two consecutive
# passes before trusting it, to debounce a possible one-off false positive.
consecutive=0
for _ in $(seq 1 10); do
    if is_display_up; then
        consecutive=$((consecutive + 1))
        if [ "$consecutive" -ge 2 ]; then
            logger -t "$LOG_TAG" "Studio Display up (confirmed on 2 consecutive checks), nothing to do."
            exit 0
        fi
    else
        if [ "$consecutive" -gt 0 ]; then
            logger -t "$LOG_TAG" "Studio Display check passed once then failed on recheck (debounced a possible false positive). Raw hyprctl output: $(hyprctl monitors -j 2>&1 | tr -d '\n')"
        fi
        consecutive=0
    fi
    sleep 1
done

logger -t "$LOG_TAG" "Studio Display not detected, looking for its Thunderbolt device."

tb_dev=""
for d in /sys/bus/thunderbolt/devices/*/; do
    if [ "$(cat "${d}device_name" 2>/dev/null)" = "Studio Display" ]; then
        tb_dev="$d"
        break
    fi
done

if [ -z "$tb_dev" ]; then
    logger -t "$LOG_TAG" "No Thunderbolt device named 'Studio Display' found, giving up."
    exit 1
fi

logger -t "$LOG_TAG" "Forcing reauthorization of ${tb_dev}."
sudo -n tee "${tb_dev}authorized" <<<0 >/dev/null
sleep 1
sudo -n tee "${tb_dev}authorized" <<<1 >/dev/null

sleep 3
hyprctl reload >/dev/null 2>&1

if is_display_up; then
    logger -t "$LOG_TAG" "Studio Display recovered after reauthorization."
else
    logger -t "$LOG_TAG" "Studio Display still not detected after reauthorization."
fi
