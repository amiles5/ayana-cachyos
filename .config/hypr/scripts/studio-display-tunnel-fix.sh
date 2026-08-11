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
# boots without needing the reauth below at all).
for _ in $(seq 1 10); do
    if is_display_up; then
        logger -t "$LOG_TAG" "Studio Display already up, nothing to do."
        exit 0
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
