import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../ui"

Column {
    id: page
    width: parent ? parent.width : 400
    property var mons: []
    property var specs: ({})
    property var backup: null
    property int countdown: 0
    readonly property string dir: Quickshell.env("HOME") + "/.config/hypr/config"

    onVisibleChanged: if (visible) query.running = true
    Component.onCompleted: if (visible) query.running = true

    function primaryName() {
        return mons.length ? mons[0].name : ""
    }

    function resOf(mode) {
        return mode.split("@")[0]
    }

    function resolutions(m) {
        const seen = []
        for (const s of m.availableModes) {
            const r = s.split("@")[0]
            if (seen.indexOf(r) === -1) seen.push(r)
        }
        seen.sort((a, b) => {
            const pa = a.split("x").map(Number), pb = b.split("x").map(Number)
            return pb[0] * pb[1] - pa[0] * pa[1]
        })
        return seen
    }

    function rates(m, res) {
        const r = []
        for (const s of m.availableModes) {
            const p = s.split("@")
            if (p[0] === res) {
                const hz = parseFloat(p[1]).toFixed(2)
                if (r.indexOf(hz) === -1) r.push(hz)
            }
        }
        r.sort((a, b) => b - a)
        return r
    }

    function load(list) {
        list.sort((a, b) => (a.name.startsWith("eDP") ? -1 : 0) - (b.name.startsWith("eDP") ? -1 : 0))
        const sp = {}
        const prim = list.length ? list[0] : null
        for (const m of list) {
            let pos = "0x0"
            if (prim && m !== prim) {
                if (m.mirrorOf && m.mirrorOf !== "none") pos = "mirror"
                else if (m.x < prim.x) pos = "auto-left"
                else if (m.y < prim.y) pos = "auto-up"
                else if (m.y > prim.y && m.x < prim.x + prim.width) pos = "auto-down"
                else pos = "auto-right"
            }
            sp[m.name] = {
                res: m.width + "x" + m.height,
                rate: m.refreshRate.toFixed(2),
                scale: Math.round(m.scale * 100) / 100,
                pos: pos,
                disabled: !!m.disabled
            }
        }
        mons = list
        specs = sp
    }

    function lua(name, s) {
        if (s.disabled) return 'hl.monitor({ output = "' + name + '", disabled = true })'
        let l = 'hl.monitor({ output = "' + name + '", mode = "' + s.res + "@" + s.rate + '", scale = ' + s.scale
        if (s.pos === "mirror") l += ', position = "auto", mirror = "' + primaryName() + '"'
        else l += ', position = "' + s.pos + '"'
        return l + " })"
    }

    function allLua(sp) {
        const lines = []
        for (const m of mons) if (sp[m.name]) lines.push(lua(m.name, sp[m.name]))
        return lines.join("\n")
    }

    function write(code) {
        const file = "-- Written by Canvas Settings\nhl.monitor({ output = \"\", mode = \"preferred\", position = \"auto\", scale = 1.0 })\n" + code + "\n"
        apply.command = ["sh", "-c", 'mkdir -p "$1" && printf "%s" "$2" > "$1/monitors.lua" && hyprctl eval "$3"', "sh", dir, file, code]
        apply.running = true
    }

    function change(name, key, val) {
        if (!backup) backup = JSON.parse(JSON.stringify(specs))
        const sp = JSON.parse(JSON.stringify(specs))
        sp[name][key] = val
        if (key === "res") {
            const m = mons.find(x => x.name === name)
            const r = rates(m, val)
            if (r.indexOf(sp[name].rate) === -1) sp[name].rate = r[0]
        }
        specs = sp
        write(allLua(sp))
        countdown = 15
    }

    function keep() {
        backup = null
        countdown = 0
    }

    function revert() {
        if (backup) {
            specs = backup
            write(allLua(backup))
        }
        keep()
    }

    Timer {
        interval: 1000
        repeat: true
        running: page.countdown > 0
        onTriggered: {
            page.countdown--
            if (page.countdown === 0) page.revert()
        }
    }

    Process {
        id: query
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { page.load(JSON.parse(text)) } catch (e) {}
            }
        }
    }

    Process {
        id: apply
        onExited: refresh.restart()
    }

    Timer {
        id: refresh
        interval: 800
        onTriggered: query.running = true
    }

    Rectangle {
        width: parent.width
        height: page.countdown > 0 ? 64 : 0
        visible: height > 0
        radius: 20
        color: Theme.alpha(Theme.accent, 0.18)
        Behavior on height { NumberAnimation { duration: Theme.dur(220) } }
        Txt {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: Lang.t.displayKeep.arg(page.countdown)
            weight: Font.Medium
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            PillButton { text: Lang.t.displayRevert; onClicked: page.revert() }
            PillButton { text: Lang.t.displayKeepBtn; primary: true; onClicked: page.keep() }
        }
    }

    Repeater {
        model: page.mons
        Column {
            id: monCol
            required property var modelData
            required property int index
            readonly property var m: modelData
            readonly property var s: page.specs[m.name] || ({ res: "", rate: "", scale: 1, pos: "0x0", disabled: false })
            width: page.width
            Txt {
                text: (monCol.m.make && monCol.m.make !== "Unknown" ? monCol.m.make + " · " : "") + monCol.m.name
                size: 13
                weight: Font.DemiBold
                color: Theme.accent
                topPadding: 14
                bottomPadding: 2
            }
            SettingRow {
                visible: monCol.index > 0
                title: Lang.t.displayOn
                Toggle {
                    checked: !monCol.s.disabled
                    onToggled: v => page.change(monCol.m.name, "disabled", !v)
                }
            }
            ChoiceRow {
                visible: !monCol.s.disabled
                title: Lang.t.resolution
                options: page.resolutions(monCol.m).map(r => r.replace("x", " × "))
                values: page.resolutions(monCol.m)
                value: monCol.s.res
                onPicked: v => page.change(monCol.m.name, "res", v)
            }
            ChoiceRow {
                visible: !monCol.s.disabled
                title: Lang.t.refreshRate
                options: page.rates(monCol.m, monCol.s.res).map(r => Math.round(r) + " Hz")
                values: page.rates(monCol.m, monCol.s.res)
                value: monCol.s.rate
                onPicked: v => page.change(monCol.m.name, "rate", v)
            }
            ChoiceRow {
                visible: !monCol.s.disabled
                title: Lang.t.scale
                sub: Lang.t.scaleSub
                options: ["100 %", "125 %", "150 %", "175 %", "200 %"]
                values: [1, 1.25, 1.5, 1.75, 2]
                value: monCol.s.scale
                onPicked: v => page.change(monCol.m.name, "scale", v)
            }
            ChoiceRow {
                visible: monCol.index > 0 && !monCol.s.disabled
                title: Lang.t.arrange
                sub: Lang.t.arrangeSub.arg(page.primaryName())
                options: [Lang.t.posRight, Lang.t.posLeft, Lang.t.posUp, Lang.t.posDown, Lang.t.posMirror]
                values: ["auto-right", "auto-left", "auto-up", "auto-down", "mirror"]
                value: monCol.s.pos
                onPicked: v => page.change(monCol.m.name, "pos", v)
            }
        }
    }
}
