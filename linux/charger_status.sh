#!/usr/bin/env bash
# Identifies the current USB laptop charger, and prints out its current and
# maximum power.

set -euo pipefail

for dev in /sys/class/power_supply/ucsi-source-psy-*; do
    [[ -d "$dev" ]] || continue

    status=$(<"$dev/status")
    online=$(<"$dev/online")

    if [[ "$status" == "Charging" || "$online" == "1" ]]; then
        voltage_now=$(<"$dev/voltage_now")
        current_now=$(<"$dev/current_now")
        voltage_max=$(<"$dev/voltage_max")
        current_max=$(<"$dev/current_max")

        awk \
            -v dev="$(basename "$dev")" \
            -v vn="$voltage_now" \
            -v cn="$current_now" \
            -v vm="$voltage_max" \
            -v cm="$current_max" '
            BEGIN {
                vn /= 1000000
                cn /= 1000000
                vm /= 1000000
                cm /= 1000000

                printf "%s\n", dev
                printf "Current: %.1f V × %.2f A = %.1f W\n",
                       vn, cn, vn * cn
                printf "Maximum: %.1f V × %.2f A = %.1f W\n",
                       vm, cm, vm * cm
            }
        '

        exit 0
    fi
done

echo "No charging power supply found." >&2
exit 1
