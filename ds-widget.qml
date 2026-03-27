import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import Quickshell.Io

PluginComponent {
    id: root

    property string scriptPath: Qt.resolvedUrl("controller-status.sh").toString().replace("file://", "")
    property string displayText: "Loading..."
    property var controllers: []
    property bool hasActiveController: false
    property bool hideWhenNoController: pluginData.hideWhenNoController !== undefined ? pluginData.hideWhenNoController : false
    property bool useSteamConfig: pluginData.useSteamConfig !== undefined ? pluginData.useSteamConfig : false
    property string steamConfigSource: pluginData.steamConfigSource || "native"
    property string steamConfigCustomPath: pluginData.steamConfigCustomPath || ""
    property bool showDebugInfo: pluginData.showDebugInfo !== undefined ? pluginData.showDebugInfo : false
    property bool useCustomColors: pluginData.useCustomColors !== undefined ? pluginData.useCustomColors : false
    property int lowBatteryThreshold: {
        const value = Number(pluginData.lowBatteryThreshold)
        if (Number.isNaN(value)) return 10
        return Math.max(1, Math.min(100, Math.round(value)))
    }
    property string manualController1: pluginData.manualController1 || ""
    property string manualColor1: pluginData.manualColor1 || ""
    property string manualController2: pluginData.manualController2 || ""
    property string manualColor2: pluginData.manualColor2 || ""
    property string manualController3: pluginData.manualController3 || ""
    property string manualColor3: pluginData.manualColor3 || ""
    property string manualController4: pluginData.manualController4 || ""
    property string manualColor4: pluginData.manualColor4 || ""

    function normalizeHexColor(color) {
        if (!color || typeof color !== "string") return ""
        const value = color.trim()
        const match = value.match(/^#([0-9a-fA-F]{6})$/)
        return match ? ("#" + match[1].toLowerCase()) : ""
    }

    function normalizeMac(mac) {
        return (mac || "").trim().toLowerCase()
    }

    function manualColorForMac(mac) {
        if (!useCustomColors) return ""

        const key = normalizeMac(mac)
        if (key === "") return ""

        const slots = [
            { mac: normalizeMac(manualController1), color: normalizeHexColor(manualColor1) },
            { mac: normalizeMac(manualController2), color: normalizeHexColor(manualColor2) },
            { mac: normalizeMac(manualController3), color: normalizeHexColor(manualColor3) },
            { mac: normalizeMac(manualController4), color: normalizeHexColor(manualColor4) }
        ]

        for (let i = 0; i < slots.length; i++) {
            if (slots[i].mac !== "" && slots[i].mac === key && slots[i].color !== "") {
                return slots[i].color
            }
        }
        return ""
    }

    function vividColor(color) {
        const hex = normalizeHexColor(color)
        if (hex === "") return ""

        let r = parseInt(hex.slice(1, 3), 16)
        let g = parseInt(hex.slice(3, 5), 16)
        let b = parseInt(hex.slice(5, 7), 16)
        const max = Math.max(r, g, b)
        if (max <= 0) return hex

        const scale = 255 / max
        r = Math.min(255, Math.round(r * scale))
        g = Math.min(255, Math.round(g * scale))
        b = Math.min(255, Math.round(b * scale))

        const toHex = value => value.toString(16).padStart(2, "0")
        return "#" + toHex(r) + toHex(g) + toHex(b)
    }

    function resolvedUnderlineColor(controller) {
        // Priority: manual override > steam/sysfs
        const manualColor = manualColorForMac(controller.mac || "")
        if (manualColor !== "") return vividColor(manualColor)

        const sysfsColor = normalizeHexColor(controller.sysfsColor || "")
        return vividColor(sysfsColor)
    }

    function batteryPercent(controller) {
        const value = Number(controller && controller.batteryPercentage)
        if (Number.isNaN(value)) return 100
        return Math.max(0, Math.min(100, value))
    }

    function chargeFillWidth(fullWidth, controller) {
        const width = Math.max(10, fullWidth)
        const pct = batteryPercent(controller) / 100
        if (pct <= 0) return 0
        return Math.max(6, Math.round(width * pct))
    }

    function chargeBarHeight() {
        const base = Number(Theme.fontSizeSmall)
        if (Number.isNaN(base)) return 2
        return Math.max(2, Math.min(5, Math.round(base * 0.18)))
    }

    function isLowBattery(controller) {
        return batteryPercent(controller) < lowBatteryThreshold
    }

    function showLowBatteryStripe(controller) {
        return isLowBattery(controller)
    }

    function showLowBatteryRing(controller) {
        return isLowBattery(controller)
    }

    readonly property var visibleControllers: {
        return hasActiveController ? controllers : [{
            "text": displayText,
            "underlineColor": "",
            "mac": "",
            "kind": ""
        }]
    }

    function iconForKind(kind) {
        switch (kind) {
        case "dualsense":
            return "sports_esports"
        case "dualshock4":
            return "sports_esports"
        default:
            return "widgets"
        }
    }

    function statusPrefix(status) {
        return status === "Charging" ? "🎮↑ " : "🎮 "
    }

    function controllerText(controller) {
        if (!controller || controller.status === undefined) {
            return "Error"
        }
        const baseText = statusPrefix(controller.status) + controller.batteryPercentage + "%"
        if (!showDebugInfo) return baseText

        const debugParts = []
        const colorText = normalizeHexColor(controller.sysfsColor || "")
        const macText = normalizeMac(controller.mac || "")
        if (colorText !== "") debugParts.push(colorText)
        if (macText !== "") debugParts.push(macText)
        debugParts.push(useSteamConfig ? ("steam:" + steamConfigSource) : "steam:off")
        return baseText + (debugParts.length > 0 ? " " + debugParts.join(" ") : "")
    }

    function controllerCommand() {
        return [
            "sh", root.scriptPath,
            useSteamConfig ? "1" : "0",
            steamConfigSource,
            steamConfigCustomPath
        ]
    }

    function updateControllers(output) {
        const trimmedOutput = output.trim()
        if (trimmedOutput === "") {
            controllers = []
            hasActiveController = false
            displayText = "N/A"
            syncVisibility()
            return
        }

        const parsedControllers = []
        const lines = trimmedOutput.split("\n")

        for (let index = 0; index < lines.length; index++) {
            const line = lines[index].trim()
            if (line === "") {
                continue
            }

            const parts = line.split("\t")
            if (parts.length < 5) {
                continue
            }

            const batteryPercentage = parseInt(parts[1], 10)
            if (Number.isNaN(batteryPercentage)) {
                continue
            }

            const controller = {
                "mac": parts[0],
                "batteryPercentage": batteryPercentage,
                "status": parts[2],
                "kind": parts[3],
                "sysfsColor": parts[4] || ""
            }
            controller.underlineColor = resolvedUnderlineColor(controller)
            controller.text = controllerText(controller)
            parsedControllers.push(controller)
        }

        controllers = parsedControllers
        hasActiveController = parsedControllers.length > 0
        displayText = hasActiveController ? parsedControllers.map(controller => controller.text).join(" | ") : "N/A"
        syncVisibility()
    }

    function syncVisibility() {
        if (hideWhenNoController) {
            setVisibilityOverride(hasActiveController)
        } else {
            clearVisibilityOverride()
        }
    }

    Component.onCompleted: syncVisibility()
    onHasActiveControllerChanged: syncVisibility()
    onHideWhenNoControllerChanged: syncVisibility()

    Timer {
        id: reloadTimer
        interval: 2000  // 2 seconds
        running: true
        repeat: true
        onTriggered: {
            controllerProc.command = root.controllerCommand()
            controllerProc.running = true
        }
    }

    Process {
        id: controllerProc
        command: root.controllerCommand()
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.updateControllers(this.text)
            }
        }
    }

    onUseSteamConfigChanged: {
        controllerProc.command = root.controllerCommand()
        controllerProc.running = true
    }
    onSteamConfigSourceChanged: {
        controllerProc.command = root.controllerCommand()
        controllerProc.running = true
    }
    onSteamConfigCustomPathChanged: {
        controllerProc.command = root.controllerCommand()
        controllerProc.running = true
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            Repeater {
                id: horizontalRepeater
                model: root.visibleControllers

                delegate: Row {
                    required property int index
                    required property var modelData

                    spacing: Theme.spacingS

                    Column {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter

                        StyledText {
                            id: horizontalText
                            text: modelData.text
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        Item {
                            width: Math.max(10, horizontalText.implicitWidth)
                            height: chargeBarHeight()
                            visible: root.hasActiveController

                            Rectangle {
                                width: parent.width
                                height: parent.height
                                radius: 3
                                color: Theme.surfaceVariant
                                opacity: 0.45
                            }

                            Rectangle {
                                width: chargeFillWidth(parent.width, modelData)
                                height: parent.height
                                radius: 3
                                color: modelData.underlineColor || Theme.primary
                                opacity: 0.95
                            }

                            Rectangle {
                                width: parent.width
                                height: 2
                                color: "#ff4d4d"
                                visible: root.showLowBatteryStripe(modelData)
                                opacity: 0.95
                                anchors.top: parent.top
                            }


                        }
                    }

                    StyledText {
                        text: "|"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                        visible: index < horizontalRepeater.count - 1
                    }
                }
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            Item {
                width: Theme.iconSize + 10
                height: Theme.iconSize + 10
                anchors.horizontalCenter: parent.horizontalCenter
                readonly property var iconController: root.hasActiveController ? root.controllers[0] : null

                readonly property color iconAccent: root.hasActiveController
                    ? (root.controllers[0].underlineColor || Theme.primary)
                    : Theme.primary

                Rectangle {
                    width: Theme.iconSize + 8
                    height: Theme.iconSize + 8
                    radius: (Theme.iconSize + 8) / 2
                    color: parent.iconAccent
                    opacity: 0.22
                    anchors.centerIn: parent
                }

                Rectangle {
                    width: Theme.iconSize + 2
                    height: Theme.iconSize + 2
                    radius: (Theme.iconSize + 2) / 2
                    color: "transparent"
                    border.width: 1
                    border.color: parent.iconAccent
                    opacity: 0.9
                    anchors.centerIn: parent
                }

                DankIcon {
                    name: root.hasActiveController ? root.iconForKind(root.controllers[0].kind) : root.iconForKind("dualshock4")
                    size: Theme.iconSize
                    color: parent.iconAccent
                    opacity: 0.28
                    anchors.centerIn: parent
                }

                DankIcon {
                    name: root.hasActiveController ? root.iconForKind(root.controllers[0].kind) : root.iconForKind("dualshock4")
                    size: Theme.iconSize
                    color: Theme.surfaceText
                    anchors.centerIn: parent
                }
            }

            Repeater {
                model: root.visibleControllers

                delegate: Column {
                    required property var modelData

                    spacing: 2
                    anchors.horizontalCenter: parent.horizontalCenter

                    StyledText {
                        id: verticalText
                        text: modelData.text
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceText
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Item {
                        width: Math.max(10, verticalText.implicitWidth)
                        height: chargeBarHeight()
                        visible: root.hasActiveController
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle {
                            width: parent.width
                            height: parent.height
                            radius: 3
                            color: Theme.surfaceVariant
                            opacity: 0.45
                        }

                        Rectangle {
                            width: chargeFillWidth(parent.width, modelData)
                            height: parent.height
                            radius: 3
                            color: modelData.underlineColor || Theme.primary
                            opacity: 0.95
                        }

                        Rectangle {
                            width: parent.width
                            height: 2
                            color: "#ff4d4d"
                            visible: root.showLowBatteryStripe(modelData)
                            opacity: 0.95
                            anchors.top: parent.top
                        }
                    }
                }
            }
        }
    }
}
