#!/bin/sh

set -eu

power_base="/sys/class/power_supply"
use_steam="${1:-0}"
steam_source="${2:-native}"
steam_custom_path="${3:-}"

trim_file() {
    tr -d '\n' < "$1"
}

normalize_channel() {
    value="$1"
    max="$2"

    if [ -z "$max" ] || [ "$max" -le 0 ] 2>/dev/null; then
        max=255
    fi

    scaled=$((value * 255 / max))
    [ "$scaled" -gt 255 ] && scaled=255
    [ "$scaled" -lt 0 ] && scaled=0
    printf '%d' "$scaled"
}

read_multicolor_led() {
    led_dir="$1"

    [ -f "$led_dir/multi_index" ] || return 1
    [ -f "$led_dir/multi_intensity" ] || return 1

    red=0
    green=0
    blue=0
    max_brightness=255

    if [ -f "$led_dir/max_brightness" ]; then
        max_brightness="$(trim_file "$led_dir/max_brightness")"
    fi

    while IFS=' ' read -r name value; do
        case "$name" in
            red)
                red="$(normalize_channel "$value" "$max_brightness")"
                ;;
            green)
                green="$(normalize_channel "$value" "$max_brightness")"
                ;;
            blue)
                blue="$(normalize_channel "$value" "$max_brightness")"
                ;;
        esac
    done <<EOF
$(paste -d ' ' "$led_dir/multi_index" "$led_dir/multi_intensity" 2>/dev/null)
EOF

    printf '#%02x%02x%02x\n' "$red" "$green" "$blue"
}

read_rgb_leds() {
    leds_dir="$1"

    red=''
    green=''
    blue=''
    red_max=''
    green_max=''
    blue_max=''

    for led in "$leds_dir"/*; do
        [ -e "$led" ] || continue

        name="$(basename "$led")"
        [ -f "$led/brightness" ] || continue

        brightness="$(trim_file "$led/brightness")"
        max_brightness="255"
        if [ -f "$led/max_brightness" ]; then
            max_brightness="$(trim_file "$led/max_brightness")"
        fi

        case "$name" in
            *:red|*:red:*|red|red:*)
                red="$brightness"
                red_max="$max_brightness"
                ;;
            *:green|*:green:*|green|green:*)
                green="$brightness"
                green_max="$max_brightness"
                ;;
            *:blue|*:blue:*|blue|blue:*)
                blue="$brightness"
                blue_max="$max_brightness"
                ;;
        esac
    done

    [ -n "$red$green$blue" ] || return 1

    red="${red:-0}"
    green="${green:-0}"
    blue="${blue:-0}"

    red_max="${red_max:-255}"
    green_max="${green_max:-255}"
    blue_max="${blue_max:-255}"

    red="$(normalize_channel "$red" "$red_max")"
    green="$(normalize_channel "$green" "$green_max")"
    blue="$(normalize_channel "$blue" "$blue_max")"

    printf '#%02x%02x%02x\n' "$red" "$green" "$blue"
}

find_led_color() {
    device_path="$1"
    current="$(readlink -f "$device_path/device" 2>/dev/null || readlink -f "$device_path")"
    depth=0

    while [ -n "$current" ] && [ "$current" != "/" ] && [ "$depth" -lt 8 ]; do
        if [ -d "$current/leds" ]; then
            for led in "$current/leds"/*; do
                [ -e "$led" ] || continue
                if color="$(read_multicolor_led "$led" 2>/dev/null)" && [ -n "$color" ]; then
                    printf '%s\n' "$color"
                    return 0
                fi
            done

            if color="$(read_rgb_leds "$current/leds" 2>/dev/null)" && [ -n "$color" ]; then
                printf '%s\n' "$color"
                return 0
            fi
        fi

        current="$(dirname "$current")"
        depth=$((depth + 1))
    done

    printf '\n'
}

find_steam_config_color() {
    mac="$1"
    source="$2"
    custom_path="$3"

    if [ -z "$mac" ]; then
        printf ""
        return 1
    fi

    # Sanitize MAC: aa:bb:cc:dd:ee:ff -> aabbccddeeff
    sanitized_mac=$(printf '%s' "$mac" | tr '[:upper:]' '[:lower:]' | sed 's/://g')
    [ -n "$sanitized_mac" ] || return 1

    # Determine base path. Fall back between native and flatpak when the selected install is absent.
    if [ "$source" = "native" ]; then
        base_path="$HOME/.local/share/Steam/steamapps/common/Steam Controller Configs"
        if [ ! -d "$base_path" ] && [ -d "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/Steam Controller Configs" ]; then
            base_path="$HOME/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/Steam Controller Configs"
        fi
    elif [ "$source" = "flatpak" ]; then
        base_path="$HOME/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/Steam Controller Configs"
        if [ ! -d "$base_path" ] && [ -d "$HOME/.local/share/Steam/steamapps/common/Steam Controller Configs" ]; then
            base_path="$HOME/.local/share/Steam/steamapps/common/Steam Controller Configs"
        fi
    elif [ "$source" = "custom" ] && [ -n "$custom_path" ]; then
        base_path="$custom_path"
    else
        return 1
    fi

    [ -d "$base_path" ] || return 1

    config_dir=''

    # Auto-detect Steam ID if not custom
    if [ "$source" != "custom" ]; then
        for entry in "$base_path"/*; do
            [ -d "$entry" ] || continue
            dirname=$(basename "$entry")
            if printf '%s' "$dirname" | grep -qE '^[0-9]+$'; then
                config_dir="$entry/config"
                break
            fi
        done
    elif [ -d "$base_path/config" ]; then
        config_dir="$base_path/config"
    else
        config_dir="$base_path"
    fi

    [ -n "$config_dir" ] || return 1
    [ -d "$config_dir" ] || return 1

    vdf_file="$config_dir/preferences_${sanitized_mac}.vdf"
    [ -f "$vdf_file" ] || return 1

    # Extract RGB values from Steam's controller personalization keys.
    r=$(sed -n 's/^[[:space:]]*"color_red"[[:space:]]*"\([0-9][0-9]*\)"[[:space:]]*$/\1/p' "$vdf_file" | head -1)
    g=$(sed -n 's/^[[:space:]]*"color_green"[[:space:]]*"\([0-9][0-9]*\)"[[:space:]]*$/\1/p' "$vdf_file" | head -1)
    b=$(sed -n 's/^[[:space:]]*"color_blue"[[:space:]]*"\([0-9][0-9]*\)"[[:space:]]*$/\1/p' "$vdf_file" | head -1)

    if [ -n "$r" ] || [ -n "$g" ] || [ -n "$b" ]; then
        r=${r:-0}
        g=${g:-0}
        b=${b:-0}
        r=$((r > 255 ? 255 : r))
        g=$((g > 255 ? 255 : g))
        b=$((b > 255 ? 255 : b))
        printf '#%02x%02x%02x\n' "$r" "$g" "$b"
        return 0
    fi

    return 1
}

emit_device() {
    device_path="$1"
    kind="$2"
    base_name="$(basename "$device_path")"

    [ -f "$device_path/capacity" ] || return 0
    [ -f "$device_path/status" ] || return 0

    battery="$(trim_file "$device_path/capacity")"
    status="$(trim_file "$device_path/status")"

    case "$kind" in
        dualshock4)
            mac="${base_name##*_}"
            ;;
        dualsense)
            mac="${base_name##*-}"
            ;;
        *)
            mac=""
            ;;
    esac

    # Try Steam color first if enabled, fallback to sysfs
    color_sysfs="$(find_led_color "$device_path")"
    if [ "$use_steam" = "1" ]; then
        color_steam="$(find_steam_config_color "$mac" "$steam_source" "$steam_custom_path" 2>/dev/null)" || color_steam=""
        color_sysfs="${color_steam:-$color_sysfs}"
    fi

    printf '%s\t%s\t%s\t%s\t%s\n' "$mac" "$battery" "$status" "$kind" "$color_sysfs"
}

for device in "$power_base"/sony_controller_battery*; do
    [ -e "$device" ] || continue
    emit_device "$device" dualshock4
done

for device in "$power_base"/ps-controller-battery*; do
    [ -e "$device" ] || continue
    emit_device "$device" dualsense
done
