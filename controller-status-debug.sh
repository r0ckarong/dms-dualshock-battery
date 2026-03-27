#!/bin/sh

set -eu

power_base="/sys/class/power_supply"

trim_file() {
    tr -d '\n' < "$1"
}

find_led_debug() {
    device_path="$1"
    current="$(readlink -f "$device_path/device" 2>/dev/null || readlink -f "$device_path")"
    depth=0

    echo "=== Searching for LED from: $device_path ===" >&2
    echo "Initial path: $current" >&2

    while [ -n "$current" ] && [ "$current" != "/" ] && [ "$depth" -lt 8 ]; do
        echo "Depth $depth: $current" >&2
        if [ -d "$current/leds" ]; then
            echo "Found leds directory: $current/leds" >&2
            ls -la "$current/leds/" >&2

            for led in "$current/leds"/*; do
                [ -e "$led" ] || continue
                echo "  Checking LED: $led" >&2

                # Try multicolor LED
                if [ -f "$led/multi_index" ] && [ -f "$led/multi_intensity" ]; then
                    echo "    Found multicolor LED" >&2
                    echo "    multi_index:" >&2
                    cat "$led/multi_index" >&2
                    echo "    multi_intensity:" >&2
                    cat "$led/multi_intensity" >&2
                fi

                # Try RGB channels
                for channel in red green blue; do
                    if [ -f "$led/brightness" ]; then
                        name="$(basename "$led")"
                        echo "    LED name: $name" >&2
                        echo "    brightness: $(cat "$led/brightness")" >&2
                    fi

                    for subdir in "$led"/*:"$channel" "$led"/*:"$channel":* "$led"/"$channel"*; do
                        if [ -f "$subdir/brightness" ] 2>/dev/null; then
                            echo "    Found $channel channel: $subdir = $(cat "$subdir/brightness")" >&2
                        fi
                    done
                done
            done
        fi

        current="$(dirname "$current")"
        depth=$((depth + 1))
    done
}

for device in "$power_base"/ps-controller-battery*; do
    [ -e "$device" ] || continue
    echo "=== Checking device: $device ===" >&2
    find_led_debug "$device"
done
