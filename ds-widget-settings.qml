import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "ds_battery_widget"

    StyledText {
        width: parent.width
        text: "DS Widget Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "hideWhenNoController"
        label: "Hide When No Controller Is Active"
        description: "Hide the widget instead of showing N/A when dsbattery reports no connected controller"
        defaultValue: false
    }

    ToggleSetting {
        id: steamConfigToggle
        settingKey: "useSteamConfig"
        label: "Use Steam Controller Config Colors"
        description: "Read LED colors from Steam controller configuration instead of sysfs"
        defaultValue: false
    }

    SelectionSetting {
        id: steamConfigSourceSetting
        settingKey: "steamConfigSource"
        label: "Steam Config Source"
        description: "Where to look for Steam controller configurations"
        defaultValue: "native"
        options: [
            {"label": "Native Steam", "value": "native"},
            {"label": "Flatpak Steam", "value": "flatpak"},
            {"label": "Custom Path", "value": "custom"}
        ]
        visible: steamConfigToggle.value
    }

    StringSetting {
        settingKey: "steamConfigCustomPath"
        label: "Steam Config Directory Path"
        description: "Full path to Steam Controller Configs/<ID>/config directory (e.g. ~/.local/share/Steam/steamapps/common/Steam Controller Configs/123456/config)"
        defaultValue: ""
        visible: steamConfigToggle.value && steamConfigSourceSetting.value === "custom"
    }

    SelectionSetting {
        settingKey: "lowBatteryThreshold"
        label: "Low Battery Threshold"
        description: "Battery percentage below which the low-charge warning appears"
        defaultValue: "10"
        options: [
            {"label": "5%", "value": "5"},
            {"label": "10%", "value": "10"},
            {"label": "15%", "value": "15"},
            {"label": "20%", "value": "20"}
        ]
    }

    ToggleSetting {
        id: useCustomColorsToggle
        settingKey: "useCustomColors"
        label: "Use Custom Colors"
        description: "Enable per-controller color overrides"
        defaultValue: false
    }

    StyledText {
        width: parent.width
        text: "Underline Color Overrides"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
        visible: useCustomColorsToggle.value
    }

    StyledText {
        width: parent.width
        text: "Assign a custom underline color to each controller. Set slot to 'None' to use the automatic sysfs color."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
        visible: useCustomColorsToggle.value
    }

    StringSetting {
        settingKey: "manualController1"
        label: "Color Slot 1 - Controller"
        description: "Controller MAC address (e.g. aa:bb:cc:dd:ee:ff)"
        defaultValue: ""
        visible: useCustomColorsToggle.value
    }

    ColorSetting {
        settingKey: "manualColor1"
        label: "Color Slot 1 - Underline Color"
        description: "Underline color for the controller in slot 1"
        defaultValue: "#ff0000"
        visible: useCustomColorsToggle.value
    }

    StringSetting {
        settingKey: "manualController2"
        label: "Color Slot 2 - Controller"
        description: "Controller MAC address (e.g. aa:bb:cc:dd:ee:ff)"
        defaultValue: ""
        visible: useCustomColorsToggle.value
    }

    ColorSetting {
        settingKey: "manualColor2"
        label: "Color Slot 2 - Underline Color"
        description: "Underline color for the controller in slot 2"
        defaultValue: "#00ffff"
        visible: useCustomColorsToggle.value
    }

    StringSetting {
        settingKey: "manualController3"
        label: "Color Slot 3 - Controller"
        description: "Controller MAC address (e.g. aa:bb:cc:dd:ee:ff)"
        defaultValue: ""
        visible: useCustomColorsToggle.value
    }

    ColorSetting {
        settingKey: "manualColor3"
        label: "Color Slot 3 - Underline Color"
        description: "Underline color for the controller in slot 3"
        defaultValue: "#00ff00"
        visible: useCustomColorsToggle.value
    }

    StringSetting {
        settingKey: "manualController4"
        label: "Color Slot 4 - Controller"
        description: "Controller MAC address (e.g. aa:bb:cc:dd:ee:ff)"
        defaultValue: ""
        visible: useCustomColorsToggle.value
    }

    ColorSetting {
        settingKey: "manualColor4"
        label: "Color Slot 4 - Underline Color"
        description: "Underline color for the controller in slot 4"
        defaultValue: "#ffff00"
        visible: useCustomColorsToggle.value
    }

    ToggleSetting {
        settingKey: "showDebugInfo"
        label: "Show Debug Information"
        description: "Display LED color hex, MAC address, and Steam config source in the widget"
        defaultValue: false
    }

}