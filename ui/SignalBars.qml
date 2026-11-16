import QtQuick
import "../core"

Item {
    id: bars
    property int strength: 0
    property bool lit: false
    implicitWidth: 22
    implicitHeight: 18

    Repeater {
        model: 4
        Rectangle {
            id: bar
            required property int index
            x: index * 6
            width: 4
            height: 6 + index * 4
            anchors.bottom: parent.bottom
            radius: 2
            transformOrigin: Item.Bottom
            color: bars.strength > index * 25 ? (bars.lit ? Theme.accent : Theme.text) : Theme.alpha(Theme.subtext, 0.22)
            Behavior on color { ColorAnimation { duration: Theme.dur(300) } }
            scale: 0
            SequentialAnimation on scale {
                running: true
                PauseAnimation { duration: Theme.dur(60 + bar.index * 70) }
                NumberAnimation { to: 1; duration: Theme.dur(380); easing.type: Easing.OutBack; easing.overshoot: 2 }
            }
        }
    }
}
