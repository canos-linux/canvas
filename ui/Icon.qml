import QtQuick
import "../core"

Text {
    id: icon
    property int size: 19
    property bool hoverable: true
    signal clicked()
    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: size
    scale: area.pressed ? 0.85 : hoverable && area.containsMouse ? 1.2 : 1
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
    Behavior on color { ColorAnimation { duration: 250 } }
    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -4
        enabled: icon.hoverable
        hoverEnabled: true
        onClicked: icon.clicked()
    }
}
