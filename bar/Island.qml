import QtQuick
import "../core"

Rectangle {
    id: island
    default property alias content: row.data
    property bool solid: true
    property int delay: 0

    implicitWidth: row.implicitWidth + 28
    implicitHeight: 34
    radius: height / 2
    color: solid ? Theme.base : "transparent"
    border.width: solid ? 1 : 0
    border.color: Theme.alpha(Theme.accent, hover.hovered ? 0.6 : 0.2)
    opacity: 0
    scale: hover.hovered ? 1.04 : 1

    transform: Translate { id: shift; y: -40 }

    Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    HoverHandler { id: hover }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 12
    }

    SequentialAnimation {
        running: true
        PauseAnimation { duration: island.delay }
        ParallelAnimation {
            NumberAnimation { target: island; property: "opacity"; to: 1; duration: 400 }
            NumberAnimation { target: shift; property: "y"; to: 0; duration: 700; easing.type: Easing.OutBack }
        }
    }
}
