import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "."

Pill {
    id: kb
    property string layout: "DE"

    icon: "󰌌"
    label: layout
    alwaysLabel: true

    function short(name) {
        const map = { "German": "DE", "English (US)": "US", "English (UK)": "UK", "Turkish": "TR" }
        for (const key in map)
            if (name.indexOf(key) === 0) return map[key]
        return name.slice(0, 2).toUpperCase()
    }

    Process {
        id: query
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                const keyboards = JSON.parse(text).keyboards
                const main = keyboards.find(k => k.main) || keyboards[0]
                if (main) kb.layout = kb.short(main.active_keymap)
            }
        }
    }

    Socket {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/hypr/" + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/.socket2.sock"
        connected: true
        parser: SplitParser {
            onRead: data => {
                if (data.startsWith("activelayout"))
                    query.running = true
            }
        }
    }

    Component.onCompleted: query.running = true

    TapHandler {
        onTapped: Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
    }
}
