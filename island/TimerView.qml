import QtQuick
import "../core"
import "../ui"

Item {
    readonly property int rest: IslandState.timerLeft

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
            text: (rest >= 3600 ? Math.floor(rest / 3600) + ":" + String(Math.floor(rest % 3600 / 60)).padStart(2, "0") : Math.floor(rest / 60)) + ":" + String(rest % 60).padStart(2, "0")
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
