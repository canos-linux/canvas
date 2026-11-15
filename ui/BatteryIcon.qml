import QtQuick
import "../core"
import "../services"

Rectangle {
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
        width: Math.max(2, (parent.width - 6) * Power.percent / 100)
        radius: 2
        color: Power.low ? "#ff6b6b" : Power.charging ? Theme.accent : Theme.text
        Behavior on width { NumberAnimation { duration: 500 } }
        SequentialAnimation on opacity {
            running: Power.charging
            loops: Animation.Infinite
            NumberAnimation { to: 0.4; duration: 900 }
            NumberAnimation { to: 1; duration: 900 }
        }
    }
}
