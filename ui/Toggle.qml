import QtQuick
import "../core"
import "../services"

Rectangle {
    id: toggle
    property bool checked: false
    signal toggled(bool value)
    width: 50
    height: 28
    radius: 14
    color: checked ? Theme.accent : Theme.surfaceHigh
    Behavior on color { ColorAnimation { duration: Theme.dur(200) } }

    Rectangle {
        width: 22
        height: 22
        radius: 11
        y: 3
        x: toggle.checked ? toggle.width - width - 3 : 3
        color: toggle.checked ? Theme.base : Theme.subtext
        scale: area.pressed ? 0.85 : 1
        Behavior on x { NumberAnimation { duration: Theme.dur(260); easing.type: Easing.OutBack } }
        Behavior on scale { NumberAnimation { duration: Theme.dur(120) } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        onClicked: { Sounds.play("click"); toggle.toggled(!toggle.checked) }
    }
}
