import QtQuick
import "../core"
import "../services"
import "../ui"

Item {
    Row {
        anchors.centerIn: parent
        spacing: 12

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: Audio.icon
            size: 20
            color: Audio.muted ? Theme.subtext : Theme.text
        }

        Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: 180
            value: Audio.muted ? 0 : Audio.volume
            onMoved: v => Audio.setVolume(v)
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            horizontalAlignment: Text.AlignRight
            text: Math.round(Audio.volume * 100) + "%"
            weight: Font.Medium
        }
    }
}
