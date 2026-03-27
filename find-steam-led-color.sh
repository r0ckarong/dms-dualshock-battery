#!/bin/sh

# Helper script to find and parse Steam controller LED colors from VDF files
# Usage: find-steam-led-color.sh <source> <custom_path> <mac>
# source: native, flatpak, or custom
# custom_path: path to config directory (only used if source=custom)
# mac: MAC address like "aa:bb:cc:dd:ee:ff"

source="${1:-native}"
custom_path="${2:-}"
mac="${3:-}"

if [ -z "$mac" ]; then
    printf ""
    exit 0
fi

# Sanitize MAC address: aa:bb:cc:dd:ee:ff -> aabbccddeeff
sanitized_mac=$(printf '%s' "$mac" | tr '[:upper:]' '[:lower:]' | sed 's/://g')

if [ -z "$sanitized_mac" ]; then
    printf ""
    exit 0
fi

# Determine Steam config base path
if [ "$source" = "native" ]; then
    base_path="$HOME/.local/share/Steam/steamapps/common/Steam Controller Configs"
elif [ "$source" = "flatpak" ]; then
    base_path="$HOME/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/Steam Controller Configs"
elif [ "$source" = "custom" ] && [ -n "$custom_path" ]; then
    base_path="$custom_path"
else
    printf ""
    exit 0
fi

if [ ! -d "$base_path" ]; then
    printf ""
    exit 0
fi

config_dir=''

# If not custom, try to auto-detect Steam ID (first numeric directory)
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

[ -n "$config_dir" ] || exit 0
[ -d "$config_dir" ] || exit 0

# Look for the preferences file
vdf_file="$config_dir/preferences_${sanitized_mac}.vdf"

if [ ! -f "$vdf_file" ]; then
    printf ""
    exit 0
fi

# Parse VDF file for Steam controller personalization RGB values.
r=$(sed -n 's/^[[:space:]]*"color_red"[[:space:]]*"\([0-9][0-9]*\)"[[:space:]]*$/\1/p' "$vdf_file" | head -1)
g=$(sed -n 's/^[[:space:]]*"color_green"[[:space:]]*"\([0-9][0-9]*\)"[[:space:]]*$/\1/p' "$vdf_file" | head -1)
b=$(sed -n 's/^[[:space:]]*"color_blue"[[:space:]]*"\([0-9][0-9]*\)"[[:space:]]*$/\1/p' "$vdf_file" | head -1)

# If any values found, output as hex
if [ -n "$r" ] || [ -n "$g" ] || [ -n "$b" ]; then
    r=${r:-0}
    g=${g:-0}
    b=${b:-0}

    # Clamp values to 0-255
    r=$((r > 255 ? 255 : r))
    g=$((g > 255 ? 255 : g))
    b=$((b > 255 ? 255 : b))

    # Convert to hex
    printf '#%02x%02x%02x\n' "$r" "$g" "$b"
else
    printf ""
fi
