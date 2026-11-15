import QtQuick
import "../core"
import "modules"

Rectangle {
    id: island
    property var modules: []
    property var barWindow
    property bool solid: true
    property int delay: 0

    visible: row.implicitWidth > 0
    implicitWidth: row.implicitWidth + 32
    implicitHeight: 40
    radius: height / 2
    color: solid ? Theme.base : "transparent"
    border.width: solid ? 1 : 0
    border.color: Theme.alpha(Theme.accent, hover.hovered ? 0.6 : 0.2)
    opacity: 0
    scale: hover.hovered ? 1.03 : 1

    transform: Translate { id: shift; y: -50 }

    Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    HoverHandler { id: hover }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 16

        Repeater {
            model: island.modules
            Loader {
                anchors.verticalCenter: parent.verticalCenter
                source: Qt.resolvedUrl("modules/" + modelData.charAt(0).toUpperCase() + modelData.slice(1) + ".qml")
                visible: item !== null && (item.shown === undefined || item.shown)
                onLoaded: {
                    if (item.barWindow !== undefined)
                        item.barWindow = island.barWindow
                }
            }
        }
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
