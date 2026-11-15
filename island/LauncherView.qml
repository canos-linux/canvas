import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../core"
import "../ui"

Item {
    id: lv
    property bool active: false
    property var results: []
    property int sel: 0
    property var counts: ({})
    readonly property string usagePath: Quickshell.env("HOME") + "/.local/state/canvas/launcher.json"

    onActiveChanged: {
        if (active) {
            input.text = ""
            sel = 0
            update()
            focusTimer.restart()
        }
    }

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

    function update() {
        const raw = input.text
        const q = raw.trim().toLowerCase()
        const list = []
        if (raw.startsWith(">")) {
            const cmd = raw.slice(1).trim()
            if (cmd !== "") list.push({ kind: "cmd", name: Lang.t.runCommand, sub: cmd, glyph: "󰆍", value: cmd })
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
            text: input.text.startsWith(">") ? "󰆍" : input.text.startsWith("?") ? "󰖟" : "󰍉"
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
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                    lv.sel = Math.min(lv.results.length - 1, lv.sel + 1)
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
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
                text: Lang.t.launcherHint
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
}
