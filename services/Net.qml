pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../core"

Singleton {
    id: root
    property int strength: 0
    property string ssid: ""
    property bool wired: false
    property bool enabled: true
    property bool hotspot: false
    property bool hasDevice: true
    property bool connected: wired || ssid !== ""
    property string icon: wired ? "󰈀" : !enabled ? "󰤭" : hotspot ? "󰀂" : ssid === "" ? "󰤮" : strength > 75 ? "󰤨" : strength > 50 ? "󰤥" : strength > 25 ? "󰤢" : "󰤟"
    property string label: wired ? "Ethernet" : !enabled ? Lang.t.off : hotspot ? Lang.t.wifiHotspot : ssid === "" ? Lang.t.offline : ssid

    // menu state
    property bool listening: false
    property bool scanning: false
    property var networks: []
    property var saved: []
    property string busy: ""
    property string error: ""
    property string errorFor: ""
    property string qrPath: ""
    property string qrSsid: ""
    property string qrPassword: ""
    property bool qrLoading: false

    function openSettings() {
        Quickshell.execDetached(["kitty", "-e", "nmtui"])
    }

    // nmcli -t escapes ":" and "\" inside values
    function fields(line) {
        const out = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            const c = line[i]
            if (c === "\\" && i + 1 < line.length) { cur += line[++i]; continue }
            if (c === ":") { out.push(cur); cur = ""; continue }
            cur += c
        }
        out.push(cur)
        return out
    }

    function band(freq) {
        const f = parseInt(freq)
        return f >= 5925 ? "6 GHz" : f >= 4900 ? "5 GHz" : "2.4 GHz"
    }

    function scan(rescan) {
        if (scanProc.running) return
        if (rescan) scanning = true
        scanProc.command = ["sh", "-c", scanScript, "sh", rescan ? "yes" : "no"]
        scanProc.running = true
    }

    function run(kind, ssid, script, args) {
        if (actProc.running) return
        error = ""
        errorFor = ""
        busy = kind === "connect" ? ssid : ""
        actProc.kind = kind
        actProc.ssid = ssid
        actProc.wasSaved = saved.indexOf(ssid) !== -1
        actProc.command = ["sh", "-c", "export LC_ALL=C; " + script, "sh"].concat(args)
        actProc.running = true
    }

    function connect(ssid, password, hidden) {
        const known = saved.indexOf(ssid) !== -1
        if (known && password === "")
            run("connect", ssid, "nmcli -w 30 connection up id \"$1\"", [ssid])
        else if (known)
            run("connect", ssid, "nmcli connection modify id \"$1\" wifi-sec.key-mgmt wpa-psk wifi-sec.psk \"$2\" && nmcli -w 30 connection up id \"$1\"", [ssid, password])
        else if (password !== "")
            run("connect", ssid, "nmcli -w 30 dev wifi connect \"$1\" password \"$2\" hidden \"$3\"", [ssid, password, hidden ? "yes" : "no"])
        else
            run("connect", ssid, "nmcli -w 30 dev wifi connect \"$1\" hidden \"$2\"", [ssid, hidden ? "yes" : "no"])
    }

    function disconnect(ssid) {
        run("down", ssid, "nmcli connection down id \"$1\"", [ssid])
    }

    function forget(ssid) {
        run("forget", ssid, "nmcli connection delete id \"$1\"", [ssid])
    }

    function setEnabled(on) {
        enabled = on
        if (!on) networks = []
        run("radio", "", "nmcli radio wifi \"$1\"", [on ? "on" : "off"])
    }

    function toggleHotspot() {
        if (hotspot) run("hotspot", "", "nmcli connection down Hotspot", [])
        else run("hotspot", "", "nmcli connection up Hotspot 2>/dev/null || nmcli dev wifi hotspot ssid \"$(cat /etc/hostname 2>/dev/null || echo CanOS)-CanOS\" password \"$(tr -dc a-z0-9 </dev/urandom | head -c 10)\"", [])
    }

    function share(ssid) {
        qrSsid = ssid
        qrPassword = ""
        qrPath = ""
        qrLoading = true
        qrProc.command = ["sh", "-c", qrScript, "sh", ssid, Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"]
        qrProc.running = true
    }

    function finish(code) {
        const kind = actProc.kind
        const ssid = actProc.ssid
        if (kind === "connect") {
            if (code !== 0) {
                const e = actErr.text + actOut.text
                error = /secret|password|psk|802-1x|key/i.test(e) ? Lang.t.wifiWrongPw : Lang.t.wifiFailed
                errorFor = ssid
                if (!actProc.wasSaved) Quickshell.execDetached(["nmcli", "connection", "delete", "id", ssid])
            }
            busy = ""
        }
        query.running = true
        scan(false)
    }

    readonly property string scanScript: "export LC_ALL=C; if [ \"$1\" = yes ]; then nmcli dev wifi rescan 2>/dev/null; sleep 2.5; fi; echo \"@RADIO $(nmcli radio wifi)\"; nmcli -t -f TYPE dev | grep -qx wifi && echo @DEV; nmcli -t -f NAME,TYPE connection show | grep ':802-11-wireless$' | sed 's/^/@SAVED /'; nmcli -t -f NAME connection show --active | sed 's/^/@ACTIVE /'; nmcli -t -f IN-USE,SIGNAL,SECURITY,FREQ,SSID dev wifi list --rescan no | sed 's/^/@NET /'"

    readonly property string qrScript: "export LC_ALL=C; p=$(nmcli -s -g 802-11-wireless-security.psk connection show id \"$1\" 2>/dev/null); s=$(nmcli -g 802-11-wireless.ssid connection show id \"$1\" 2>/dev/null); [ -n \"$s\" ] || s=\"$1\"; esc() { printf %s \"$1\" | sed 's/[\\\;,:\"]/\\\\&/g'; }; t=WPA; [ -n \"$p\" ] || t=nopass; rm -f \"$2\"/canvas-wifi-qr-*.png; f=\"$2/canvas-wifi-qr-$$.png\"; command -v qrencode >/dev/null && qrencode -o \"$f\" -s 10 -m 1 \"WIFI:T:$t;S:$(esc \"$s\");P:$(esc \"$p\");;\" && echo \"FILE $f\"; echo \"PW $p\""

    Process {
        id: scanProc
        stdout: StdioCollector {
            onStreamFinished: {
                const nets = {}
                const sav = []
                const act = []
                let radio = true
                let dev = false
                for (const l of text.split("\n")) {
                    if (l === "@DEV") dev = true
                    else if (l.startsWith("@RADIO ")) radio = l.slice(7).trim() === "enabled"
                    else if (l.startsWith("@SAVED ")) sav.push(root.fields(l.slice(7))[0])
                    else if (l.startsWith("@ACTIVE ")) act.push(root.fields(l.slice(8))[0])
                    else if (l.startsWith("@NET ")) {
                        const f = root.fields(l.slice(5))
                        const name = f.slice(4).join(":")
                        if (name === "") continue
                        const n = { ssid: name, level: parseInt(f[1]) || 0, secure: f[2] !== "" && f[2] !== "--", band: root.band(f[3]), active: f[0] === "*" }
                        const o = nets[name]
                        if (!o || n.active || (!o.active && n.level > o.level)) nets[name] = n
                    }
                }
                const list = Object.values(nets)
                for (const n of list) n.saved = sav.indexOf(n.ssid) !== -1
                list.sort((a, b) => (b.active - a.active) || (b.saved - a.saved) || (b.level - a.level))
                root.enabled = radio
                root.hasDevice = dev
                root.saved = sav
                root.hotspot = act.indexOf("Hotspot") !== -1
                root.networks = radio ? list : []
                root.scanning = false
            }
        }
    }

    Process {
        id: actProc
        property string kind: ""
        property string ssid: ""
        property bool wasSaved: false
        stdout: StdioCollector { id: actOut }
        stderr: StdioCollector { id: actErr }
        onExited: code => {
            finishTimer.code = code
            finishTimer.restart()
        }
    }

    Timer {
        id: finishTimer
        property int code: 0
        interval: 80
        onTriggered: root.finish(code)
    }

    Process {
        id: qrProc
        stdout: StdioCollector {
            onStreamFinished: {
                for (const l of text.split("\n")) {
                    if (l.startsWith("FILE ")) root.qrPath = "file://" + l.slice(5)
                    else if (l.startsWith("PW ")) root.qrPassword = l.slice(3)
                }
                root.qrLoading = false
            }
        }
    }

    Timer {
        interval: 10000
        running: root.listening
        repeat: true
        onTriggered: root.scan(false)
    }

    Process {
        id: query
        command: ["sh", "-c", "export LC_ALL=C; echo RADIO=$(nmcli radio wifi); nmcli -t -f TYPE,STATE dev | grep ^ethernet:connected >/dev/null && echo ETH; nmcli -t -f NAME connection show --active | grep -x Hotspot >/dev/null && echo HOTSPOT; nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev | grep :wifi:connected:; nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi list --rescan no | grep ^yes:; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                root.wired = lines.indexOf("ETH") !== -1
                root.hotspot = lines.indexOf("HOTSPOT") !== -1
                root.enabled = lines.indexOf("RADIO=disabled") === -1
                const dev = lines.find(l => l.indexOf(":wifi:connected:") !== -1)
                const act = lines.find(l => l.startsWith("yes:"))
                if (dev) {
                    const name = root.fields(dev).slice(3).join(":")
                    root.ssid = name !== "" ? name : act ? root.fields(act).slice(2).join(":") : ""
                    root.strength = act ? parseInt(act.split(":")[1]) || 0 : 0
                } else {
                    root.strength = 0
                    root.ssid = ""
                }
            }
        }
    }

    Timer {
        id: refresh
        interval: 500
        onTriggered: {
            query.running = true
            if (root.listening) root.scan(false)
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: query.running = true
    }

    Process {
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: refresh.restart()
        }
    }
}
