import QtQuick
import "../core"
import "../services"
import "../ui"

Item {
    Row {
        anchors.centerIn: parent
        spacing: 10
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: Audio.micIcon
            size: 20
            hoverable: false
            color: Audio.micMuted ? "#ff8a8a" : Theme.accent
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: Audio.micMuted ? Lang.t.micOff : Lang.t.micOn
            weight: Font.DemiBold
        }
    }
}
