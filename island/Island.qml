import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../core"
import "../services"

PanelWindow {
    id: win
    property bool expanded: false
    property bool hovered: hover.hovered
    property string mode: expanded ? "center" : IslandState.temp !== "" ? IslandState.temp : Media.playing ? "music" : "idle"
    property var sizes: ({
        idle: [hovered ? 250 : 130, 38],
        music: [400, 50],
        volume: [310, 44],
        ws: [200, 38],
        notif: [370, 96],
        center: [500, Media.player ? 520 : 434]
    })

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 560
    exclusiveZone: 54
    color: "transparent"
    mask: Region { item: island }

    HyprlandFocusGrab {
        windows: [win]
        active: win.expanded
        onCleared: win.expanded = false
    }

    onExpandedChanged: {
        Sys.active = expanded
        if (expanded) Brightness.refresh()
    }

    component View: Item {
        id: view
        property bool on: false
        anchors.fill: parent
        opacity: on ? 1 : 0
        scale: on ? 1 : 0.9
        visible: opacity > 0
        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: view.on ? 140 : 0 }
                NumberAnimation { duration: 220 }
            }
        }
        Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }
    }

    Rectangle {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        y: 8
        width: win.sizes[win.mode][0]
        height: win.sizes[win.mode][1]
        radius: win.mode === "center" ? 32 : height / 2
        color: Theme.base
        border.width: 1
        border.color: Theme.alpha(Theme.accent, win.mode === "idle" && !win.hovered ? 0.3 : 0.75)
        clip: true

        Behavior on width { NumberAnimation { duration: 560; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
        Behavior on height { NumberAnimation { duration: 560; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
        Behavior on radius { NumberAnimation { duration: 400 } }
        Behavior on border.color { ColorAnimation { duration: 300 } }

        HoverHandler { id: hover }
        TapHandler {
            enabled: !win.expanded
            onTapped: win.expanded = true
        }

        View { on: win.mode === "idle"; IdleView { anchors.fill: parent; hovered: win.hovered } }
        View { on: win.mode === "music"; MusicView { anchors.fill: parent } }
        View { on: win.mode === "volume"; VolumeView { anchors.fill: parent } }
        View { on: win.mode === "ws"; WsView { anchors.fill: parent } }
        View { on: win.mode === "notif"; NotifView { anchors.fill: parent } }
        View { on: win.mode === "center"; CenterView { anchors.fill: parent; win: win } }
    }
}
