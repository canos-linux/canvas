pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string env: Quickshell.env("CANVAS_EDITION") || ""
    property bool hasPrivate: false
    property bool loaded: false
    readonly property bool ready: env !== "" || loaded
    readonly property bool priv: env === "private" || (env === "" && hasPrivate)

    FileView {
        path: Quickshell.env("HOME") + "/.config/canvas/private.json"
        blockLoading: true
        onLoaded: {
            root.hasPrivate = true
            root.loaded = true
        }
        onLoadFailed: {
            root.hasPrivate = false
            root.loaded = true
        }
    }
}
