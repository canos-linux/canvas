pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property bool powered: false
    property string device: ""
    property string icon: !powered ? "󰂲" : device !== "" ? "󰂱" : "󰂯"
    property string label: !powered ? "Aus" : device !== "" ? device : "An"

    function toggle() {
        toggleProc.running = true
    }

    Process {
        id: query
        command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo ON; bluetoothctl devices Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.powered = text.indexOf("ON") === 0
                const line = text.split("\n").find(l => l.startsWith("Device "))
                root.device = line ? line.split(" ").slice(2).join(" ") : ""
            }
        }
    }

    Process {
        id: toggleProc
        command: ["bluetoothctl", "power", root.powered ? "off" : "on"]
        onExited: query.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: query.running = true
    }
}
