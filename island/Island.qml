import Quickshell
import Quickshell.Wayland
import QtQuick
import "../core"
import "../services"

PanelWindow {
    id: win
    property bool expanded: IslandState.expandedScreen === screen.name
    property bool hovered: hover.hovered
    property bool focusedScreen: Hypr.focusedMonitor === "" || screen.name === Hypr.focusedMonitor
    property string overlay: focusedScreen ? IslandState.overlay : ""
    property string mode: overlay !== "" ? overlay : expanded ? "center" : IslandState.temp !== "" ? IslandState.temp : Media.recent && Media.player ? "music" : "idle"
    property var sizes: ({
        idle: [hovered && Config.opt.hoverDate ? 250 : 130, 38],
        music: [400, 50],
        volume: [310, 44],
        brightness: [310, 44],
        ws: [200, 38],
        notif: [370, 96],
        center: [500, IslandState.centerHeight],
        launcher: [620, 66 + IslandState.launcherRows * 54 + (IslandState.launcherRows > 0 ? 14 : 0)],
        themes: [960, 420],
        power: [480, 150]
    })

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 640
    exclusiveZone: 54
    color: "transparent"
    mask: Region { item: island }
    WlrLayershell.namespace: "canvas"
    WlrLayershell.keyboardFocus: overlay !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function setExpanded(v) {
        IslandState.expandedScreen = v ? screen.name : ""
    }

    onOverlayChanged: if (overlay !== "") setExpanded(false)
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
                PauseAnimation { duration: view.on ? Theme.dur(140) : 0 }
                NumberAnimation { duration: Theme.dur(220) }
            }
        }
        Behavior on scale { NumberAnimation { duration: Theme.dur(420); easing.type: Easing.OutBack } }
    }

    Rectangle {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        y: 8
        width: win.sizes[win.mode][0]
        height: win.sizes[win.mode][1]
        radius: win.mode === "center" || win.mode === "themes" || win.mode === "power" ? 32 : win.mode === "launcher" ? 28 : height / 2
        color: Theme.panel
        border.width: 1
        border.color: Theme.alpha(Theme.accent, win.mode === "idle" && !win.hovered ? 0.3 : 0.75)
        clip: true

        Behavior on width { NumberAnimation { duration: Theme.dur(560); easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
        Behavior on height { NumberAnimation { duration: Theme.dur(560); easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
        Behavior on radius { NumberAnimation { duration: Theme.dur(400) } }
        Behavior on border.color { ColorAnimation { duration: 300 } }
        Behavior on color { ColorAnimation { duration: 300 } }

        HoverHandler { id: hover }
        MouseArea {
            anchors.fill: parent
            enabled: !win.expanded && win.overlay === ""
            onClicked: win.setExpanded(true)
        }

        View { on: win.mode === "idle"; IdleView { anchors.fill: parent; hovered: win.hovered && Config.opt.hoverDate } }
        View { on: win.mode === "music"; MusicView { anchors.fill: parent } }
        View { on: win.mode === "volume"; VolumeView { anchors.fill: parent } }
        View { on: win.mode === "brightness"; BrightnessView { anchors.fill: parent } }
        View { on: win.mode === "ws"; WsView { anchors.fill: parent } }
        View { on: win.mode === "notif"; NotifView { anchors.fill: parent } }
        View { on: win.mode === "center"; CenterView { anchors.fill: parent; win: win } }
        View { on: win.mode === "launcher"; LauncherView { anchors.fill: parent; active: win.mode === "launcher" } }
        View { on: win.mode === "themes"; ThemesView { anchors.fill: parent; active: win.mode === "themes" } }
        View { on: win.mode === "power"; PowerView { anchors.fill: parent; active: win.mode === "power" } }
    }
}
