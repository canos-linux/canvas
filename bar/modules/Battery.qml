import QtQuick
import Quickshell.Services.UPower
import "../../core"

Row {
    id: bat
    spacing: 7

    property real raw: UPower.displayDevice.percentage
    property int percent: Math.round(raw > 1 ? raw : raw * 100)
    property bool charging: !UPower.onBattery
    property color fillColor: percent <= 15 && !charging ? "#ff6b6b" : charging ? Theme.accent : Theme.text

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        height: 13
        radius: 4
        color: "transparent"
        border.width: 1.5
        border.color: Theme.subtext

        Rectangle {
            x: 3
            y: 3
            height: parent.height - 6
            width: Math.max(2, (parent.width - 6) * bat.percent / 100)
            radius: 2
            color: bat.fillColor
            Behavior on width { NumberAnimation { duration: 500 } }
            SequentialAnimation on opacity {
                running: bat.charging
                loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 900 }
                NumberAnimation { to: 1; duration: 900 }
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: bat.percent + "%"
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 14
        font.weight: Font.Medium
    }
}
