import Quickshell
import Quickshell.Wayland
import QtQuick
import "../core"
import "../services"

PanelWindow {
    id: catcher
    property bool focusedScreen: Hypr.focusedMonitor === "" || screen.name === Hypr.focusedMonitor
    property bool active: IslandState.expandedScreen === screen.name || (focusedScreen && IslandState.overlay !== "")

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "canvas-catcher"
    property Region fullRegion: Region { item: full }
    property Region emptyRegion: Region {}
    mask: active ? fullRegion : emptyRegion

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Rectangle {
        id: full
        anchors.fill: parent
        color: "black"
        opacity: catcher.active ? (IslandState.overlay !== "" ? 0.35 : 0.15) : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(250) } }

        MouseArea {
            anchors.fill: parent
            enabled: catcher.active
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: IslandState.closeAll()
        }
    }
}
