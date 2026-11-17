pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../core"

// Monitors: arrangement, main display, first start with several displays, Identify.
// Settings are saved in ~/.config/hypr/config/monitors.lua (Hyprland) and
// /var/lib/canos (copy for the login screen).
Singleton {
    id: root
    property var mons: []
    property bool ready: false
    property bool identifying: false
    readonly property string mainName: Config.opt.mainDisplay !== "" && mons.some(m => m.name === Config.opt.mainDisplay) ? Config.opt.mainDisplay : best(mons)
    readonly property int count: mons.length
    readonly property string dir: Quickshell.env("HOME") + "/.config/hypr/config"
    // first start with several displays: only the main one is used until the welcome setup is done
    readonly property bool firstStart: !Config.opt.displaySetup && !Config.opt.welcomeDone && !Edition.priv
    signal changed()

    // biggest resolution, then highest possible refresh rate (monitors often start at 60 Hz)
    function maxMode(m) {
        let px = m.width * m.height, hz = m.refreshRate
        for (const s of (m.availableModes || [])) {
            const p = s.split("@"), r = p[0].split("x").map(Number), f = parseFloat(p[1])
            if (r[0] * r[1] > px) px = r[0] * r[1]
            if (f > hz) hz = f
        }
        return { px: px, hz: hz }
    }

    function best(list) {
        if (!list || !list.length) return ""
        const s = list.slice().sort((a, b) => {
            const ma = maxMode(a), mb = maxMode(b)
            return mb.px - ma.px || mb.hz - ma.hz
        })
        return s[0].name
    }

    // number shown by Identify and in the arrangement (sorted by Hyprland id)
    function numberOf(name) {
        const i = mons.findIndex(m => m.name === name)
        return i + 1
    }

    function refresh() { query.running = true }

    function identify() {
        identifying = true
        identTimer.restart()
    }

    function saved() {
        try { return JSON.parse(Config.opt.displays || "{}") } catch (e) { return {} }
    }

    function preferredMode(m) {
        const s = (m.availableModes || [])[0] || ""
        const p = s.split("@")
        return { res: p[0] || (m.width + "x" + m.height), rate: p[1] ? parseFloat(p[1]).toFixed(2) : m.refreshRate.toFixed(2) }
    }

    // specs: { name: { res, rate, scale, x, y, disabled, vrr, mirror } }
    function lua(specs, main) {
        const lines = []
        for (const m of mons) {
            const s = specs[m.name]
            if (!s) continue
            if (s.disabled && m.name !== main) {
                lines.push('hl.monitor({ output = "' + m.name + '", disabled = true })')
                continue
            }
            let l = 'hl.monitor({ output = "' + m.name + '", mode = "' + s.res + "@" + s.rate + '", scale = ' + s.scale
            if (s.mirror && main !== m.name) l += ', position = "auto", mirror = "' + main + '"'
            else l += ', position = "' + Math.round(s.x) + "x" + Math.round(s.y) + '"'
            if (s.vrr) l += ", vrr = 2"
            lines.push(l + " })")
        }
        if (main !== "") lines.push('hl.workspace_rule({ workspace = "1", monitor = "' + main + '", default = true })')
        return lines.join("\n")
    }

    function apply(specs, main) {
        const code = lua(specs, main)
        const file = "-- Written by Canvas Settings\nhl.monitor({ output = \"\", mode = \"preferred\", position = \"auto\", scale = 1.0 })\n" + code + "\n"
        const keep = {}
        for (const n in specs) keep[n] = { vrr: !!specs[n].vrr, mirror: !!specs[n].mirror }
        Config.opt.displays = JSON.stringify(keep)
        Config.opt.mainDisplay = main
        writer.command = ["sh", "-c",
            'mkdir -p "$1" && printf "%s" "$2" > "$1/monitors.lua"; hyprctl eval "$3" >/dev/null; '
            + 'if [ -w /var/lib/canos ]; then (umask 002; rm -f /var/lib/canos/monitors.lua /var/lib/canos/main-display 2>/dev/null; printf "%s" "$2" > /var/lib/canos/monitors.lua; printf "%s" "$4" > /var/lib/canos/main-display); fi; '
            + 'hyprctl dispatch "hl.dsp.focus({ monitor = \\"$4\\" })" >/dev/null; true',
            "sh", dir, file, code, main]
        writer.running = true
    }

    // current state of all monitors as specs (positions in logical pixels)
    function specsNow() {
        const keep = saved()
        const sp = {}
        for (const m of mons) {
            const pm = preferredMode(m)
            const off = m.disabled || m.width <= 0
            sp[m.name] = {
                res: off ? pm.res : m.width + "x" + m.height,
                rate: off ? pm.rate : m.refreshRate.toFixed(2),
                scale: Math.round((m.scale || 1) * 100) / 100,
                x: m.x,
                y: m.y,
                disabled: !!m.disabled,
                vrr: keep[m.name] ? keep[m.name].vrr : false,
                mirror: m.mirrorOf && m.mirrorOf !== "none" ? true : (keep[m.name] ? keep[m.name].mirror : false)
            }
        }
        return sp
    }

    // logical size of a spec
    function sizeOf(s) {
        const r = s.res.split("x").map(Number)
        return { w: Math.round(r[0] / (s.scale || 1)), h: Math.round(r[1] / (s.scale || 1)) }
    }

    // all displays on, side by side from left to right (main first)
    function sideBySide(sp, main) {
        const order = mons.map(m => m.name).sort((a, b) => (a === main ? -1 : b === main ? 1 : 0))
        let x = 0
        for (const n of order) {
            const s = sp[n]
            s.disabled = false
            s.mirror = false
            s.x = x
            s.y = 0
            x += sizeOf(s).w
        }
        return sp
    }

    // first start: use only the best display until the welcome setup is done.
    // Written to monitors.lua: Hyprland reloads its config files when Canvas writes them,
    // which would undo a runtime-only change.
    function firstStartSingle() {
        const main = mainName
        const code = mons.filter(m => m.name !== main && !m.disabled).map(m => 'hl.monitor({ output = "' + m.name + '", disabled = true })').join("\n")
        console.info("Displays: first start, only", main)
        if (code === "") return focusMain()
        const file = "-- Written by Canvas (first start: only the main display until the welcome setup is done)\nhl.monitor({ output = \"\", mode = \"preferred\", position = \"auto\", scale = 1.0 })\n" + code + "\n"
        writer.command = ["sh", "-c", 'mkdir -p "$1" && printf "%s" "$2" > "$1/monitors.lua"; hyprctl eval "$3" >/dev/null; hyprctl dispatch "hl.dsp.focus({ monitor = \\"$4\\" })" >/dev/null; true', "sh", dir, file, code, main]
        writer.running = true
    }

    // welcome setup reached the display step (or was skipped): all displays on
    function enableAll() {
        if (mons.length < 2) return
        const sp = sideBySide(specsNow(), mainName)
        apply(sp, mainName)
    }

    function focusMain() {
        if (mainName !== "") Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.focus({ monitor = "' + mainName + '" })'])
    }

    Timer {
        id: identTimer
        interval: 3000
        onTriggered: root.identifying = false
    }

    Process {
        id: writer
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") console.warn("Displays writer:", text.trim())
        }
        onExited: (code, status) => {
            console.info("Displays: settings written, exit", code)
            refreshLater.restart()
        }
    }

    Timer {
        id: refreshLater
        interval: 700
        onTriggered: root.refresh()
    }

    Process {
        id: query
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list = []
                try { list = JSON.parse(text) } catch (e) { return }
                list.sort((a, b) => a.id - b.id)
                root.mons = list
                root.changed()
                if (!root.ready) {
                    console.info("Displays:", list.map(m => m.name + (m.disabled ? "(off)" : "")).join(" "), "main", root.mainName, "firstStart", root.firstStart)
                    if (root.firstStart && list.filter(m => !m.disabled).length > 1) root.firstStartSingle()
                    else root.focusMain()
                    root.ready = true
                }
            }
        }
    }

    Socket {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/hypr/" + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/.socket2.sock"
        connected: true
        parser: SplitParser {
            onRead: data => {
                if (/^(monitoradded|monitorremoved)/.test(data)) refreshLater.restart()
            }
        }
    }

    Component.onCompleted: refresh()
}
