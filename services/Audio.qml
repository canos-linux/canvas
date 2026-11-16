pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root
    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    property real volume: sink && sink.audio ? sink.audio.volume : 0
    property bool muted: sink && sink.audio ? sink.audio.muted : false
    property real micVolume: source && source.audio ? source.audio.volume : 0
    property bool micMuted: source && source.audio ? source.audio.muted : false
    property bool ready: false
    property string icon: muted ? "󰝟" : volume > 0.6 ? "󰕾" : volume > 0.25 ? "󰖀" : "󰕿"
    property string micIcon: micMuted ? "󰍭" : "󰍬"

    readonly property var nodes: Pipewire.nodes.values
    readonly property var outputs: nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var inputs: nodes.filter(n => n.audio && !n.isSink && !n.isStream)
    readonly property var apps: nodes.filter(n => n.audio && n.isStream && !n.isSink)

    signal bumped()
    signal micBumped()

    onVolumeChanged: if (ready) bumped()
    onMutedChanged: if (ready) bumped()
    onMicMutedChanged: if (ready) micBumped()

    PwObjectTracker { objects: [root.sink, root.source].concat(root.outputs, root.inputs, root.apps).filter(x => x) }

    Timer {
        interval: 1500
        running: true
        onTriggered: root.ready = true
    }

    function clamp(v) { return Math.max(0, Math.min(1, v)) }

    function setVolume(v) {
        if (sink && sink.audio) sink.audio.volume = clamp(v)
    }

    function toggleMute() {
        if (sink && sink.audio) sink.audio.muted = !muted
    }

    function setMic(v) {
        if (source && source.audio) source.audio.volume = clamp(v)
    }

    function toggleMic() {
        if (source && source.audio) source.audio.muted = !micMuted
    }

    function setNode(n, v) {
        if (n && n.audio) n.audio.volume = clamp(v)
    }

    function toggleNode(n) {
        if (n && n.audio) n.audio.muted = !n.audio.muted
    }

    function setOutput(n) { Pipewire.preferredDefaultAudioSink = n }
    function setInput(n) { Pipewire.preferredDefaultAudioSource = n }

    function label(n) {
        return n ? (n.description || n.nickname || n.name || "?") : ""
    }

    function appName(n) {
        const p = n.properties || {}
        return p["application.name"] || n.description || n.name || "?"
    }

    function appIcon(n) {
        const p = n.properties || {}
        return p["application.icon-name"] || (p["application.process.binary"] || "").toLowerCase() || "audio-x-generic"
    }

    function outGlyph(n) {
        const s = ((n && n.name) || "") + " " + label(n).toLowerCase()
        if (s.indexOf("bluez") !== -1 || s.indexOf("headphone") !== -1 || s.indexOf("kopfh") !== -1 || s.indexOf("headset") !== -1) return "󰋋"
        if (s.indexOf("hdmi") !== -1 || s.indexOf("displayport") !== -1) return "󰡁"
        return "󰓃"
    }
}
