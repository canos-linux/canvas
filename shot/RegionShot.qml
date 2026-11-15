import Quickshell
import Quickshell.Wayland
import QtQuick
import "../core"
import "../ui"

PanelWindow {
    id: shot
    property real ax: 0
    property real ay: 0
    property real bx: 0
    property real by: 0
    property bool dragging: false
    readonly property real sx: Math.min(ax, bx)
    readonly property real sy: Math.min(ay, by)
    readonly property real sw: Math.abs(ax - bx)
    readonly property real sh: Math.abs(ay - by)

    visible: IslandState.shooting
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "canvas-shot"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onVisibleChanged: {
        dragging = false
        ax = ay = bx = by = 0
        if (visible) focusTimer.restart()
    }

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: keys.forceActiveFocus()
    }

    function capture(full) {
        const g = full
            ? Math.round(screen.x) + "," + Math.round(screen.y) + " " + screen.width + "x" + screen.height
            : Math.round(screen.x + sx) + "," + Math.round(screen.y + sy) + " " + Math.round(sw) + "x" + Math.round(sh)
        IslandState.shooting = false
        Quickshell.execDetached(["sh", "-c", "sleep 0.25; d=\"$(xdg-user-dir PICTURES 2>/dev/null || echo \"$HOME/Pictures\")/Screenshots\"; mkdir -p \"$d\"; f=\"$d/$(date +%Y-%m-%d_%H-%M-%S).png\"; grim -g \"$1\" \"$f\" && wl-copy < \"$f\" && notify-send -i \"$f\" \"$2\" \"$3\"", "sh", g, Lang.t.shotTitle, Lang.t.shotBody])
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: IslandState.shooting = false
    }

    Rectangle {
        anchors.fill: parent
        visible: !shot.dragging
        color: Qt.rgba(0, 0, 0, 0.35)
    }

    Item {
        anchors.fill: parent
        visible: shot.dragging
        Rectangle { x: 0; y: 0; width: parent.width; height: shot.sy; color: Qt.rgba(0, 0, 0, 0.45) }
        Rectangle { x: 0; y: shot.sy + shot.sh; width: parent.width; height: parent.height - shot.sy - shot.sh; color: Qt.rgba(0, 0, 0, 0.45) }
        Rectangle { x: 0; y: shot.sy; width: shot.sx; height: shot.sh; color: Qt.rgba(0, 0, 0, 0.45) }
        Rectangle { x: shot.sx + shot.sw; y: shot.sy; width: parent.width - shot.sx - shot.sw; height: shot.sh; color: Qt.rgba(0, 0, 0, 0.45) }

        Rectangle {
            x: shot.sx - 1
            y: shot.sy - 1
            width: shot.sw + 2
            height: shot.sh + 2
            color: "transparent"
            radius: 4
            border.width: 2
            border.color: Theme.accent
        }

        Rectangle {
            x: Math.min(shot.sx, parent.width - width - 8)
            y: shot.sy + shot.sh + 8 + height > parent.height ? shot.sy - height - 8 : shot.sy + shot.sh + 8
            width: sizeTxt.implicitWidth + 20
            height: 26
            radius: 13
            color: Theme.accent
            Txt {
                id: sizeTxt
                anchors.centerIn: parent
                text: Math.round(shot.sw) + " × " + Math.round(shot.sh)
                size: 12
                weight: Font.DemiBold
                color: Theme.base
            }
        }
    }

    Rectangle {
        visible: !shot.dragging
        anchors.horizontalCenter: parent.horizontalCenter
        y: 24
        width: hint.implicitWidth + 36
        height: 40
        radius: 20
        color: Theme.panel
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.75)
        Txt {
            id: hint
            anchors.centerIn: parent
            text: "󰹑   " + Lang.t.shotHint
            size: 13
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                IslandState.shooting = false
                return
            }
            shot.ax = shot.bx = mouse.x
            shot.ay = shot.by = mouse.y
            shot.dragging = true
        }
        onPositionChanged: mouse => {
            if (!shot.dragging) return
            shot.bx = mouse.x
            shot.by = mouse.y
        }
        onReleased: mouse => {
            if (!shot.dragging) return
            shot.dragging = false
            shot.capture(shot.sw < 6 || shot.sh < 6)
        }
    }
}
