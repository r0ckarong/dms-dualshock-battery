# README

Install dsbattery - https://github.com/valters-tomsons/dsbattery

The widget now reads controller battery data directly from Linux sysfs instead of shelling out to `dsbattery`, using the same `/sys/class/power_supply` entries that `dsbattery` relies on internally.

## Limitations

* Does not have an indicator bar
* Does not indicate which controller is which unless the underlying sysfs paths remain stable enough to distinguish them reliably

## Configuration

* Optional setting to hide the widget when no controller is connected
* Shows a controller-color underline when the kernel exposes lightbar LEDs in sysfs

## Wishful thinking

* Allow selecting the controller to be shown
* Allow full list of controllers to be shown on click
* Allow battery indicator bar or dots (like the awesome https://extensions.gnome.org/extension/6670/bluetooth-battery-meter/)
* Identify the controller with the LED color (https://github.com/alanrme/ds4led)
* Also works with DualSense
* Configurable refresh interval