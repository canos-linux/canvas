import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../core"
import "../services"
import "../ui"

Item {
    id: lv
    property bool active: false
    property var results: []
    property int sel: 0
    property var counts: ({})
    property var clips: []
    property string tab: "apps"
    property var files: []
    property var recent: []
    readonly property var tabs: [{ key: "apps", name: Lang.t.tabApps, icon: "󰀻" }, { key: "files", name: Lang.t.tabFiles, icon: "󰉋" }]
    readonly property string usagePath: Quickshell.env("HOME") + "/.local/state/canvas/launcher.json"

    onActiveChanged: {
        if (active) {
            input.text = IslandState.launcherPrefix
            if (IslandState.launcherPrefix === ";") clipLoader.running = true
            IslandState.launcherPrefix = ""
            tab = "apps"
            sel = 0
            recentLoader.running = true
            update()
            focusTimer.restart()
        }
    }

    // desktop entries load in the background: refresh once they are there (first open after login)
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            if (lv.active && lv.tab === "apps") lv.update()
        }
    }
    Component.onCompleted: DesktopEntries.applications.values.length

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: input.forceActiveFocus()
    }

    Binding {
        target: IslandState
        property: "launcherRows"
        value: Math.min(lv.results.length, 7)
    }

    FileView {
        id: usage
        path: lv.usagePath
        onLoaded: {
            try { lv.counts = JSON.parse(text()) } catch (e) { lv.counts = {} }
        }
    }

    Process {
        id: saver
        property string data: "{}"
        command: ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "sh", lv.usagePath, data]
    }

    Process {
        id: clipLoader
        command: ["sh", "-c", "cliphist list 2>/dev/null | head -60"]
        stdout: StdioCollector {
            onStreamFinished: {
                lv.clips = text.split("\n").filter(l => l !== "")
                if (lv.active && input.text.startsWith(";")) lv.update()
            }
        }
    }

    function setTab(t) {
        if (tab === t) return
        tab = t
        Sounds.play("click")
        update()
    }

    function fileGlyph(p) {
        const e = p.split(".").pop().toLowerCase()
        if (p.endsWith("/")) return "󰉋"
        if (["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp"].indexOf(e) !== -1) return "󰋩"
        if (["mp4", "mkv", "webm", "mov", "avi"].indexOf(e) !== -1) return "󰕧"
        if (["mp3", "flac", "ogg", "wav", "m4a"].indexOf(e) !== -1) return "󰎆"
        if (e === "pdf") return "󰈦"
        if (["zip", "tar", "gz", "xz", "7z", "rar", "zst"].indexOf(e) !== -1) return "󰗄"
        if (["qml", "js", "py", "java", "c", "cpp", "sh", "html", "css", "json", "lua", "rs"].indexOf(e) !== -1) return "󰈮"
        return "󰈙"
    }

    function fileItem(path) {
        const home = Quickshell.env("HOME")
        const clean = path.replace(/\/$/, "")
        const name = clean.split("/").pop()
        const dir = clean.slice(0, clean.length - name.length - 1).replace(home, "~")
        return { kind: "file", name: name, sub: dir || "/", glyph: fileGlyph(path), value: clean }
    }

    // recently used files (GTK/Qt apps write this file)
    Process {
        id: recentLoader
        command: ["sh", "-c", "f=\"$HOME/.local/share/recently-used.xbel\"; [ -f \"$f\" ] || exit 0; grep -o 'href=\"file://[^\"]*\"' \"$f\" | sed 's/^href=\"file:\\/\\///; s/\"$//' | tac | awk '!s[$0]++' | head -40 | while IFS= read -r p; do p=$(printf '%b' \"$(printf '%s' \"$p\" | sed 's/%/\\\\x/g')\"); [ -e \"$p\" ] && echo \"$p\"; done | head -7"]
        stdout: StdioCollector {
            onStreamFinished: {
                lv.recent = text.split("\n").filter(l => l !== "")
                if (lv.active && lv.tab === "files") lv.update()
            }
        }
    }

    Process {
        id: fileSearch
        property string term: ""
        command: ["sh", "-c", "cd \"$HOME\" || exit 0; if command -v fd >/dev/null; then fd -i -t f -t d --max-results 40 --max-depth 6 -- \"$1\" . ; else find . -maxdepth 6 -not -path '*/.*' -iname \"*$1*\" 2>/dev/null | head -40 | sed 's|^\\./||'; fi", "sh", term]
        stdout: StdioCollector {
            onStreamFinished: {
                const home = Quickshell.env("HOME")
                const t = fileSearch.term.toLowerCase()
                const list = text.split("\n").filter(l => l !== "").map(l => home + "/" + l.replace(/^\.\//, ""))
                // exact name matches and short paths first
                list.sort((a, b) => {
                    const na = a.replace(/\/$/, "").split("/").pop().toLowerCase().startsWith(t) ? 0 : 1
                    const nb = b.replace(/\/$/, "").split("/").pop().toLowerCase().startsWith(t) ? 0 : 1
                    return na - nb || a.split("/").length - b.split("/").length
                })
                lv.files = list.slice(0, 7)
                if (lv.active && lv.tab === "files") lv.update(true)
            }
        }
    }

    Timer {
        id: fileDebounce
        interval: 160
        onTriggered: {
            fileSearch.running = false
            fileSearch.running = true
        }
    }

    function score(entry, q) {
        const name = (entry.name || "").toLowerCase()
        const extra = ((entry.genericName || "") + " " + (entry.keywords || []).join(" ") + " " + (entry.comment || "")).toLowerCase()
        let s = 0
        if (name.startsWith(q)) s = 4
        else if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) s = 3
        else if (name.indexOf(q) !== -1) s = 2
        else if (extra.indexOf(q) !== -1) s = 1
        if (s === 0) return 0
        return s + Math.min(2, (lv.counts[entry.id] || 0) / 10)
    }

    function calc(q) {
        if (!/^[0-9+\-*/().,%^\s]+$/.test(q) || !/[0-9]/.test(q) || !/[+\-*/%^]/.test(q)) return null
        try {
            const value = Function("return (" + q.replace(/\^/g, "**").replace(/,/g, ".") + ")")()
            if (typeof value === "number" && isFinite(value)) return Math.round(value * 1e8) / 1e8
        } catch (e) {}
        return null
    }

    function update(fromSearch) {
        const raw = input.text
        const q = raw.trim().toLowerCase()
        const list = []
        const tm = q.match(/^timer\s+(\d+)\s*(s|sec|m|min|h)?$/)
        if (lv.tab === "files" && !/^[>;?]/.test(raw)) {
            if (q === "") {
                for (const p of lv.recent) list.push(fileItem(p))
            } else if (fromSearch) {
                for (const p of lv.files) list.push(fileItem(p))
            } else {
                fileSearch.term = raw.trim()
                fileDebounce.restart()
                for (const r of lv.results) if (r.kind === "file") list.push(r)
            }
        } else if (tm) {
            const n = parseInt(tm[1])
            const u = tm[2] || "m"
            const sec = u.startsWith("s") ? n : u === "h" ? n * 3600 : n * 60
            list.push({ kind: "timer", name: Lang.t.timerStart, sub: (sec >= 60 ? Math.floor(sec / 60) + " min " : "") + (sec % 60 ? sec % 60 + " s" : ""), glyph: "󱎫", value: String(sec) })
        } else if (raw.startsWith(">")) {
            const cmd = raw.slice(1).trim()
            if (cmd !== "") list.push({ kind: "cmd", name: Lang.t.runCommand, sub: cmd, glyph: "󰆍", value: cmd })
        } else if (raw.startsWith(";")) {
            if (raw === ";") clipLoader.running = true
            const term = raw.slice(1).trim().toLowerCase()
            for (const l of lv.clips) {
                const t = l.replace(/^[0-9]+\t/, "")
                if (term === "" || t.toLowerCase().indexOf(term) !== -1)
                    list.push({ kind: "clip", name: t.slice(0, 90), sub: Lang.t.clipHint, glyph: "󰅌", value: l })
                if (list.length >= 7) break
            }
        } else if (raw.startsWith("?")) {
            const term = raw.slice(1).trim()
            if (term !== "") list.push({ kind: "web", name: Lang.t.searchWeb, sub: term, glyph: "󰖟", value: term })
        } else {
            const result = calc(q.startsWith("=") ? q.slice(1).trim() : q)
            if (result !== null) list.push({ kind: "calc", name: Lang.num(result), sub: Lang.t.calcHint, glyph: "󰃬", value: String(result) })
            const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay)
            let ranked
            if (q === "") {
                ranked = apps.filter(e => lv.counts[e.id]).sort((a, b) => lv.counts[b.id] - lv.counts[a.id])
                if (ranked.length < 7) ranked = ranked.concat(apps.filter(e => !lv.counts[e.id]).sort((a, b) => a.name.localeCompare(b.name)))
            } else {
                ranked = apps.map(e => ({ e: e, s: score(e, q) })).filter(x => x.s > 0).sort((a, b) => b.s - a.s).map(x => x.e)
            }
            for (const e of ranked.slice(0, 7))
                list.push({ kind: "app", name: e.name, sub: e.genericName || e.comment || "", icon: e.icon, entry: e })
        }
        results = list.slice(0, 7)
        sel = 0
    }

    function run(i) {
        const r = results[i]
        if (!r) return
        if (r.kind === "app") {
            const c = Object.assign({}, lv.counts)
            c[r.entry.id] = (c[r.entry.id] || 0) + 1
            lv.counts = c
            saver.data = JSON.stringify(c)
            saver.running = true
            r.entry.execute()
        } else if (r.kind === "cmd") {
            Quickshell.execDetached(["sh", "-c", r.value])
        } else if (r.kind === "web") {
            Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(r.value)])
        } else if (r.kind === "clip") {
            Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", r.value])
        } else if (r.kind === "file") {
            Quickshell.execDetached(["xdg-open", r.value])
        } else if (r.kind === "timer") {
            IslandState.startTimer(parseInt(r.value))
        } else if (r.kind === "calc") {
            Quickshell.execDetached(["wl-copy", r.value])
        }
        IslandState.overlay = ""
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 66

        Icon {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: lv.tab === "files" ? "󰉋" : input.text.startsWith(">") ? "󰆍" : input.text.startsWith("?") ? "󰖟" : input.text.startsWith(";") ? "󰅌" : "󰍉"
            size: 22
            color: Theme.accent
            hoverable: false
        }

        TextInput {
            id: input
            anchors.left: searchIcon.right
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            selectionColor: Theme.alpha(Theme.accent, 0.4)
            font.family: Theme.font
            font.pixelSize: 18
            clip: true
            onTextChanged: lv.update()

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    IslandState.overlay = ""
                } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    lv.setTab(lv.tab === "apps" ? "files" : "apps")
                } else if (event.key === Qt.Key_Down) {
                    lv.sel = Math.min(lv.results.length - 1, lv.sel + 1)
                } else if (event.key === Qt.Key_Up) {
                    lv.sel = Math.max(0, lv.sel - 1)
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    lv.run(lv.sel)
                } else {
                    return
                }
                event.accepted = true
            }

            Txt {
                visible: input.text === ""
                anchors.verticalCenter: parent.verticalCenter
                text: lv.tab === "files" ? Lang.t.filesHint : Lang.t.launcherHint
                size: 16
                color: Theme.subtext
                opacity: 0.7
            }
        }
    }

    ListView {
        id: list
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.margins: 8
        anchors.topMargin: 0
        height: lv.results.length * 54
        interactive: false
        model: lv.results
        currentIndex: lv.sel
        highlightMoveDuration: Theme.dur(180)
        highlight: Rectangle {
            radius: 18
            color: Theme.alpha(Theme.accent, 0.18)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.4)
        }

        delegate: Item {
            id: row
            width: list.width
            height: 54
            NumberAnimation on opacity {
                from: 0
                to: 1
                duration: Theme.dur(200 + index * 40)
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 30
                    IconImage {
                        visible: modelData.kind === "app"
                        anchors.fill: parent
                        source: modelData.kind === "app" ? Quickshell.iconPath(modelData.icon, "application-x-executable") : ""
                    }
                    Icon {
                        visible: modelData.kind !== "app"
                        anchors.centerIn: parent
                        text: modelData.glyph || ""
                        size: 22
                        color: Theme.accent
                        hoverable: false
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Txt {
                        width: list.width - 90
                        text: modelData.name
                        size: modelData.kind === "calc" ? 17 : 15
                        weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Txt {
                        visible: text !== ""
                        width: list.width - 90
                        text: modelData.sub
                        size: 12
                        color: Theme.subtext
                        elide: Text.ElideRight
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: lv.sel = index
                onClicked: lv.run(index)
            }
        }
    }

    Row {
        id: tabBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        height: 40
        spacing: 6
        Repeater {
            model: lv.tabs
            Rectangle {
                width: (tabBar.width - 6) / 2
                height: 40
                radius: 20
                color: lv.tab === modelData.key ? Theme.alpha(Theme.accent, 0.85) : tabHov.hovered ? Theme.surfaceHigh : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.dur(180) } }
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.icon
                        size: 16
                        hoverable: false
                        color: lv.tab === modelData.key ? Theme.base : Theme.text
                    }
                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        weight: Font.DemiBold
                        color: lv.tab === modelData.key ? Theme.base : Theme.text
                    }
                }
                HoverHandler { id: tabHov }
                TapHandler { onTapped: lv.setTab(modelData.key) }
            }
        }
    }
}
