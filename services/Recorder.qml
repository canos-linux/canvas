pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../core"

Singleton {
    id: root
    property bool active: false
    property int seconds: 0
    property string file: ""
    readonly property string time: Math.floor(seconds / 60) + ":" + String(seconds % 60).padStart(2, "0")
    signal finished(string path)

    function start(region) {
        if (proc.running) return
        file = ""
        seconds = 0
        proc.command = ["sh", "-c", `
dir="$HOME/Videos/Recordings"; mkdir -p "$dir"
f="$dir/Recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"
set -- -f "$f" -c libx264 -p preset=veryfast -p crf=23
if [ "$REGION" = 1 ]; then g=$(slurp -d) || exit 3; set -- "$@" -g "$g"; else set -- "$@" -o "$MON"; fi
if [ "$AUDIO" = 1 ]; then s=$(pactl get-default-sink 2>/dev/null); [ -n "$s" ] && set -- "$@" --audio="$s.monitor"; fi
echo "FILE:$f"
exec wf-recorder "$@"`]
        proc.environment = { REGION: region ? "1" : "0", AUDIO: Config.opt.recordAudio ? "1" : "0", MON: Hypr.focusedMonitor }
        proc.running = true
    }

    function stop() {
        if (proc.running) Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"])
    }

    function toggle(region) {
        if (proc.running) stop()
        else start(region)
    }

    Process {
        id: proc
        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("FILE:")) {
                    root.file = data.slice(5)
                    root.active = true
                    Sounds.play("record")
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                const was = root.active
                root.active = false
                if (was && root.file !== "") {
                    Sounds.play("record")
                    root.finished(root.file)
                }
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.active
        onTriggered: root.seconds++
    }
}
