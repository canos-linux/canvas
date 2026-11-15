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
    implicitHeight: Config.barStyle === "classic" ? 46 : 56
    color: "transparent"

    Rectangle {
        visible: !bar.islands
        anchors.fill: parent
        anchors.topMargin: bar.floating ? 6 : 0
        anchors.leftMargin: bar.floating ? 10 : 0
        anchors.rightMargin: bar.floating ? 10 : 0
        radius: bar.floating ? 20 : 0
        color: Theme.base
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: bar.islands || bar.floating ? 6 : 0
        anchors.leftMargin: 14
        anchors.rightMargin: 14

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Repeater {
                model: Config.left
                Island {
                    modules: modelData
                    barWindow: bar
                    solid: bar.islands
                    delay: index * 100
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Repeater {
                model: Config.center
                Island {
                    modules: modelData
                    barWindow: bar
                    solid: bar.islands
                    delay: 200 + index * 100
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Repeater {
                model: Config.right
                Island {
                    modules: modelData
                    barWindow: bar
                    solid: bar.islands
                    delay: 300 + index * 100
                }
            }
        }
    }
}
