import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "."

Pill {
    id: bt
    property bool powered: false
    property string device: ""

    icon: !powered ? "󰂲" : device !== "" ? "󰂱" : "󰂯"
    iconColor: !powered ? Theme.subtext : device !== "" ? Theme.accent : Theme.text
    label: !powered ? "Aus" : device !== "" ? device : "An"

    Process {
        id: query
        command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo ON; bluetoothctl devices Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                bt.powered = text.indexOf("ON") === 0
                const line = text.split("\n").find(l => l.startsWith("Device "))
                bt.device = line ? line.split(" ").slice(2).join(" ") : ""
            }
        }
    }

    Process {
        id: toggle
        command: ["bluetoothctl", "power", bt.powered ? "off" : "on"]
        onExited: query.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: query.running = true
    }

    TapHandler {
        onTapped: {
            toggle.running = true
            bt.flash()
        }
    }
}
