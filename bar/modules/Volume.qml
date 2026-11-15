import QtQuick
import Quickshell.Services.Pipewire
import "../../core"
import "."

Pill {
    id: volume
    property var sink: Pipewire.defaultAudioSink
    property real level: sink && sink.audio ? sink.audio.volume : 0
    property bool muted: sink && sink.audio ? sink.audio.muted : false

    icon: muted ? "󰝟" : level > 0.6 ? "󰕾" : level > 0.25 ? "󰖀" : "󰕿"
    iconColor: muted ? Theme.subtext : Theme.text
    label: Math.round(level * 100) + "%"

    PwObjectTracker { objects: volume.sink ? [volume.sink] : [] }

    WheelHandler {
        onWheel: event => {
            if (!volume.sink) return
            const step = event.angleDelta.y > 0 ? 0.05 : -0.05
            volume.sink.audio.volume = Math.max(0, Math.min(1, volume.level + step))
            volume.flash()
        }
    }
    TapHandler {
        onTapped: if (volume.sink) volume.sink.audio.muted = !volume.muted
    }
}
