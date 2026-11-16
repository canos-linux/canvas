import QtQuick
import "../core"
import "../services"
import "../ui"

Item {
    id: pop

    Rectangle {
        id: bubble
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 46
        height: 46
        radius: 23
        color: Theme.accent
        Icon {
            anchors.centerIn: parent
            text: IslandState.btPopIcon
            size: 24
            hoverable: false
            color: Theme.base
        }
        SequentialAnimation on scale {
            running: IslandState.temp === "btdev"
            NumberAnimation { from: 0.4; to: 1.12; duration: Theme.dur(320); easing.type: Easing.OutCubic }
            NumberAnimation { to: 1; duration: Theme.dur(260); easing.type: Easing.OutBack }
        }
    }

    Column {
        anchors.left: bubble.right
        anchors.leftMargin: 14
        anchors.right: batt.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        Txt { width: parent.width; text: IslandState.btPopName; weight: Font.Bold; elide: Text.ElideRight }
        Txt { text: Lang.t.wifiConnected; size: 12; color: Theme.accent }
    }

    Row {
        id: batt
        visible: IslandState.btPopBattery >= 0
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            readonly property real b: IslandState.btPopBattery
            text: b > 0.9 ? "󰁹" : b > 0.65 ? "󰂀" : b > 0.4 ? "󰁾" : b > 0.15 ? "󰁼" : "󰁺"
            size: 20
            hoverable: false
            color: b < 0.2 ? "#ff8a8a" : Theme.accent
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(IslandState.btPopBattery * 100) + "%"
            weight: Font.DemiBold
        }
    }
}
