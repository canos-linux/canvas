import QtQuick
import "../core"
import "../services"
import "../ui"

Item {
    id: cv
    property real fill: 0

    Connections {
        target: IslandState
        function onTempChanged() {
            if (IslandState.temp !== "charge") return
            cv.fill = 0
            grow.restart()
        }
    }

    NumberAnimation {
        id: grow
        target: cv
        property: "fill"
        to: Power.percent / 100
        duration: Theme.dur(1100)
        easing.type: Easing.OutCubic
    }

    Row {
        anchors.centerIn: parent
        spacing: 12

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 20
            Rectangle {
                id: shell
                width: 36
                height: 20
                radius: 6
                color: "transparent"
                border.width: 2
                border.color: Theme.accent
                Rectangle {
                    x: 3
                    y: 3
                    height: parent.height - 6
                    width: Math.max(3, (parent.width - 6) * cv.fill)
                    radius: 3
                    color: Theme.accent
                    SequentialAnimation on opacity {
                        running: IslandState.temp === "charge"
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.55; duration: 700 }
                        NumberAnimation { to: 1; duration: 700 }
                    }
                }
            }
            Rectangle {
                anchors.left: shell.right
                anchors.leftMargin: 1
                anchors.verticalCenter: shell.verticalCenter
                width: 3
                height: 8
                radius: 1.5
                color: Theme.accent
            }
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: "󱐋 " + Power.percent + "%"
            weight: Font.Bold
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: Lang.t.charging
            color: Theme.subtext
        }
    }
}
