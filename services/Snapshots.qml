pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../core"

// snapper "root" config: list, create, undo changes (no reboot into a snapshot needed)
Singleton {
    id: root
    property bool ready: false      // snapper config root exists and is readable for the user
    property bool checked: false
    property var list: []           // newest first: { num, date, desc, type }
    property string busy: ""
    property string message: ""

    function refresh() { if (!q.running) q.running = true }

    function setup() {
        busy = "setup"
        message = ""
        job.command = ["sh", "-c", "pkexec sh -c 'pacman -S --needed --noconfirm snapper snap-pac >/dev/null && (snapper -c root list >/dev/null 2>&1 || snapper -c root create-config /) && snapper -c root set-config ALLOW_USERS=\"$1\" SYNC_ACL=yes TIMELINE_CREATE=no NUMBER_LIMIT=15 NUMBER_LIMIT_IMPORTANT=8 && snapper -c root create -c important -d \"First snapshot\"' sh \"$USER\""]
        job.running = true
    }

    function create(desc) {
        busy = "create"
        message = ""
        job.command = ["snapper", "-c", "root", "create", "-c", "important", "-d", desc || "Canvas"]
        job.running = true
    }

    function remove(num) {
        busy = "remove"
        job.command = ["snapper", "-c", "root", "delete", String(num)]
        job.running = true
    }

    // restore files of the system to the state of snapshot <num> (home folders are separate subvolumes)
    function restore(num) {
        busy = "restore"
        message = ""
        job.command = ["sh", "-c", "snapper -c root create -c important -d \"Before restore to #$1\" && snapper -c root undochange \"$1\"..0 >/dev/null 2>&1 || pkexec snapper -c root undochange \"$1\"..0 >/dev/null", "sh", String(num)]
        job.running = true
    }

    Process {
        id: job
        stderr: StdioCollector { id: jobErr }
        onExited: code => {
            const what = root.busy
            root.busy = ""
            if (code === 0) {
                root.message = what === "restore" ? Lang.t.snapRestored : what === "setup" ? Lang.t.snapReady : ""
                Sounds.play("notif")
            } else {
                root.message = Lang.t.snapFailed + (jobErr.text.trim() ? " – " + jobErr.text.trim().split("\n").pop() : "")
                Sounds.play("error")
            }
            root.refresh()
        }
    }

    Process {
        id: q
        command: ["sh", "-c", "command -v snapper >/dev/null || exit 3; snapper -c root --csvout list --columns number,date,description,type 2>/dev/null || exit 4"]
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = text.trim().split("\n").slice(1).map(l => {
                    const f = l.split(",")
                    return { num: parseInt(f[0]), date: f[1] || "", desc: f.slice(2, f.length - 1).join(",") || "", type: f[f.length - 1] }
                }).filter(r => r.num > 0)
                root.list = rows.reverse()
            }
        }
        onExited: code => {
            root.ready = code === 0
            root.checked = true
        }
    }
}
