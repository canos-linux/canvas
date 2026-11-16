import QtQuick
import Quickshell
import "../core"
import "../services"
import "../ui"

FocusScope {
    id: wv
    property var win
    property bool active: false
    property string open: ""
    property bool hidden: false
    property bool qr: false

    Binding {
        target: IslandState
        property: "panelHeight"
        value: Math.min(600, body.implicitHeight + 40)
        when: wv.active
    }

    onActiveChanged: {
        Net.listening = active
        if (active) {
            sync()
            open = ""
            hidden = false
            qr = false
            Net.error = ""
            Net.errorFor = ""
            Net.scan(true)
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: keys.forceActiveFocus()
    }

    ListModel { id: netModel }

    // update the model in place so rows keep their state (password field, animations)
    function sync() {
        const src = Net.networks
        for (let i = netModel.count - 1; i >= 0; i--)
            if (!src.some(n => n.ssid === netModel.get(i).ssid)) netModel.remove(i)
        for (let i = 0; i < src.length; i++) {
            let j = -1
            for (let k = i; k < netModel.count; k++)
                if (netModel.get(k).ssid === src[i].ssid) { j = k; break }
            if (j === -1) netModel.insert(i, src[i])
            else {
                if (j !== i) netModel.move(j, i, 1)
                netModel.set(i, src[i])
            }
        }
    }

    Connections {
        target: Net
        function onNetworksChanged() { wv.sync() }
        function onBusyChanged() {
            if (Net.busy === "" && Net.error === "") wv.open = ""
        }
    }

    function back() {
        IslandState.overlay = ""
        if (win) win.setExpanded(true)
    }

    function tap(n) {
        if (Net.busy !== "") return
        if (n.active || (!n.saved && n.secure) || (n.saved && Net.errorFor === n.ssid)) {
            open = open === n.ssid ? "" : n.ssid
        } else {
            open = ""
            Net.connect(n.ssid, "", false)
        }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key !== Qt.Key_Escape) return
            if (wv.qr) wv.qr = false
            else if (wv.open !== "" || wv.hidden) { wv.open = ""; wv.hidden = false; keys.forceActiveFocus() }
            else IslandState.overlay = ""
            event.accepted = true
        }
    }

    Column {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        spacing: 14

        // header
        Item {
            width: parent.width
            height: 34

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰁍"
                    size: 20
                    onClicked: wv.qr ? wv.qr = false : wv.back()
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: wv.qr ? Lang.t.wifiShare : Lang.t.wifi
                    size: 17
                    weight: Font.Bold
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14
                visible: !wv.qr
                Icon {
                    id: rescan
                    visible: Net.enabled
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰑐"
                    size: 19
                    color: Net.scanning ? Theme.accent : Theme.subtext
                    onClicked: Net.scan(true)
                    RotationAnimator on rotation {
                        running: Net.scanning
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) rescan.rotation = 0
                    }
                }
                Toggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: Net.enabled
                    onToggled: value => Net.setEnabled(value)
                }
            }
        }

        // QR share
        Column {
            visible: wv.qr
            width: parent.width
            spacing: 12

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 220
                height: 220
                radius: 24
                color: "white"
                scale: wv.qr ? 1 : 0.6
                Behavior on scale { NumberAnimation { duration: Theme.dur(500); easing.type: Easing.OutBack } }
                Image {
                    anchors.fill: parent
                    anchors.margins: 14
                    source: Net.qrPath
                    smooth: false
                    fillMode: Image.PreserveAspectFit
                }
                Spinner {
                    anchors.centerIn: parent
                    visible: Net.qrLoading
                    size: 28
                }
                Txt {
                    anchors.centerIn: parent
                    visible: !Net.qrLoading && Net.qrPath === ""
                    text: Lang.t.wifiNoQr
                    width: 180
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: "#555"
                }
            }
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Net.qrSsid
                size: 16
                weight: Font.DemiBold
            }
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: Net.qrPassword !== ""
                text: Lang.t.wifiPassword + ": " + Net.qrPassword
                size: 13
                color: Theme.subtext
            }
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Lang.t.wifiScanQr
                size: 12
                color: Theme.subtext
            }
        }

        // off / empty
        Column {
            visible: !wv.qr && (!Net.enabled || Net.networks.length === 0)
            width: parent.width
            spacing: 8
            topPadding: 18
            bottomPadding: 18
            Icon {
                id: emptyIcon
                anchors.horizontalCenter: parent.horizontalCenter
                text: !Net.enabled ? "󰤭" : "󰤯"
                size: 40
                hoverable: false
                color: Theme.subtext
                SequentialAnimation on opacity {
                    running: Net.hasDevice && Net.enabled && Net.scanning
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) emptyIcon.opacity = 1
                    NumberAnimation { to: 0.3; duration: 600 }
                    NumberAnimation { to: 1; duration: 600 }
                }
            }
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: !Net.hasDevice ? Lang.t.wifiNoDevice : !Net.enabled ? Lang.t.wifiOffHint : Net.scanning ? Lang.t.wifiScanning : Lang.t.wifiNone
                color: Theme.subtext
            }
        }

        // networks
        ListView {
            id: list
            visible: !wv.qr && Net.networks.length > 0
            width: parent.width
            height: Math.min(contentHeight, 360)
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            model: netModel

            add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.dur(250) } }
            displaced: Transition { NumberAnimation { property: "y"; duration: Theme.dur(300); easing.type: Easing.OutCubic } }

            delegate: Rectangle {
                id: row
                required property int index
                required property string ssid
                required property int level
                required property bool secure
                required property string band
                required property bool active
                required property bool saved
                readonly property var n: ({ ssid: ssid, level: level, secure: secure, band: band, active: active, saved: saved })
                readonly property bool expanded: wv.open === n.ssid
                readonly property bool connecting: Net.busy === n.ssid
                width: list.width
                height: 56 + (expanded ? extra.implicitHeight + 12 : 0)
                radius: 20
                color: n.active ? Theme.alpha(Theme.accent, rowHov.hovered ? 0.26 : 0.18) : rowHov.hovered || expanded ? Theme.surfaceHigh : Theme.card
                clip: true
                Behavior on height { NumberAnimation { duration: Theme.dur(380); easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                Behavior on color { ColorAnimation { duration: Theme.dur(200) } }

                HoverHandler { id: rowHov }

                Item {
                    id: head
                    width: parent.width
                    height: 56

                    TapHandler {
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: {
                            wv.tap(row.n)
                            if (wv.open === row.n.ssid && !row.n.active) focusLater.restart()
                        }
                    }

                    SignalBars {
                        id: sig
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        strength: row.n.level
                        lit: row.n.active
                    }

                    Column {
                        anchors.left: sig.right
                        anchors.leftMargin: 14
                        anchors.right: right.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        Txt {
                            width: parent.width
                            text: row.n.ssid
                            weight: row.n.active ? Font.Bold : Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Txt {
                            width: parent.width
                            size: 12
                            color: row.n.active ? Theme.accent : Theme.subtext
                            elide: Text.ElideRight
                            text: (row.connecting ? Lang.t.wifiConnecting
                                : row.n.active ? Lang.t.wifiConnected
                                : row.n.saved ? Lang.t.wifiSaved
                                : row.n.secure ? Lang.t.wifiSecured : Lang.t.wifiOpen) + "  ·  " + row.n.band
                        }
                    }

                    Row {
                        id: right
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        Spinner {
                            visible: row.connecting
                            anchors.verticalCenter: parent.verticalCenter
                            size: 18
                        }
                        Icon {
                            visible: row.n.saved && !row.n.active && rowHov.hovered && !row.connecting
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰆴"
                            size: 17
                            color: Theme.subtext
                            onClicked: Net.forget(row.n.ssid)
                        }
                        Icon {
                            visible: row.n.secure
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰌾"
                            size: 15
                            hoverable: false
                            color: Theme.subtext
                        }
                    }
                }

                Timer {
                    id: focusLater
                    interval: 120
                    onTriggered: if (pw.visible) pw.focusInput()
                }

                Column {
                    id: extra
                    anchors.top: head.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 8
                    opacity: row.expanded ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(200) } }

                    Row {
                        visible: row.n.active
                        spacing: 8
                        Pill { icon: "󰖪"; text: Lang.t.wifiDisconnect; onClicked: { wv.open = ""; Net.disconnect(row.n.ssid) } }
                        Pill { icon: "󰐲"; text: Lang.t.wifiShare; onClicked: { wv.qr = true; Net.share(row.n.ssid) } }
                        Pill { icon: "󰆴"; text: Lang.t.wifiForget; onClicked: { wv.open = ""; Net.forget(row.n.ssid) } }
                    }

                    Row {
                        visible: !row.n.active
                        width: parent.width
                        spacing: 8
                        Field {
                            id: pw
                            width: parent.width - go.width - 8
                            password: true
                            placeholder: Lang.t.wifiPassword
                            onAccepted: if (text !== "") Net.connect(row.n.ssid, text, false)
                        }
                        Pill {
                            id: go
                            primary: true
                            height: 38
                            text: Lang.t.wifiConnect
                            onClicked: if (pw.text !== "") Net.connect(row.n.ssid, pw.text, false)
                        }
                    }

                    Txt {
                        visible: Net.errorFor === row.n.ssid && Net.error !== ""
                        text: "󰅚  " + Net.error
                        size: 12
                        color: "#ff8a8a"
                    }
                }
            }
        }

        // hidden network
        Column {
            visible: !wv.qr && wv.hidden && Net.enabled
            width: parent.width
            spacing: 8
            Field {
                id: hName
                width: parent.width
                placeholder: Lang.t.wifiName
                onAccepted: hPw.focusInput()
            }
            Row {
                width: parent.width
                spacing: 8
                Field {
                    id: hPw
                    width: parent.width - hGo.width - 8
                    password: true
                    placeholder: Lang.t.wifiPassword + " (" + Lang.t.optional + ")"
                    onAccepted: hGo.clicked()
                }
                Pill {
                    id: hGo
                    primary: true
                    height: 38
                    text: Lang.t.wifiConnect
                    onClicked: if (hName.text !== "") { Net.connect(hName.text, hPw.text, true); wv.hidden = false }
                }
            }
            Txt {
                visible: Net.errorFor === hName.text && Net.error !== ""
                text: "󰅚  " + Net.error
                size: 12
                color: "#ff8a8a"
            }
        }

        // footer
        Row {
            visible: !wv.qr && Net.hasDevice
            spacing: 8
            Pill {
                visible: Net.enabled
                icon: "󰛓"
                text: Lang.t.wifiHidden
                active: wv.hidden
                onClicked: {
                    wv.hidden = !wv.hidden
                    wv.open = ""
                    if (wv.hidden) hFocus.restart()
                }
            }
            Pill {
                icon: "󰀂"
                text: Lang.t.wifiHotspot
                active: Net.hotspot
                onClicked: Net.toggleHotspot()
            }
            Pill {
                visible: Net.hotspot
                icon: "󰐲"
                onClicked: { wv.qr = true; Net.share("Hotspot") }
            }
            Pill {
                icon: "󰒓"
                onClicked: { IslandState.overlay = ""; Net.openSettings() }
            }
        }

        Timer {
            id: hFocus
            interval: 120
            onTriggered: hName.focusInput()
        }
    }
}
