pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root
    property int active: 1
    property var occupied: []
    property string layout: "DE"
    property int last: -1
    signal switched()

    function focus(num) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + num + " })")
    }

    function nextLayout() {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
    }

    function shortName(name) {
        const map = { "German": "DE", "English (US)": "US", "English (UK)": "UK", "Turkish": "TR" }
        for (const key in map)
            if (name.indexOf(key) === 0) return map[key]
        return name.slice(0, 2).toUpperCase()
    }

    Process {
        id: wsQuery
        command: ["sh", "-c", "hyprctl -j activeworkspace; echo '|||'; hyprctl -j workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("|||")
                const id = JSON.parse(parts[0]).id
                if (root.last !== -1 && id !== root.last && id > 0) root.switched()
                if (id > 0) {
                    root.last = id
                    root.active = id
                }
                root.occupied = JSON.parse(parts[1]).filter(w => w.id > 0 && w.windows > 0).map(w => w.id)
            }
        }
    }

    Process {
        id: kbQuery
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                const keyboards = JSON.parse(text).keyboards
                const main = keyboards.find(k => k.main) || keyboards[0]
                if (main) root.layout = root.shortName(main.active_keymap)
            }
        }
    }

    Timer {
        id: refresh
        interval: 30
        onTriggered: wsQuery.running = true
    }

    Socket {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/hypr/" + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/.socket2.sock"
        connected: true
        parser: SplitParser {
            onRead: data => {
                if (data.startsWith("activelayout")) kbQuery.running = true
                else if (/^(workspace|createworkspace|destroyworkspace|openwindow|closewindow|movewindow|focusedmon)/.test(data)) refresh.restart()
            }
        }
    }

    Component.onCompleted: {
        wsQuery.running = true
        kbQuery.running = true
    }
}
