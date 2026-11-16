import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../core"
import "../services"
import "../ui"

FocusScope {
    id: bv
    property var win
    property bool active: false

    Binding {
        target: IslandState
        property: "panelHeight"
        value: Math.min(600, body.implicitHeight + 40)
        when: bv.active
    }

    onActiveChanged: {
        Bt.scan(active)
        if (active) focusTimer.restart()
    }

    Connections {
        target: Bt
        function onPoweredChanged() { if (bv.active && Bt.powered) Bt.scan(true) }
        function onPromptChanged() { if (Bt.prompt === "pin" || Bt.prompt === "passkey") pinFocus.restart() }
    }

    Timer { id: focusTimer; interval: 60; onTriggered: keys.forceActiveFocus() }
    Timer { id: pinFocus; interval: 120; onTriggered: pin.focusInput() }

    function back() {
        IslandState.overlay = ""
        if (win) win.setExpanded(true)
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key !== Qt.Key_Escape) return
            IslandState.overlay = ""
            event.accepted = true
        }
    }

    ScriptModel {
        id: mine
        values: Bt.devices.filter(d => d.paired).sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    }

    ScriptModel {
        id: nearby
        values: Bt.devices.filter(d => !d.paired && Bt.named(d))
    }

    component DeviceRow: Rectangle {
        id: row
        required property var modelData
        readonly property var d: modelData
        readonly property bool busy: d.pairing || d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting
        width: parent ? parent.width : 0
        height: 58
        radius: 20
        color: d.connected ? Theme.alpha(Theme.accent, hov.hovered ? 0.26 : 0.18) : hov.hovered ? Theme.surfaceHigh : Theme.card
        scale: tap.pressed ? 0.97 : 1
        Behavior on color { ColorAnimation { duration: Theme.dur(200) } }
        Behavior on scale { NumberAnimation { duration: Theme.dur(160); easing.type: Easing.OutBack } }

        HoverHandler { id: hov }
        TapHandler {
            id: tap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: if (!row.busy) Bt.activate(row.d)
        }

        Rectangle {
            id: bubble
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36
            radius: 18
            color: row.d.connected ? Theme.accent : Theme.surfaceHigh
            Behavior on color { ColorAnimation { duration: Theme.dur(250) } }
            Icon {
                anchors.centerIn: parent
                text: Bt.glyph(row.d)
                size: 18
                hoverable: false
                color: row.d.connected ? Theme.base : Theme.text
            }
        }

        Column {
            anchors.left: bubble.right
            anchors.leftMargin: 12
            anchors.right: side.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            Txt {
                width: parent.width
                text: row.d.name
                weight: row.d.connected ? Font.Bold : Font.DemiBold
                elide: Text.ElideRight
            }
            Txt {
                width: parent.width
                size: 12
                elide: Text.ElideRight
                color: row.d.connected ? Theme.accent : Theme.subtext
                text: row.d.pairing ? Lang.t.btPairing
                    : row.d.state === BluetoothDeviceState.Connecting ? Lang.t.wifiConnecting
                    : row.d.connected ? Lang.t.wifiConnected
                    : row.d.paired ? Lang.t.btPaired : Lang.t.btPair
            }
        }

        Row {
            id: side
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            Spinner { visible: row.busy; anchors.verticalCenter: parent.verticalCenter; size: 18 }
            Row {
                visible: row.d.batteryAvailable && row.d.connected
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 12
                    radius: 4
                    color: "transparent"
                    border.width: 1.5
                    border.color: Theme.subtext
                    Rectangle {
                        x: 2.5
                        y: 2.5
                        height: parent.height - 5
                        width: Math.max(2, (parent.width - 5) * row.d.battery)
                        radius: 2
                        color: row.d.battery < 0.2 ? "#ff8a8a" : Theme.accent
                        Behavior on width { NumberAnimation { duration: Theme.dur(600); easing.type: Easing.OutCubic } }
                    }
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(row.d.battery * 100) + "%"
                    size: 12
                    color: Theme.subtext
                }
            }
            Icon {
                visible: row.d.paired && hov.hovered && !row.busy
                anchors.verticalCenter: parent.verticalCenter
                text: "󰆴"
                size: 17
                color: Theme.subtext
                onClicked: row.d.forget()
            }
        }
    }

    Column {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        spacing: 14

        Item {
            width: parent.width
            height: 34
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Icon { anchors.verticalCenter: parent.verticalCenter; text: "󰁍"; size: 20; onClicked: bv.back() }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: "Bluetooth"; size: 17; weight: Font.Bold }
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14
                Icon {
                    id: radar
                    visible: Bt.powered
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰑐"
                    size: 19
                    color: Bt.discovering ? Theme.accent : Theme.subtext
                    onClicked: Bt.scan(!Bt.discovering)
                    RotationAnimator on rotation {
                        running: Bt.discovering
                        from: 0
                        to: 360
                        duration: 1400
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) radar.rotation = 0
                    }
                }
                Toggle {
                    visible: Bt.available
                    anchors.verticalCenter: parent.verticalCenter
                    checked: Bt.powered
                    onToggled: value => Bt.setPowered(value)
                }
            }
        }

        // pairing prompt
        Rectangle {
            visible: Bt.prompt !== ""
            width: parent.width
            height: promptCol.implicitHeight + 28
            radius: 22
            color: Theme.alpha(Theme.accent, 0.14)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.6)

            Column {
                id: promptCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 16
                spacing: 10
                Txt {
                    text: Bt.prompt === "confirm" ? Lang.t.btConfirmCode
                        : Bt.prompt === "display" ? Lang.t.btTypeCode
                        : Bt.prompt === "authorize" ? Lang.t.btAuthorize
                        : Lang.t.btEnterPin
                    weight: Font.DemiBold
                }
                Txt {
                    visible: Bt.promptCode !== ""
                    text: Bt.promptCode.split("").join(" ")
                    size: 30
                    weight: Font.Bold
                    color: Theme.accent
                }
                Field {
                    id: pin
                    visible: Bt.prompt === "pin" || Bt.prompt === "passkey"
                    width: parent.width
                    placeholder: "PIN"
                    onAccepted: Bt.answer(text)
                }
                Row {
                    spacing: 8
                    Pill {
                        visible: Bt.prompt !== "display"
                        primary: true
                        text: Bt.prompt === "pin" || Bt.prompt === "passkey" ? Lang.t.wifiConnect : Lang.t.btAccept
                        onClicked: Bt.answer(Bt.prompt === "pin" || Bt.prompt === "passkey" ? pin.text : "yes")
                    }
                    Pill {
                        text: Lang.t.btDecline
                        onClicked: Bt.answer("no")
                    }
                }
            }
        }

        Column {
            visible: !Bt.available || !Bt.powered
            width: parent.width
            spacing: 8
            topPadding: 18
            bottomPadding: 18
            Icon { anchors.horizontalCenter: parent.horizontalCenter; text: "󰂲"; size: 40; hoverable: false; color: Theme.subtext }
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: !Bt.available ? Lang.t.btNoAdapter : Lang.t.btOffHint
                color: Theme.subtext
            }
        }

        Flickable {
            visible: Bt.powered
            width: parent.width
            height: Math.min(lists.implicitHeight, 380)
            contentHeight: lists.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: lists
                width: parent.width
                spacing: 8

                Txt { visible: mine.values.length > 0; text: Lang.t.btMine; size: 13; weight: Font.DemiBold; color: Theme.subtext }
                Repeater { model: mine; DeviceRow {} }

                Item { visible: mine.values.length > 0; width: 1; height: 4 }
                Row {
                    spacing: 8
                    Txt { text: Lang.t.btNearby; size: 13; weight: Font.DemiBold; color: Theme.subtext }
                    Spinner { visible: Bt.discovering; size: 13; anchors.verticalCenter: parent.verticalCenter }
                }
                Repeater { model: nearby; DeviceRow {} }
                Txt {
                    visible: nearby.values.length === 0
                    text: Bt.discovering ? Lang.t.btScanning : Lang.t.btNone
                    size: 13
                    color: Theme.subtext
                    topPadding: 4
                    bottomPadding: 4
                }
            }
        }
    }
}
