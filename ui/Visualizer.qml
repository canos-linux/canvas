import QtQuick
import "../core"
import "../services"

Row {
    property real maxHeight: 20
    spacing: 3
    Repeater {
        model: 8
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 3 + Media.levels[index] / 100 * maxHeight
            radius: 1.5
            color: Theme.accent
            Behavior on height { NumberAnimation { duration: 80 } }
        }
    }
}
