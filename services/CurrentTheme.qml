pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../core"

Singleton {
    id: root
    readonly property string home: Quickshell.env("HOME")
    readonly property var roots: [home + "/.local/share/canvas/themes", Quickshell.shellDir + "/themes"]
    readonly property string statePath: Edition.priv ? home + "/Themes/current" : home + "/.local/state/canvas/theme"
    property string name: ""
    property string dir: ""
    property bool hasVideo: false
    property var themes: []      // visible in the theme switcher
    property var allThemes: []   // including deleted built-in themes
    readonly property string userRoot: home + "/.local/share/canvas/themes"
    readonly property var hiddenList: Config.opt.hiddenThemes.split(",").filter(s => s !== "")
    onHiddenListChanged: filter()

    function filter() {
        if (Edition.priv) {
            themes = allThemes
        } else {
            const v = allThemes.filter(t => t.user || hiddenList.indexOf(t.name) === -1)
            themes = v.length > 0 ? v : allThemes.slice(0, 1)
        }
        resolve()
        if (!Edition.priv && themes.length > 0 && name !== "" && !themes.some(t => t.name === name)) apply(themes[0])
    }

    // user themes are removed from disk, built-in ones are only hidden; one theme always stays
    function remove(t) {
        if (themes.length < 2 || !t) return
        if (t.user) {
            Quickshell.execDetached(["sh", "-c", "case \"$1\" in \"$2\"/*) rm -rf \"$1\";; esac", "sh", t.dir, userRoot])
            refreshSoon.restart()
        } else {
            Config.opt.hiddenThemes = hiddenList.concat([t.name]).join(",")
        }
    }

    // share: one file (tar.gz) "<name>.canostheme" in Downloads
    signal shared(string path)
    signal imported(bool ok)

    function exportTheme(t) {
        exporter.command = ["sh", "-c", "mkdir -p \"$HOME/Downloads\"; f=\"$HOME/Downloads/$2.canostheme\"; tar czf \"$f\" -C \"$(dirname \"$1\")\" \"$(basename \"$1\")\" && echo \"$f\"", "sh", t.dir, t.name]
        exporter.running = true
    }

    function importFile(path) {
        importer.command = ["sh", "-c", `
t=$(mktemp -d) || exit 1
tar xzf "$1" -C "$t" 2>/dev/null || { rm -rf "$t"; exit 1; }
src=$(dirname "$(find "$t" -maxdepth 2 -name theme.json | head -1)")
[ -f "$src/theme.json" ] && [ -f "$src/lock.png" ] || { rm -rf "$t"; exit 1; }
n=$(basename "$src"); [ "$src" = "$t" ] && n=$(basename "$1" .canostheme)
n=$(printf '%s' "$n" | tr -cs 'a-zA-Z0-9-' '-' | sed 's/^-*//; s/-*$//'); [ -n "$n" ] || n=theme
mkdir -p "$2"; b=$n; i=2; while [ -e "$2/$n" ] || [ -e "$3/$n" ]; do n="$b-$i"; i=$((i+1)); done; d="$2/$n"
mkdir -p "$d" && cp -r "$src"/. "$d"/ && find "$d" -type f ! -name '*.png' ! -name '*.jpg' ! -name '*.mp4' ! -name '*.json' -delete
rm -rf "$t"; echo "$n"`, "sh", path, userRoot, Quickshell.shellDir + "/themes"]
        importer.running = true
    }

    Process {
        id: exporter
        stdout: StdioCollector { onStreamFinished: if (text.trim() !== "") root.shared(text.trim()) }
    }

    Process {
        id: importer
        stdout: StdioCollector {
            onStreamFinished: {
                const n = text.trim()
                root.imported(n !== "")
                if (n !== "") {
                    importedName = n
                    root.refresh()
                    applyImported.restart()
                }
            }
        }
    }

    property string importedName: ""
    Timer {
        id: applyImported
        interval: 600
        onTriggered: root.apply(root.themes.find(t => t.name === root.importedName))
    }

    function restoreBuiltIn() {
        Config.opt.hiddenThemes = ""
    }

    Timer {
        id: refreshSoon
        interval: 400
        onTriggered: root.refresh()
    }
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
        } else if (themes.length > 0) {
            const t = themes.find(x => x.name === name) || themes.find(x => x.name === "canvas") || themes[0]
            dir = t.dir
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
        id: lister
        command: Edition.priv
            ? ["sh", "-c", "for d in \"$HOME\"/Themes/*/; do n=$(basename \"$d\"); [ -f \"$d/theme.fish\" ] || continue; h=0; [ -f \"$d/.hidden\" ] && h=1; c=$(grep -m1 '^set grub ' \"$d/theme.fish\" | awk '{print $3}'); echo \"$n|$h|$c|${d%/}\"; done"]
            : ["sh", "-c", "for r in \"$@\"; do for d in \"$r\"/*/; do [ -f \"$d/theme.json\" ] || continue; c=$(grep -o '\"color\" *: *\"#[0-9a-fA-F]*\"' \"$d/theme.json\" | grep -o '[0-9a-fA-F]\\{6\\}'); t=$(grep -o '\"name\" *: *\"[^\"]*\"' \"$d/theme.json\" | head -1 | sed 's/.*: *\"\\(.*\\)\"$/\\1/'); echo \"$(basename \"$d\")|0|$c|${d%/}|$t\"; done; done", "sh"].concat(root.roots)
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {}
                const list = []
                for (const l of text.trim().split("\n")) {
                    if (l === "") continue
                    const p = l.split("|")
                    if (seen[p[0]]) continue
                    seen[p[0]] = true
                    list.push({ name: p[0], hidden: p[1] === "1", color: p[2] ? "#" + p[2] : "#b9a4ff", dir: p[3], user: p[3].indexOf(root.userRoot + "/") === 0, title: p[4] || p[0] })
                }
                if (!Edition.priv) list.sort((a, b) => a.name === "canvas" ? -1 : b.name === "canvas" ? 1 : a.name.localeCompare(b.name))
                root.allThemes = list
                root.filter()
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
