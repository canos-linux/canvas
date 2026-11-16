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
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE dev | grep ^ethernet:connected >/dev/null && echo ETH; nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev | grep :wifi:connected:; nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi list --rescan no | grep ^yes:; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                root.wired = lines.indexOf("ETH") !== -1
                const dev = lines.find(l => l.indexOf(":wifi:connected:") !== -1)
                const act = lines.find(l => l.startsWith("yes:"))
                if (dev) {
                    // DEVICE:TYPE:STATE:CONNECTION – name comes from the device line, signal from the wifi list
                    const name = dev.split(":").slice(3).join(":")
                    root.ssid = name !== "" ? name : (act ? act.split(":").slice(2).join(":") : "")
                    root.strength = act ? parseInt(act.split(":")[1]) || 0 : 0
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
