# README

The widget reads controller battery data directly from Linux sysfs via `/sys/class/power_supply` using `controller-status.sh`.

## Features

* Shows battery percentage and charge state for connected Sony controllers
* Supports both DualShock 4 and DualSense
* Displays all connected controllers in the widget
* Uses controller lightbar color as underline when available from sysfs
* Optional Steam color source for LED color (`native`, `flatpak`, or custom path)
* Optional per-controller custom underline color overrides by MAC address
* Optional debug display with color, MAC, and selected Steam source

## Configuration

* Hide widget when no controller is connected
* Enable or disable Steam controller config colors
* Select Steam config source (`native`, `flatpak`, `custom`)
* Provide custom Steam config directory path
* Enable or disable custom per-controller color overrides
* Configure up to four per-controller color slots
* Enable or disable debug information in widget text

## Limitations

* Does not have an indicator bar
* Refresh interval is fixed in code

## Future Ideas

* Allow full list of controllers to be shown on click
* Allow battery indicator bar or dots (like the awesome https://extensions.gnome.org/extension/6670/bluetooth-battery-meter/)
* Better controller identification UX without relying on debug text