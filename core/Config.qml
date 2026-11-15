pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string barStyle: "islands"

    FileView {
        path: Quickshell.env("HOME") + "/.config/canvas/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const s = JSON.parse(text())
                if (s.barStyle) root.barStyle = s.barStyle
            } catch (e) {}
        }
    }
}
