pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import QtQuick
import "../core"

Singleton {
    id: root
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool powered: adapter ? adapter.enabled : false
    readonly property bool discovering: adapter ? adapter.discovering : false
    readonly property var devices: adapter ? adapter.devices.values : []
    readonly property var connectedDevices: devices.filter(d => d.connected)
    readonly property string device: connectedDevices.length > 0 ? connectedDevices[0].name : ""
    readonly property string icon: !powered ? "󰂲" : device !== "" ? "󰂱" : "󰂯"
    readonly property string label: !available ? Lang.t.btNoAdapter : !powered ? Lang.t.off : device !== "" ? device : Lang.t.on

    // pairing agent prompt: "" | "confirm" | "authorize" | "pin" | "passkey" | "display"
    property string prompt: ""
    property string promptCode: ""
    property string pendingPair: ""
    property bool ready: false

    signal deviceConnected(var d)

    function toggle() { setPowered(!powered) }

    function setPowered(on) {
        if (!adapter) return
        if (on) Quickshell.execDetached(["rfkill", "unblock", "bluetooth"])
        adapter.enabled = on
    }

    function scan(on) {
        if (adapter && adapter.enabled && adapter.discovering !== on) adapter.discovering = on
    }

    function glyph(d) {
        const i = d && d.icon ? d.icon : ""
        if (i.indexOf("headset") !== -1 || i.indexOf("headphone") !== -1) return "󰋋"
        if (i.indexOf("audio") !== -1) return "󰓃"
        if (i.indexOf("keyboard") !== -1) return "󰌌"
        if (i.indexOf("mouse") !== -1) return "󰍽"
        if (i.indexOf("gaming") !== -1) return "󰊴"
        if (i.indexOf("phone") !== -1) return "󰏲"
        if (i.indexOf("computer") !== -1) return "󰍹"
        if (i.indexOf("watch") !== -1) return "󰖉"
        return "󰂯"
    }

    // devices without a real name only show their address – hide them from "nearby"
    function named(d) {
        return d.deviceName !== "" && !/^([0-9A-F]{2}[:-]){5}[0-9A-F]{2}$/i.test(d.deviceName)
    }

    function activate(d) {
        if (d.connected) d.disconnect()
        else if (d.paired) d.connect()
        else {
            pendingPair = d.address
            d.trusted = true
            d.pair()
        }
    }

    function answer(text) {
        agent.write(text + "\n")
        prompt = ""
        promptCode = ""
    }

    // connect right after pairing finished
    Timer {
        interval: 800
        repeat: true
        running: root.pendingPair !== ""
        onTriggered: {
            const d = root.devices.find(x => x.address === root.pendingPair)
            if (!d) { root.pendingPair = ""; return }
            if (d.paired) {
                root.pendingPair = ""
                d.connect()
            } else if (!d.pairing) {
                root.pendingPair = ""
                root.prompt = ""
            }
        }
    }

    property var known: []
    onConnectedDevicesChanged: {
        const now = connectedDevices.map(d => d.address)
        if (ready) {
            for (const d of connectedDevices)
                if (known.indexOf(d.address) === -1) deviceConnected(d)
        }
        known = now
    }

    Timer {
        interval: 3000
        running: true
        onTriggered: root.ready = true
    }

    // bluetoothctl as pairing agent (Quickshell has none) – prompts come without newline
    Process {
        id: agent
        running: root.available
        command: ["bluetoothctl"]
        stdinEnabled: true
        environment: ({ LC_ALL: "C" })
        onStarted: write("agent KeyboardDisplay\ndefault-agent\n")
        stdout: StdioCollector {
            id: agentOut
            waitForEnd: false
            property int seen: 0
            onDataChanged: {
                if (text.length < seen) seen = 0
                const chunk = text.slice(seen).replace(/\x1b\[[0-9;]*[A-Za-z]|[\x01\x02\r]/g, "")
                seen = text.length
                let m
                if ((m = chunk.match(/Confirm passkey (\d+)/))) { root.promptCode = m[1]; root.prompt = "confirm" }
                else if ((m = chunk.match(/Passkey: (\d+)/))) { root.promptCode = m[1]; root.prompt = "display" }
                else if ((m = chunk.match(/PIN code: (\S+)/)) && chunk.indexOf("Enter PIN") === -1) { root.promptCode = m[1]; root.prompt = "display" }
                else if (chunk.indexOf("Enter PIN code") !== -1) { root.promptCode = ""; root.prompt = "pin" }
                else if (chunk.indexOf("Enter passkey") !== -1) { root.promptCode = ""; root.prompt = "passkey" }
                else if (/Accept pairing|Authorize service/.test(chunk)) { root.promptCode = ""; root.prompt = "authorize" }
                else if (/Pairing successful|Failed to pair|Request canceled/.test(chunk)) { root.prompt = ""; root.promptCode = "" }
            }
        }
    }
}
