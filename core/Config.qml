pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string path: Quickshell.env("HOME") + "/.config/canvas/settings.json"
    property alias opt: adapter

    FileView {
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) writeAdapter()
        }

        JsonAdapter {
            id: adapter
            property string language: "en"
            property bool glass: false
            property real glassOpacity: 0.55
            property string animations: "normal"
            property bool hoverDate: true
            property int musicLinger: 8
            property int notifDuration: 5
            property bool visualizer: true
            property bool systemRings: true
            property bool dnd: false
            property bool wallpaper: false
            property bool notifications: false
            property bool lockscreen: false
            property bool ownColors: false
        }
    }
}
