pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Polkit
import QtQuick

Singleton {
    id: root
    property bool start: false
    readonly property var agent: loader.item
    readonly property var flow: agent ? agent.flow : null
    readonly property bool active: agent ? agent.isActive : false
    readonly property bool registered: agent ? agent.isRegistered : false

    // Canvas is the polkit agent; stop the old one first, fall back to it if registering fails
    Process {
        running: true
        command: ["sh", "-c", "sleep 2; systemctl --user stop hyprpolkitagent 2>/dev/null; pkill -x hyprpolkitagent; true"]
        onExited: root.start = true
    }

    LazyLoader {
        id: loader
        active: root.start
        PolkitAgent {}
    }

    Timer {
        interval: 4000
        running: root.start
        onTriggered: if (!root.registered) Quickshell.execDetached(["systemctl", "--user", "start", "hyprpolkitagent"])
    }
}
