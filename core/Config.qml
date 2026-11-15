pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string barStyle: "islands"
    property var left: [["settings", "workspaces"], ["music"]]
    property var center: [["clock"]]
    property var right: [["tray"], ["keyboard", "bluetooth", "network", "volume", "battery"]]
    readonly property string path: Quickshell.env("HOME") + "/.config/canvas/settings.json"

    FileView {
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const s = JSON.parse(text())
                if (s.barStyle) root.barStyle = s.barStyle
                if (s.bar && s.bar.left) root.left = s.bar.left
                if (s.bar && s.bar.center) root.center = s.bar.center
                if (s.bar && s.bar.right) root.right = s.bar.right
            } catch (e) {}
        }
    }
}
