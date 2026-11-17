import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"
import "../services"
import "../ui"

// big display number on every screen (Settings › Displays › Identify)
PanelWindow {
    id: win
    visible: Displays.identifying || card.opacity > 0
    anchors {
        top: true
        left: true
    }
    margins.top: 40
    margins.left: 40
    implicitWidth: 220
    implicitHeight: 220
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "canvas-identify"
    color: "transparent"

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 36
        color: Theme.base
        border.width: 3
        border.color: Theme.accent
        opacity: Displays.identifying ? 1 : 0
        scale: Displays.identifying ? 1 : 0.85
        Behavior on opacity { NumberAnimation { duration: Theme.dur(220) } }
        Behavior on scale { NumberAnimation { duration: Theme.dur(260); easing.type: Easing.OutBack } }
        Column {
            anchors.centerIn: parent
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Displays.numberOf(win.screen ? win.screen.name : "")
                size: 120
                weight: Font.Bold
                color: Theme.accent
            }
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: (win.screen ? win.screen.name : "") + (win.screen && win.screen.name === Displays.mainName ? " ★" : "")
                size: 14
                color: Theme.subtext
            }
        }
    }
}
