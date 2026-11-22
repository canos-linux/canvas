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
            text: "󰊴"
            size: 20
            color: Gaming.active ? Theme.accent : Theme.subtext
            hoverable: false
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: Gaming.active ? Lang.t.gameOn : Lang.t.gameOff
            size: 14
            weight: Font.DemiBold
        }
    }
}
