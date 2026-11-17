pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property real value: 1
    property int raw: -1
    property int max: 1
    property string device: ""
    readonly property bool available: device !== ""
    signal bumped()

    function set(v) {
        if (!available) return
        value = Math.max(0.05, Math.min(1, v))
        setter.command = ["brightnessctl", "-q", "-d", device, "s", Math.round(value * 100) + "%"]
        setter.running = true
    }

    function refresh() { if (available) query.running = true }

    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/backlight | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.device = text.trim()
                root.refresh()
            }
        }
    }

    FileView {
        id: maxFile
        path: root.device !== "" ? "/sys/class/backlight/" + root.device + "/max_brightness" : ""
        onLoaded: root.max = parseInt(text())
    }

    FileView {
        id: curFile
        path: root.device !== "" ? "/sys/class/backlight/" + root.device + "/brightness" : ""
        onLoaded: {
            const v = parseInt(text())
            if (isNaN(v) || root.max <= 1) return
            if (root.raw !== -1 && v !== root.raw) {
                root.value = v / root.max
                root.bumped()
            }
            root.raw = v
        }
    }

    Timer {
        interval: 250
        running: root.device !== ""
        repeat: true
        onTriggered: curFile.reload()
    }

    Process {
        id: query
        command: ["brightnessctl", "-m", "-d", root.device]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                if (parts.length >= 5) root.value = parseInt(parts[2]) / parseInt(parts[4])
            }
        }
    }

    Process { id: setter }

}
