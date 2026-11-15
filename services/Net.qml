pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property int strength: 0
    property string ssid: ""
    property bool wired: false
    property bool connected: wired || ssid !== ""
    property string icon: wired ? "󰈀" : ssid === "" ? "󰤮" : strength > 75 ? "󰤨" : strength > 50 ? "󰤥" : strength > 25 ? "󰤢" : "󰤟"
    property string label: wired ? "Ethernet" : ssid === "" ? "Offline" : ssid

    function openSettings() {
        Quickshell.execDetached(["kitty", "-e", "nmtui"])
    }

    Process {
        id: query
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE dev | grep -q '^ethernet:connected' && echo ETH; nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi list --rescan no | grep '^yes:'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wired = text.indexOf("ETH") !== -1
                const line = text.split("\n").find(l => l.startsWith("yes:"))
                if (line) {
                    const parts = line.split(":")
                    root.strength = parseInt(parts[1])
                    root.ssid = parts.slice(2).join(":")
                } else {
                    root.strength = 0
                    root.ssid = ""
                }
            }
        }
    }

    Timer {
        id: refresh
        interval: 500
        onTriggered: query.running = true
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: query.running = true
    }

    Process {
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: refresh.restart()
        }
    }
}
