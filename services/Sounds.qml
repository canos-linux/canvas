pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtMultimedia
import "../core"

Singleton {
    id: root
    readonly property bool on: Config.opt.sounds && !Gaming.mutes
    readonly property var names: ["click", "open", "close", "notif", "login", "shutdown", "shot", "record", "error"]
    property var effects: ({})

    function play(name) {
        if (!on) return
        const e = effects[name]
        if (!e) return
        if (name === "click" && clickGap.running) return
        if (name === "click") clickGap.restart()
        e.play()
    }

    Timer {
        id: clickGap
        interval: 60
    }

    Instantiator {
        model: root.names
        delegate: SoundEffect {
            required property string modelData
            source: "file://" + Quickshell.shellDir + "/sounds/" + modelData + ".wav"
            volume: Config.opt.soundVolume
            Component.onCompleted: {
                const m = Object.assign({}, root.effects)
                m[modelData] = this
                root.effects = m
            }
        }
    }

    // login sound once per session (not on every Canvas restart)
    Process {
        running: true
        command: ["sh", "-c", "f=\"${XDG_RUNTIME_DIR:-/tmp}/canvas-hello\"; [ -e \"$f\" ] && exit 0; touch \"$f\"; echo first"]
        stdout: StdioCollector {
            onStreamFinished: if (text.indexOf("first") !== -1) helloTimer.start()
        }
    }

    Timer {
        id: helloTimer
        interval: 900
        onTriggered: root.play("login")
    }
}
