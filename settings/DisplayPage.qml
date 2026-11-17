import QtQuick
import Quickshell
import "../core"
import "../services"
import "../ui"

Column {
    id: page
    width: parent ? parent.width : 400
    property var specs: ({})
    property string main: ""
    property string sel: ""
    property var backup: null
    property int countdown: 0
    // welcome setup: no 15 s revert question
    property bool compact: false
    property bool dragging: false
    readonly property var selMon: Displays.mons.find(m => m.name === sel) || null
    readonly property var selSpec: specs[sel] || ({ res: "", rate: "", scale: 1, x: 0, y: 0, disabled: false, vrr: false, mirror: false })

    onVisibleChanged: if (visible) Displays.refresh()
    Component.onCompleted: {
        load()
        Displays.refresh()
    }

    Connections {
        target: Displays
        function onChanged() {
            if (page.countdown === 0 && !page.dragging) page.load()
        }
    }

    function copy(o) {
        return JSON.parse(JSON.stringify(o))
    }

    function load() {
        specs = Displays.specsNow()
        main = Displays.mainName
        if (!specs[sel]) sel = main
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

    // place a display that is switched on again right of all others
    function placeRight(sp, name) {
        let x = 0
        for (const n in sp) if (n !== name && !sp[n].disabled && !sp[n].mirror) x = Math.max(x, sp[n].x + Displays.sizeOf(sp[n]).w)
        sp[name].x = x
        sp[name].y = 0
    }

    function normalize(sp) {
        let minX = Infinity, minY = Infinity
        for (const n in sp) if (!sp[n].disabled && !sp[n].mirror) {
            minX = Math.min(minX, sp[n].x)
            minY = Math.min(minY, sp[n].y)
        }
        if (minX === Infinity) return sp
        for (const n in sp) {
            sp[n].x -= minX
            sp[n].y -= minY
        }
        return sp
    }

    function commit(sp, m) {
        if (!compact && !backup) backup = { specs: copy(specs), main: main }
        specs = sp
        main = m
        Displays.apply(normalize(copy(sp)), m)
        if (!compact) countdown = 15
    }

    function change(name, key, val) {
        const sp = copy(specs)
        sp[name][key] = val
        if (key === "res") {
            const r = rates(Displays.mons.find(x => x.name === name), val)
            if (r.indexOf(sp[name].rate) === -1) sp[name].rate = r[0]
        }
        if ((key === "disabled" && !val) || (key === "mirror" && !val)) placeRight(sp, name)
        commit(sp, main)
    }

    function setMain(name) {
        const sp = copy(specs)
        sp[name].disabled = false
        sp[name].mirror = false
        commit(sp, name)
    }

    function keep() {
        backup = null
        countdown = 0
    }

    function revert() {
        if (backup) {
            specs = backup.specs
            main = backup.main
            Displays.apply(copy(backup.specs), backup.main)
        }
        keep()
    }

    // drop a dragged display next to the closest edge of another display
    function snap(name, lx, ly) {
        const sp = copy(specs)
        const me = Displays.sizeOf(sp[name])
        let bestPos = null, bestDist = Infinity
        const others = Object.keys(sp).filter(n => n !== name && !sp[n].disabled && !sp[n].mirror)
        for (const n of others) {
            const o = sp[n], os = Displays.sizeOf(o)
            const clampY = Math.max(o.y - me.h + 1, Math.min(o.y + os.h - 1, ly))
            const clampX = Math.max(o.x - me.w + 1, Math.min(o.x + os.w - 1, lx))
            const cands = [
                { x: o.x + os.w, y: clampY },
                { x: o.x - me.w, y: clampY },
                { x: clampX, y: o.y - me.h },
                { x: clampX, y: o.y + os.h }
            ]
            for (const c of cands) {
                // snap edges that are almost aligned
                if (Math.abs(c.y - o.y) < os.h * 0.08) c.y = o.y
                if (Math.abs(c.y + me.h - (o.y + os.h)) < os.h * 0.08) c.y = o.y + os.h - me.h
                if (Math.abs(c.x - o.x) < os.w * 0.08) c.x = o.x
                const overlap = others.some(k => {
                    const q = sp[k], qs = Displays.sizeOf(q)
                    return c.x < q.x + qs.w && c.x + me.w > q.x && c.y < q.y + qs.h && c.y + me.h > q.y
                })
                if (overlap) continue
                const d = Math.hypot(c.x - lx, c.y - ly)
                if (d < bestDist) {
                    bestDist = d
                    bestPos = c
                }
            }
        }
        if (!bestPos) {
            specs = copy(specs)
            return
        }
        sp[name].x = Math.round(bestPos.x)
        sp[name].y = Math.round(bestPos.y)
        commit(sp, main)
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

    Item { width: 1; height: page.countdown > 0 ? 12 : 0 }

    // arrangement (like Windows): drag the displays, click one to change it
    Rectangle {
        id: area
        visible: Displays.count > 1
        width: parent.width
        height: page.compact ? 190 : 220
        radius: 20
        color: Theme.card

        readonly property var placed: Displays.mons.filter(m => page.specs[m.name] && !page.specs[m.name].disabled && !page.specs[m.name].mirror)
        readonly property var box: {
            let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity
            for (const m of placed) {
                const s = page.specs[m.name], z = Displays.sizeOf(s)
                x0 = Math.min(x0, s.x); y0 = Math.min(y0, s.y)
                x1 = Math.max(x1, s.x + z.w); y1 = Math.max(y1, s.y + z.h)
            }
            if (x0 === Infinity) return { x: 0, y: 0, w: 1920, h: 1080 }
            return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 }
        }
        readonly property real f: Math.min((width - 60) / box.w, (height - 50) / box.h)
        readonly property real ox: (width - box.w * f) / 2
        readonly property real oy: (height - box.h * f) / 2

        Repeater {
            model: area.placed
            Rectangle {
                id: tile
                required property var modelData
                readonly property var s: page.specs[modelData.name]
                readonly property var sz: Displays.sizeOf(s)
                readonly property bool isSel: page.sel === modelData.name
                readonly property bool isMain: page.main === modelData.name
                x: area.ox + (s.x - area.box.x) * area.f
                y: area.oy + (s.y - area.box.y) * area.f
                width: sz.w * area.f - 4
                height: sz.h * area.f - 4
                radius: 10
                z: tileArea.drag.active ? 2 : 1
                color: isSel ? Theme.alpha(Theme.accent, 0.3) : Theme.surfaceHigh
                border.width: 2
                border.color: isSel ? Theme.accent : Theme.alpha(Theme.text, 0.15)
                Behavior on color { ColorAnimation { duration: Theme.dur(150) } }

                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Displays.numberOf(tile.modelData.name)
                        size: Math.min(34, tile.height * 0.4)
                        weight: Font.Bold
                        color: tile.isSel ? Theme.accent : Theme.text
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: tile.height > 70
                        text: (tile.isMain ? "★ " : "") + tile.modelData.name
                        size: 11
                        color: Theme.subtext
                    }
                }

                MouseArea {
                    id: tileArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    drag.target: area.placed.length > 1 ? tile : null
                    drag.threshold: 6
                    preventStealing: true
                    onPressed: {
                        page.sel = tile.modelData.name
                        page.dragging = true
                    }
                    onCanceled: page.dragging = false
                    onReleased: {
                        page.dragging = false
                        if (!drag.active) return
                        const lx = (tile.x - area.ox) / area.f + area.box.x
                        const ly = (tile.y - area.oy) / area.f + area.box.y
                        page.snap(tile.modelData.name, lx, ly)
                    }
                }
            }
        }

        Txt {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 12
            text: Lang.t.displayDragHint
            size: 11
            color: Theme.subtext
        }
    }

    Item { width: 1; height: Displays.count > 1 ? 12 : 0 }

    Row {
        visible: Displays.count > 1
        spacing: 10
        PillButton {
            text: Lang.t.displayIdentify
            onClicked: Displays.identify()
        }
        Repeater {
            // displays that are off or mirrored are not in the arrangement: select them here
            model: Displays.mons.filter(m => page.specs[m.name] && (page.specs[m.name].disabled || page.specs[m.name].mirror))
            PillButton {
                required property var modelData
                text: Displays.numberOf(modelData.name) + " · " + modelData.name
                primary: page.sel === modelData.name
                onClicked: page.sel = modelData.name
            }
        }
    }

    Column {
        visible: page.selMon !== null
        width: parent.width

        Txt {
            text: page.selMon ? (Displays.count > 1 ? Lang.t.displayN.arg(Displays.numberOf(page.sel)) + " · " : "")
                + (page.selMon.make && page.selMon.make !== "Unknown" ? page.selMon.make + " " + (page.selMon.model || "") + " · " : "") + page.selMon.name : ""
            size: 13
            weight: Font.DemiBold
            color: Theme.accent
            topPadding: 16
            bottomPadding: 2
        }
        SettingRow {
            visible: Displays.count > 1
            title: Lang.t.displayMain
            sub: Lang.t.displayMainSub
            Toggle {
                checked: page.main === page.sel
                onToggled: v => { if (v) page.setMain(page.sel) }
            }
        }
        SettingRow {
            visible: Displays.count > 1 && page.main !== page.sel
            title: Lang.t.displayOn
            Toggle {
                checked: !page.selSpec.disabled
                onToggled: v => page.change(page.sel, "disabled", !v)
            }
        }
        SettingRow {
            visible: Displays.count > 1 && page.main !== page.sel && !page.selSpec.disabled
            title: Lang.t.displayMirror
            sub: Lang.t.displayMirrorSub
            Toggle {
                checked: page.selSpec.mirror
                onToggled: v => page.change(page.sel, "mirror", v)
            }
        }
        ChoiceRow {
            visible: !page.selSpec.disabled && page.selMon !== null
            title: Lang.t.resolution
            options: page.selMon ? page.resolutions(page.selMon).map(r => r.replace("x", " × ")) : []
            values: page.selMon ? page.resolutions(page.selMon) : []
            value: page.selSpec.res
            onPicked: v => page.change(page.sel, "res", v)
        }
        ChoiceRow {
            visible: !page.selSpec.disabled && page.selMon !== null
            title: Lang.t.refreshRate
            options: page.selMon ? page.rates(page.selMon, page.selSpec.res).map(r => (Math.abs(r - Math.round(r)) > 0.1 ? Lang.num(parseFloat(r).toFixed(2)) : Math.round(r)) + " Hz") : []
            values: page.selMon ? page.rates(page.selMon, page.selSpec.res) : []
            value: page.selSpec.rate
            onPicked: v => page.change(page.sel, "rate", v)
        }
        ChoiceRow {
            visible: !page.selSpec.disabled && !page.selSpec.mirror
            title: Lang.t.scale
            sub: Lang.t.scaleSub
            options: ["100 %", "125 %", "150 %", "175 %", "200 %"]
            values: [1, 1.25, 1.5, 1.75, 2]
            value: page.selSpec.scale
            onPicked: v => page.change(page.sel, "scale", v)
        }
        SettingRow {
            visible: !page.selSpec.disabled && page.selMon !== null && page.selMon.hardwareDetails !== undefined && page.selMon.hardwareDetails.vrrCapable === true
            title: Lang.t.displayVrr
            sub: Lang.t.displayVrrSub
            Toggle {
                checked: page.selSpec.vrr
                onToggled: v => page.change(page.sel, "vrr", v)
            }
        }
    }
}
