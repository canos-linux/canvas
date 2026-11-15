pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string home: Quickshell.env("HOME")
    property string name: ""
    property string dir: name !== "" ? home + "/Themes/" + name : ""
    property bool hasVideo: false

    FileView {
        path: root.home + "/Themes/current"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.name = text().trim()
    }

    Process {
        id: check
        command: ["test", "-f", root.dir + "/wallpaper.mp4"]
        onExited: code => root.hasVideo = code === 0
    }

    onDirChanged: if (dir !== "") check.running = true
}
