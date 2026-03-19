import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import Quickshell.Io

PluginComponent {
    id: root

    property string displayText: "Loading..."

    Process {
        id: dsbattery_proc
        command: ["sh", "-c", "dsbattery"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.displayText = this.text.trim() !== "" ? this.text.trim() : "N/A"
                // root.pluginData.displayText = root.displayText
            }
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            // DankIcon {
            //     name: "widgets"
            //     size: Theme.iconSize
            //     color: Theme.primary
            //     anchors.verticalCenter: parent.verticalCenter
            // }

            StyledText {
                text: root.displayText
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: "widgets"
                size: Theme.iconSize
                color: Theme.primary
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.displayText
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
