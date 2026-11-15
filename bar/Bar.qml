import Quickshell
import QtQuick
import "../core"

PanelWindow {
    id: bar
    property bool islands: Config.barStyle === "islands"
    property bool floating: Config.barStyle === "floating"

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Config.barStyle === "classic" ? 40 : 48
    color: "transparent"

    Rectangle {
        visible: !bar.islands
        anchors.fill: parent
        anchors.topMargin: bar.floating ? 6 : 0
        anchors.leftMargin: bar.floating ? 10 : 0
        anchors.rightMargin: bar.floating ? 10 : 0
        radius: bar.floating ? 17 : 0
        color: Theme.base
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: bar.islands || bar.floating ? 6 : 0
        anchors.leftMargin: 14
        anchors.rightMargin: 14

        Island {
            solid: bar.islands
            delay: 0
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            Workspaces {}
        }

        Island {
            solid: bar.islands
            delay: 120
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            Clock {}
        }

        Island {
            solid: bar.islands
            delay: 240
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            Battery {}
        }
    }
}
