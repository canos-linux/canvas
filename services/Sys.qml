pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property real cpu: 0
    property real ram: 0
    property real temp: 0
    property bool active: false
    property bool widget: false
    property var last: [0, 0]

    Process {
        id: query
        command: ["sh", "-c", "head -1 /proc/stat; grep -E 'MemTotal|MemAvailable' /proc/meminfo; sensors 2>/dev/null | grep -m1 -E 'Tctl|Package id 0'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                const nums = lines[0].split(/\s+/).slice(1).map(Number)
                const idle = nums[3] + nums[4]
                const total = nums.reduce((a, b) => a + b, 0)
                const dTotal = total - root.last[0]
                const dIdle = idle - root.last[1]
                if (root.last[0] > 0 && dTotal > 0) root.cpu = 1 - dIdle / dTotal
                root.last = [total, idle]
                const memTotal = parseInt(lines[1].split(/\s+/)[1])
                const memAvail = parseInt(lines[2].split(/\s+/)[1])
                root.ram = 1 - memAvail / memTotal
                const t = lines[3] ? lines[3].match(/\+([\d.]+)/) : null
                if (t) root.temp = parseFloat(t[1])
            }
        }
    }

    Timer {
        interval: root.active ? 1500 : 3000
        running: root.active || root.widget
        repeat: true
        triggeredOnStart: true
        onTriggered: query.running = true
    }
}
