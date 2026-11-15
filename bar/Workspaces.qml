import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../core"

Row {
    id: ws
    spacing: 6
    property int active: 1
    property var occupied: []

    Process {
        id: query
        command: ["sh", "-c", "hyprctl -j activeworkspace; echo '|||'; hyprctl -j workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("|||")
                ws.active = JSON.parse(parts[0]).id
                ws.occupied = JSON.parse(parts[1]).filter(w => w.id > 0 && w.windows > 0).map(w => w.id)
            }
        }
    }

    Timer {
        id: refresh
        interval: 30
        onTriggered: query.running = true
    }

    Socket {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/hypr/" + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/.socket2.sock"
        connected: true
        parser: SplitParser {
            onRead: data => {
                if (/^(workspace|createworkspace|destroyworkspace|openwindow|closewindow|movewindow|focusedmon)/.test(data))
                    refresh.restart()
            }
        }
    }

    Component.onCompleted: query.running = true

    Repeater {
        model: 5
        Rectangle {
            property int num: index + 1
            property bool isActive: ws.active === num
            property bool hasWindows: ws.occupied.indexOf(num) !== -1

            anchors.verticalCenter: parent.verticalCenter
            width: isActive ? 30 : dotHover.hovered ? 16 : 10
            height: 10
            radius: 5
            color: isActive ? Theme.accent : hasWindows ? Theme.subtext : Theme.surfaceHigh

            Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
            Behavior on color { ColorAnimation { duration: 250 } }

            HoverHandler { id: dotHover }
            TapHandler {
                onTapped: Hyprland.dispatch("hl.dsp.focus({ workspace = " + num + " })")
            }
        }
    }
}
