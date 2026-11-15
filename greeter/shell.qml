//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import QtQuick

ShellRoot {
    id: root
    property bool de: false
    property var users: []
    property int index: 0
    readonly property var user: users.length > 0 ? users[index] : null
    property string status: ""
    readonly property string themeDir: Quickshell.shellDir + "/../themes/canvas"
    readonly property color base: "#0d0b14"
    readonly property color surface: "#1d1a26"
    readonly property color accent: "#b9a4ff"
    readonly property color text: "#ece7f2"
    readonly property color subtext: "#b7b0c2"
    readonly property string font: "Google Sans Flex"

    function t(en, de) {
        return root.de ? de : en
    }

    function login() {
        if (!user || status === "busy") return
        status = "busy"
        Greetd.createSession(user.name)
    }

    Process {
        running: true
        command: ["sh", "-c", "grep -q '^LANG=de' /etc/locale.conf 2>/dev/null && echo de; awk -F: '$3>=1000 && $3<60000 && $7 !~ /(nologin|false)$/ {print $1 \"|\" $5}' /etc/passwd"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l !== "")
                root.de = lines[0] === "de"
                root.users = lines.filter(l => l !== "de").map(l => {
                    const p = l.split("|")
                    const full = (p[1] || "").split(",")[0]
                    return { name: p[0], full: full !== "" ? full : p[0] }
                })
            }
        }
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) Greetd.respond(pw.text)
        }
        function onAuthFailure(message) {
            root.status = "wrong"
            pw.text = ""
            shake.restart()
            Greetd.cancelSession()
        }
        function onError(error) {
            root.status = "wrong"
            shake.restart()
        }
        function onReadyToLaunch() {
            root.status = "launch"
            Greetd.launch(["start-hyprland"])
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    FloatingWindow {
        id: win
        implicitWidth: 1920
        implicitHeight: 1080
        color: root.base

        Image {
            anchors.fill: parent
            source: "file://" + root.themeDir + "/lock.png"
            fillMode: Image.PreserveAspectCrop
            opacity: root.status === "launch" ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 400 } }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.05, 0.04, 0.08, 0.45)
        }

        Row {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 32
            spacing: 10
            Canvas {
                width: 26
                height: 26
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.lineWidth = 3
                    ctx.lineCap = "round"
                    ctx.strokeStyle = root.accent
                    ctx.beginPath()
                    ctx.arc(13, 13, 9, Math.PI * 0.22, Math.PI * 1.78)
                    ctx.stroke()
                    ctx.fillStyle = root.accent
                    ctx.beginPath()
                    ctx.arc(22, 13, 2, 0, Math.PI * 2)
                    ctx.fill()
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "CanOS"
                color: root.text
                font.family: root.font
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.14
            spacing: 4
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clock.date, "HH:mm")
                color: root.text
                font.family: root.font
                font.pixelSize: 120
                font.weight: Font.Bold
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: clock.date.toLocaleString(Qt.locale(root.de ? "de_AT" : "en_US"), root.de ? "dddd, d. MMMM" : "dddd, MMMM d")
                color: root.subtext
                font.family: root.font
                font.pixelSize: 22
            }
        }

        Column {
            id: card
            anchors.centerIn: parent
            anchors.verticalCenterOffset: parent.height * 0.12
            spacing: 16

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18
                Text {
                    visible: root.users.length > 1
                    anchors.verticalCenter: parent.verticalCenter
                    text: "‹"
                    color: root.subtext
                    font.pixelSize: 34
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
                        onClicked: root.index = (root.index + root.users.length - 1) % root.users.length
                    }
                }
                Rectangle {
                    width: 96
                    height: 96
                    radius: 48
                    color: root.surface
                    border.width: 3
                    border.color: root.accent
                    Text {
                        anchors.centerIn: parent
                        text: root.user ? root.user.full.charAt(0).toUpperCase() : ""
                        color: root.accent
                        font.family: root.font
                        font.pixelSize: 42
                        font.weight: Font.Bold
                    }
                }
                Text {
                    visible: root.users.length > 1
                    anchors.verticalCenter: parent.verticalCenter
                    text: "›"
                    color: root.subtext
                    font.pixelSize: 34
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
                        onClicked: root.index = (root.index + 1) % root.users.length
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.user ? root.user.full : ""
                color: root.text
                font.family: root.font
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }

            Rectangle {
                id: field
                anchors.horizontalCenter: parent.horizontalCenter
                width: 340
                height: 52
                radius: 26
                color: Qt.rgba(0.11, 0.1, 0.15, 0.75)
                border.width: 2
                border.color: root.status === "wrong" ? "#ff8a8a" : pw.activeFocus ? root.accent : Qt.rgba(1, 1, 1, 0.15)
                Behavior on border.color { ColorAnimation { duration: 200 } }

                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -14; duration: 50 }
                    NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 12; duration: 70 }
                    NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -8; duration: 70 }
                    NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
                }

                Text {
                    visible: pw.text.length === 0
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    text: root.status === "wrong" ? root.t("Wrong password", "Falsches Passwort") : root.t("Password", "Passwort")
                    color: root.status === "wrong" ? "#ff8a8a" : root.subtext
                    font.family: root.font
                    font.pixelSize: 16
                }

                TextInput {
                    id: pw
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: go.left
                    anchors.leftMargin: 24
                    anchors.rightMargin: 10
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    color: root.text
                    font.family: root.font
                    font.pixelSize: 18
                    focus: true
                    clip: true
                    onTextChanged: if (root.status === "wrong") root.status = ""
                    Keys.onReturnPressed: root.login()
                    Keys.onEnterPressed: root.login()
                    Keys.onEscapePressed: text = ""
                    Keys.onLeftPressed: event => {
                        if (text === "" && root.users.length > 1) root.index = (root.index + root.users.length - 1) % root.users.length
                        else event.accepted = false
                    }
                    Keys.onRightPressed: event => {
                        if (text === "" && root.users.length > 1) root.index = (root.index + 1) % root.users.length
                        else event.accepted = false
                    }
                }

                Rectangle {
                    id: go
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 6
                    width: 40
                    height: 40
                    radius: 20
                    color: goArea.containsMouse ? Qt.lighter(root.accent, 1.1) : root.accent
                    RotationAnimation on rotation {
                        running: root.status === "busy" || root.status === "launch"
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                    }
                    Text {
                        anchors.centerIn: parent
                        text: root.status === "busy" || root.status === "launch" ? "◌" : "→"
                        color: root.base
                        font.pixelSize: 20
                        font.weight: Font.Bold
                    }
                    MouseArea {
                        id: goArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.login()
                    }
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 32
            spacing: 12
            Repeater {
                model: [
                    { label: root.t("Restart", "Neustart"), cmd: "reboot" },
                    { label: root.t("Shut down", "Ausschalten"), cmd: "poweroff" }
                ]
                Rectangle {
                    required property var modelData
                    width: label.implicitWidth + 36
                    height: 40
                    radius: 20
                    color: btnArea.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: modelData.label
                        color: root.text
                        font.family: root.font
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: btnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Quickshell.execDetached(["systemctl", modelData.cmd])
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 36
            text: "Yes, I CanOS."
            color: Qt.rgba(1, 1, 1, 0.35)
            font.family: root.font
            font.pixelSize: 14
        }
    }
}
