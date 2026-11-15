import QtQuick
import "../../core"

Row {
    id: pill
    property string icon: ""
    property string label: ""
    property bool alwaysLabel: false
    property bool peek: false
    property bool reveal: (alwaysLabel || hov.hovered || peek) && label !== ""
    property color iconColor: Theme.text
    property alias iconItem: iconText

    spacing: reveal ? 7 : 0
    Behavior on spacing { NumberAnimation { duration: 250 } }

    function flash() {
        peek = true
        peekTimer.restart()
    }

    HoverHandler { id: hov }

    Timer {
        id: peekTimer
        interval: 1500
        onTriggered: pill.peek = false
    }

    Text {
        id: iconText
        anchors.verticalCenter: parent.verticalCenter
        text: pill.icon
        color: pill.iconColor
        font.family: Theme.iconFont
        font.pixelSize: 19
        scale: hov.hovered ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: 250 } }
    }

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: pill.reveal ? labelText.implicitWidth : 0
        height: labelText.implicitHeight
        clip: true
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        Text {
            id: labelText
            text: pill.label
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 14
            font.weight: Font.Medium
        }
    }
}
