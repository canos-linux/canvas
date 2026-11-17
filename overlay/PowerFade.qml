import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"
import "../services"
import "../ui"

// shutdown / restart / logout: everything fades into the theme color, the ring logo appears
PanelWindow {
    id: win
    readonly property bool on: IslandState.powerAction !== ""
    readonly property bool isMain: screen && screen.name === Displays.mainName
    visible: on || bg.opacity > 0
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "canvas-power"
    WlrLayershell.keyboardFocus: on ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Theme.base
        opacity: win.on ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: win.on ? 650 : 250; easing.type: Easing.InOutQuad } }
    }

    Column {
        anchors.centerIn: parent
        spacing: 26
        visible: win.isMain
        opacity: win.on ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        RingLogo {
            id: ring
            anchors.horizontalCenter: parent.horizontalCenter
            width: 120
            height: 120
            tint: Theme.accent
            progress: 0
            NumberAnimation on progress {
                running: win.on
                from: 0
                to: 1
                duration: 1000
                easing.type: Easing.OutCubic
            }
        }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: IslandState.powerAction === "reboot" ? Lang.t.powerRebootAnim : IslandState.powerAction === "logout" ? Lang.t.powerLogoutAnim : Lang.t.powerOffAnim
            size: 18
            color: Theme.subtext
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: win.on
    }
}
