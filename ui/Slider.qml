import QtQuick
import "../core"

Item {
    id: slider
    property real value: 0
    property real shown: value
    Behavior on shown { NumberAnimation { duration: drag.pressed ? 0 : 200 } }
    signal moved(real v)
    implicitHeight: 24

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: drag.containsMouse || drag.pressed ? 12 : 8
        radius: height / 2
        color: Theme.surfaceHigh
        Behavior on height { NumberAnimation { duration: 150 } }

        Rectangle {
            width: Math.max(parent.height, parent.width * slider.shown)
            height: parent.height
            radius: height / 2
            color: Theme.accent
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        hoverEnabled: true
        function update(x) { slider.moved(Math.max(0, Math.min(1, x / width))) }
        onPressed: mouse => update(mouse.x)
        onPositionChanged: mouse => { if (pressed) update(mouse.x) }
    }

    WheelHandler {
        onWheel: event => slider.moved(Math.max(0, Math.min(1, slider.value + (event.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
