import QtQuick
import Quickshell
import "../core"
import "../ui"

FocusScope {
    id: pv
    property bool active: false
    property int sel: 0
    readonly property var actions: [
        { icon: "󰌾", label: Lang.t.powerLock, id: "lock" },
        { icon: "󰍃", label: Lang.t.powerLogout, id: "logout" },
        { icon: "󰒲", label: Lang.t.powerSuspend, id: "suspend" },
        { icon: "󰜉", label: Lang.t.powerReboot, id: "reboot" },
        { icon: "󰐥", label: Lang.t.powerOff, id: "off" }
    ]

    onActiveChanged: {
        if (active) {
            sel = 0
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: keys.forceActiveFocus()
    }

    function run(i) {
        const a = actions[i].id
        IslandState.overlay = ""
        if (a === "lock") {
            IslandState.lock()
        } else if (a === "logout") {
            Quickshell.execDetached(["sh", "-c", "loginctl terminate-session \"$XDG_SESSION_ID\""])
        } else if (a === "suspend") {
            if (Config.lockOn) IslandState.lock()
            Quickshell.execDetached(["sh", "-c", "sleep 0.6; systemctl suspend"])
        } else if (a === "reboot") {
            Quickshell.execDetached(["systemctl", "reboot"])
        } else if (a === "off") {
            Quickshell.execDetached(["systemctl", "poweroff"])
        }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) IslandState.overlay = ""
            else if (event.key === Qt.Key_Left) pv.sel = (pv.sel + pv.actions.length - 1) % pv.actions.length
            else if (event.key === Qt.Key_Right) pv.sel = (pv.sel + 1) % pv.actions.length
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) pv.run(pv.sel)
            else return
            event.accepted = true
        }
    }

    Txt {
        anchors.top: parent.top
        anchors.topMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Power"
        size: 15
        weight: Font.Bold
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        spacing: 26
        Repeater {
            model: pv.actions
            RoundButton {
                required property var modelData
                required property int index
                icon: modelData.icon
                label: modelData.label
                active: pv.sel === index
                onClicked: pv.run(index)
            }
        }
    }
}
