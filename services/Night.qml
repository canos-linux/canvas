pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../core"

Singleton {
    id: root
    readonly property string mode: Config.opt.nightMode
    property bool inWindow: false
    property bool available: false
    readonly property bool active: available && (mode === "on" || (mode === "auto" && inWindow))
    readonly property string label: !available ? Lang.t.nightMissing
        : mode === "off" ? Lang.t.off
        : mode === "on" ? Lang.t.on
        : Lang.t.nightAuto + " " + Config.opt.nightFrom + "–" + Config.opt.nightTo

    function minutes(s) {
        const p = String(s).split(":")
        return parseInt(p[0]) * 60 + (parseInt(p[1]) || 0)
    }

    function check() {
        const d = new Date()
        const now = d.getHours() * 60 + d.getMinutes()
        const a = minutes(Config.opt.nightFrom)
        const b = minutes(Config.opt.nightTo)
        inWindow = a <= b ? (now >= a && now < b) : (now >= a || now < b)
    }

    function cycle() {
        Config.opt.nightMode = mode === "off" ? "on" : mode === "on" ? "auto" : "off"
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.check()
    }

    Connections {
        target: Config.opt
        function onNightFromChanged() { root.check() }
        function onNightToChanged() { root.check() }
        function onNightTempChanged() {
            if (!sunset.running) return
            sunset.running = false
            restart.restart()
        }
    }

    Timer {
        id: restart
        interval: 300
        onTriggered: sunset.running = Qt.binding(() => root.active)
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v hyprsunset"]
        stdout: StdioCollector {
            onStreamFinished: root.available = text.trim() !== ""
        }
    }

    Process {
        id: sunset
        running: root.active
        command: ["hyprsunset", "-t", String(Config.opt.nightTemp)]
    }
}
