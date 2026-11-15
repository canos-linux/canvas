import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "."

Pill {
    id: net
    property int strength: 0
    property string ssid: ""
    property bool wired: false

    icon: wired ? "󰈀" : ssid === "" ? "󰤮" : strength > 75 ? "󰤨" : strength > 50 ? "󰤥" : strength > 25 ? "󰤢" : "󰤟"
    iconColor: !wired && ssid === "" ? Theme.subtext : Theme.text
    label: wired ? "Ethernet" : ssid === "" ? "Offline" : ssid

    Process {
        id: query
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE dev | grep -q '^ethernet:connected' && echo ETH; nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi list --rescan no | grep '^yes:'"]
        stdout: StdioCollector {
            onStreamFinished: {
                net.wired = text.indexOf("ETH") !== -1
                const line = text.split("\n").find(l => l.startsWith("yes:"))
                if (line) {
                    const parts = line.split(":")
                    net.strength = parseInt(parts[1])
                    net.ssid = parts.slice(2).join(":")
                } else {
                    net.strength = 0
                    net.ssid = ""
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

    TapHandler {
        onTapped: Quickshell.execDetached(["kitty", "-e", "nmtui"])
    }
}
