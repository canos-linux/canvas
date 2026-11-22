import QtQuick
import "../core"
import "../ui"

Item {
    readonly property int left: IslandState.timerLeft

    Row {
        anchors.centerIn: parent
        spacing: 10
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: "󱎫"
            size: 18
            color: Theme.accent
            hoverable: false
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: (left >= 3600 ? Math.floor(left / 3600) + ":" + String(Math.floor(left % 3600 / 60)).padStart(2, "0") : Math.floor(left / 60)) + ":" + String(left % 60).padStart(2, "0")
            size: 15
            weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰅖"
            size: 16
            color: Theme.subtext
            onClicked: IslandState.stopTimer()
        }
    }
}
