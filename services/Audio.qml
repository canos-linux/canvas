pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root
    property var sink: Pipewire.defaultAudioSink
    property real volume: sink && sink.audio ? sink.audio.volume : 0
    property bool muted: sink && sink.audio ? sink.audio.muted : false
    property bool ready: false
    property string icon: muted ? "󰝟" : volume > 0.6 ? "󰕾" : volume > 0.25 ? "󰖀" : "󰕿"
    signal bumped()

    onVolumeChanged: if (ready) bumped()
    onMutedChanged: if (ready) bumped()

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    Timer {
        interval: 1500
        running: true
        onTriggered: root.ready = true
    }

    function setVolume(v) {
        if (sink && sink.audio) sink.audio.volume = Math.max(0, Math.min(1, v))
    }

    function toggleMute() {
        if (sink && sink.audio) sink.audio.muted = !muted
    }
}
