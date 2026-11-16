import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../ui"

Column {
    id: page
    width: parent ? parent.width : 400
    property var apps: []
    property var current: ({})
    readonly property var cats: [
        { key: "browser", icon: "󰖟", mimes: ["x-scheme-handler/http", "x-scheme-handler/https", "text/html", "application/xhtml+xml"] },
        { key: "files", icon: "󰉋", mimes: ["inode/directory"] },
        { key: "text", icon: "󰈙", mimes: ["text/plain", "text/markdown", "application/x-shellscript"] },
        { key: "images", icon: "󰋩", mimes: ["image/png", "image/jpeg", "image/gif", "image/webp", "image/bmp", "image/svg+xml"] },
        { key: "video", icon: "󰕧", mimes: ["video/mp4", "video/x-matroska", "video/webm", "video/quicktime", "video/x-msvideo"] },
        { key: "music", icon: "󰎆", mimes: ["audio/mpeg", "audio/flac", "audio/ogg", "audio/x-wav", "audio/mp4"] },
        { key: "pdf", icon: "󰈦", mimes: ["application/pdf"] },
        { key: "mail", icon: "󰇮", mimes: ["x-scheme-handler/mailto"] }
    ]

    onVisibleChanged: if (visible) query.running = true
    Component.onCompleted: if (visible) query.running = true

    function candidates(cat) {
        const cur = current[cat.mimes[0]] || ""
        return apps.filter(a => a.mimes.indexOf(cat.mimes[0]) !== -1 && (!a.hidden || a.id === cur))
    }

    Process {
        id: query
        command: ["sh", "-c", "for d in \"$HOME/.local/share/applications\" /var/lib/flatpak/exports/share/applications /usr/share/applications; do for f in \"$d\"/*.desktop; do [ -f \"$f\" ] || continue; h=0; grep -q '^NoDisplay=true' \"$f\" && h=1; m=$(grep -m1 '^MimeType=' \"$f\" | cut -d= -f2-); [ -n \"$m\" ] || continue; n=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); echo \"$(basename \"$f\")|$n|$m|$h\"; done; done; echo '|||'; for m in x-scheme-handler/http inode/directory text/plain image/png video/mp4 audio/mpeg application/pdf x-scheme-handler/mailto; do echo \"$m=$(xdg-mime query default $m 2>/dev/null)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.split("|||")
                const seen = {}
                const list = []
                for (const line of p[0].split("\n")) {
                    const f = line.split("|")
                    if (f.length < 3 || seen[f[0]]) continue
                    seen[f[0]] = true
                    list.push({ id: f[0], name: f[1], mimes: f[2].split(";"), hidden: f[3] === "1" })
                }
                list.sort((a, b) => a.name.localeCompare(b.name))
                page.apps = list
                const cur = {}
                for (const line of (p[1] || "").split("\n")) {
                    const i = line.indexOf("=")
                    if (i > 0) cur[line.slice(0, i)] = line.slice(i + 1).trim()
                }
                page.current = cur
            }
        }
    }

    Process {
        id: setDefault
        onExited: query.running = true
    }

    Txt {
        width: parent.width
        text: Lang.t.defaultAppsSub
        size: 13
        color: Theme.subtext
        wrapMode: Text.WordWrap
        bottomPadding: 6
    }

    Repeater {
        model: page.cats
        ChoiceRow {
            required property var modelData
            readonly property var list: page.candidates(modelData)
            visible: list.length > 0
            title: Lang.t["app_" + modelData.key]
            options: list.map(a => a.name)
            values: list.map(a => a.id)
            value: page.current[modelData.mimes[0]] || ""
            placeholder: Lang.t.none
            onPicked: v => {
                setDefault.command = ["xdg-mime", "default", v].concat(modelData.mimes)
                setDefault.running = true
            }
        }
    }
}
