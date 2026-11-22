pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../core"

// KDE Connect: phone notifications arrive as normal notifications (kdeconnectd posts them)
Singleton {
    id: root
    property bool installed: false
    property var devices: []   // { id, name, reachable, paired, battery, charging }
    property bool watching: false
    readonly property var main: devices.find(d => d.paired && d.reachable) || null

    function cli(args) {
        Quickshell.execDetached(["kdeconnect-cli"].concat(args))
        refreshSoon.restart()
    }
    function ping(id) { cli(["-d", id, "--ping"]) }
    function ring(id) { cli(["-d", id, "--ring"]) }
    function pair(id) { cli(["-d", id, "--pair"]) }
    function unpair(id) { cli(["-d", id, "--unpair"]) }
    function sendClipboard(id) {
        Quickshell.execDetached(["sh", "-c", "kdeconnect-cli -d \"$1\" --share-text \"$(wl-paste -n 2>/dev/null)\"", "sh", id])
    }
    function install() {
        Quickshell.execDetached(["kitty", "--title", "Canvas", "sh", "-c", "sudo pacman -S --needed kdeconnect; echo; read -t 15 -p 'Done – closing …' x"])
        checkSoon.restart()
    }
    function refresh() { if (installed && !query.running) query.running = true }

    Process {
        id: check
        running: Config.opt.phone
        command: ["sh", "-c", "command -v kdeconnect-cli >/dev/null || exit 1; pgrep -x kdeconnectd >/dev/null || (setsid -f /usr/lib/kdeconnectd >/dev/null 2>&1 || setsid -f kdeconnectd >/dev/null 2>&1); echo ok"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.installed = text.indexOf("ok") !== -1
                if (root.installed) refreshSoon.restart()
            }
        }
    }

    Timer {
        id: checkSoon
        interval: 20000
        onTriggered: check.running = true
    }

    Timer {
        id: refreshSoon
        interval: 1500
        onTriggered: root.refresh()
    }

    Timer {
        interval: 30000
        repeat: true
        running: Config.opt.phone && root.installed
        onTriggered: root.refresh()
    }

    // one line per device: id|name|reachable|paired|battery|charging
    Process {
        id: query
        command: ["sh", "-c", `
kdeconnect-cli -l --id-name-only 2>/dev/null | while read -r id name; do
  [ -n "$id" ] || continue
  r=$(busctl --user get-property org.kde.kdeconnect /modules/kdeconnect/devices/$id org.kde.kdeconnect.device isReachable 2>/dev/null | cut -d' ' -f2)
  p=$(busctl --user get-property org.kde.kdeconnect /modules/kdeconnect/devices/$id org.kde.kdeconnect.device isPaired 2>/dev/null | cut -d' ' -f2)
  b=$(busctl --user get-property org.kde.kdeconnect /modules/kdeconnect/devices/$id/battery org.kde.kdeconnect.device.battery charge 2>/dev/null | cut -d' ' -f2)
  c=$(busctl --user get-property org.kde.kdeconnect /modules/kdeconnect/devices/$id/battery org.kde.kdeconnect.device.battery isCharging 2>/dev/null | cut -d' ' -f2)
  echo "$id|$name|$r|$p|\${b:--1}|$c"
done`]
        stdout: StdioCollector {
            onStreamFinished: {
                root.devices = text.split("\n").filter(l => l.indexOf("|") > 0).map(l => {
                    const f = l.split("|")
                    return { id: f[0], name: f[1], reachable: f[2] === "true", paired: f[3] === "true", battery: parseInt(f[4]), charging: f[5] === "true" }
                })
            }
        }
    }
}
