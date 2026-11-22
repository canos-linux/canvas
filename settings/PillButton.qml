import QtQuick
import "../core"
import "../services"
import "../ui"

Rectangle {
    id: btn
    property string text: ""
    property bool primary: false
    property bool busy: false
    signal clicked()
    width: Math.max(110, label.implicitWidth + 32)
    height: 34
    radius: 17
    opacity: enabled ? 1 : 0.4
    color: primary || area.containsMouse ? Theme.accent : Theme.surfaceHigh
    Behavior on color { ColorAnimation { duration: Theme.dur(150) } }
    scale: area.pressed ? 0.95 : 1
    Behavior on scale { NumberAnimation { duration: Theme.dur(150) } }

    Txt {
        id: label
        anchors.centerIn: parent
        visible: !btn.busy
        text: btn.text
        weight: Font.Medium
        color: btn.primary || area.containsMouse ? Theme.base : Theme.text
    }
    Spinner {
        anchors.centerIn: parent
        visible: btn.busy
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: !btn.busy
        onClicked: { Sounds.play("click"); btn.clicked() }
    }
}
