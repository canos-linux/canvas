pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string home: Quickshell.env("HOME")
    readonly property var roots: [home + "/.local/share/canvas/themes", Quickshell.shellDir + "/themes"]
    readonly property string statePath: Edition.priv ? home + "/Themes/current" : home + "/.local/state/canvas/theme"
    property string name: ""
    property string dir: ""
    property bool hasVideo: false
    property var themes: []
    readonly property string face: Edition.priv ? (dir !== "" ? dir + "/face.png" : "") : home + "/.face"

    FileView {
        path: root.statePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.name = text().trim()
        onLoadFailed: if (!Edition.priv) root.name = "canvas"
    }

    onNameChanged: resolve()

    Connections {
        target: Edition
        function onPrivChanged() {
            root.resolve()
            root.refresh()
        }
    }

    function resolve() {
        if (name === "") {
            dir = ""
        } else if (Edition.priv) {
            dir = home + "/Themes/" + name
        } else {
            finder.running = false
            finder.running = true
        }
    }

    function refresh() {
        lister.running = false
        lister.running = true
    }

    function apply(t) {
        if (!t) return
        if (Edition.priv) {
            Quickshell.execDetached(["fish", "-c", "theme " + t.name])
            return
        }
        name = t.name
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "sh", statePath, t.name])
    }

    Process {
        id: finder
        command: ["sh", "-c", "n=\"$1\"; shift; for r in \"$@\"; do if [ -f \"$r/$n/theme.json\" ]; then echo \"$r/$n\"; exit 0; fi; done", "sh", root.name].concat(root.roots)
        stdout: StdioCollector {
            onStreamFinished: root.dir = text.trim()
        }
    }

    Process {
        id: lister
        command: Edition.priv
            ? ["sh", "-c", "for d in \"$HOME\"/Themes/*/; do n=$(basename \"$d\"); [ -f \"$d/theme.fish\" ] || continue; h=0; [ -f \"$d/.hidden\" ] && h=1; c=$(grep -m1 '^set grub ' \"$d/theme.fish\" | awk '{print $3}'); echo \"$n|$h|$c|${d%/}\"; done"]
            : ["sh", "-c", "for r in \"$@\"; do for d in \"$r\"/*/; do [ -f \"$d/theme.json\" ] || continue; c=$(grep -o '\"color\" *: *\"#[0-9a-fA-F]*\"' \"$d/theme.json\" | grep -o '[0-9a-fA-F]\\{6\\}'); echo \"$(basename \"$d\")|0|$c|${d%/}\"; done; done", "sh"].concat(root.roots)
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {}
                const list = []
                for (const l of text.trim().split("\n")) {
                    if (l === "") continue
                    const p = l.split("|")
                    if (seen[p[0]]) continue
                    seen[p[0]] = true
                    list.push({ name: p[0], hidden: p[1] === "1", color: p[2] ? "#" + p[2] : "#b9a4ff", dir: p[3] })
                }
                if (!Edition.priv) list.sort((a, b) => a.name === "canvas" ? -1 : b.name === "canvas" ? 1 : a.name.localeCompare(b.name))
                root.themes = list
            }
        }
    }

    Process {
        id: check
        command: ["test", "-f", root.dir + "/wallpaper.mp4"]
        onExited: code => root.hasVideo = code === 0
    }

    onDirChanged: if (dir !== "") check.running = true

    Component.onCompleted: {
        resolve()
        refresh()
    }
}
