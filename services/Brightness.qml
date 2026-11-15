pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property real value: 1

    function set(v) {
        value = Math.max(0.05, Math.min(1, v))
        setter.command = ["brightnessctl", "-q", "s", Math.round(value * 100) + "%"]
        setter.running = true
    }

    function refresh() { query.running = true }

    Process {
        id: query
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                if (parts.length >= 5) root.value = parseInt(parts[2]) / parseInt(parts[4])
            }
        }
    }

    Process { id: setter }

    Component.onCompleted: refresh()
}
